import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'package:visibility_detector/visibility_detector.dart'; // مكتبة اكتشاف الرؤية

void main() => runApp(const DetailsStoreApp());

class DetailsStoreApp extends StatelessWidget {
  const DetailsStoreApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Details Store',
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0.5,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: Colors.black,
            fontSize: 22,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
      ),
      home: const StoreHomePage(),
    );
  }
}

// --- النماذج (Models) ---
class Product {
  final String id, name, brand, imageUrl;
  final double price;
  final double? oldPrice;
  final bool isSoldOut;

  Product({
    required this.id,
    required this.name,
    required this.brand,
    required this.price,
    this.oldPrice,
    required this.imageUrl,
    this.isSoldOut = false,
  });

  factory Product.fromJson(Map<String, dynamic> json) => Product(
    id: json['_id'] ?? '',
    name: json['name'] ?? '',
    brand: json['brand'] ?? 'DETAILS',
    price: (json['price'] as num).toDouble(),
    oldPrice: json['oldPrice'] != null
        ? (json['oldPrice'] as num).toDouble()
        : null,
    imageUrl: json['imageUrl'] ?? '',
    isSoldOut: json['isSoldOut'] ?? false,
  );
}

class BannerModel {
  final String title, imageUrl, buttonText;
  BannerModel({
    required this.title,
    required this.imageUrl,
    required this.buttonText,
  });

  factory BannerModel.fromJson(Map<String, dynamic> json) => BannerModel(
    title: json['title'] ?? '',
    imageUrl: json['imageUrl'] ?? '',
    buttonText: json['buttonText'] ?? 'اكتشف ديتيلز',
  );
}

// --- الصفحة الرئيسية ---
class StoreHomePage extends StatefulWidget {
  const StoreHomePage({super.key});

  @override
  State<StoreHomePage> createState() => _StoreHomePageState();
}

class _StoreHomePageState extends State<StoreHomePage> {
  List<Product> products = [];
  List<BannerModel> banners = [];
  bool isLoading = true;

  int _currentBannerIndex = 0;
  int _currentAnnouncementIndex = 0;
  final PageController _heroController = PageController();
  final PageController _announcementController = PageController();
  Timer? _heroTimer, _announcementTimer;

  final List<String> _topAnnouncements = [
    "توصيل مجاني للطلبات فوق 500 شيكل",
    "خصم 20% على تشكيلة الساعات الجديدة",
    "سياسة استبدال مرنة خلال 14 يوماً",
  ];

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  @override
  void dispose() {
    _heroTimer?.cancel();
    _announcementTimer?.cancel();
    _heroController.dispose();
    _announcementController.dispose();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    await Future.wait([fetchProducts(), fetchBanners()]);
    if (mounted) {
      setState(() => isLoading = false);
      _startHeroScroll();
      _startAnnouncementScroll();
    }
  }

  void _startHeroScroll() {
    _heroTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (banners.isNotEmpty) {
        _currentBannerIndex = (_currentBannerIndex + 1) % banners.length;
        if (_heroController.hasClients) {
          _heroController.animateToPage(
            _currentBannerIndex,
            duration: const Duration(milliseconds: 1000),
            curve: Curves.easeInOutQuart,
          );
        }
      }
    });
  }

  void _startAnnouncementScroll() {
    _announcementTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_topAnnouncements.isNotEmpty) {
        _currentAnnouncementIndex =
            (_currentAnnouncementIndex + 1) % _topAnnouncements.length;
        if (_announcementController.hasClients) {
          _announcementController.animateToPage(
            _currentAnnouncementIndex,
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOut,
          );
        }
      }
    });
  }

  Future<void> fetchProducts() async {
    try {
      final res = await http.get(
        Uri.parse('https://api.details-store.com/api/products'),
      );
      if (res.statusCode == 200)
        products = (json.decode(res.body) as List)
            .map((j) => Product.fromJson(j))
            .toList();
    } catch (e) {
      debugPrint("Error products: $e");
    }
  }

  Future<void> fetchBanners() async {
    try {
      final res = await http.get(
        Uri.parse('https://api.details-store.com/api/banners'),
      );
      if (res.statusCode == 200)
        banners = (json.decode(res.body) as List)
            .map((j) => BannerModel.fromJson(j))
            .toList();
    } catch (e) {
      debugPrint("Error banners: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const Icon(Icons.menu, color: Colors.black),
        title: const Text("DETAILS"),
        actions: const [
          Icon(Icons.search, color: Colors.black),
          SizedBox(width: 15),
          Icon(Icons.shopping_cart_outlined, color: Colors.black),
          SizedBox(width: 15),
        ],
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Colors.black,
                strokeWidth: 1,
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadAllData,
              color: Colors.black,
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(child: _buildTopAnnouncement()),
                  SliverToBoxAdapter(child: _buildHeroSlider()),
                  SliverToBoxAdapter(child: _buildCategoriesSection()),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.62,
                            crossAxisSpacing: 15,
                            mainAxisSpacing: 25,
                          ),
                      delegate: SliverChildBuilderDelegate(
                        (c, i) => _buildProductCard(products[i]),
                        childCount: products.length,
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 50)),
                  // --- تطبيق ويجت الأنيميشن على الفوتر ---
                  SliverToBoxAdapter(
                    child: RevealOnScroll(child: _buildFooter()),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: _buildBottomNav(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: const Color(0xFF25D366),
        child: const Icon(Icons.chat_bubble_outline, color: Colors.white),
      ),
    );
  }

  // --- شريط الإعلانات والسلايدر ---
  Widget _buildTopAnnouncement() => Container(
    height: 35,
    color: const Color(0xFFF7F7F7),
    child: PageView.builder(
      controller: _announcementController,
      itemCount: _topAnnouncements.length,
      itemBuilder: (c, i) => Center(
        child: Text(
          _topAnnouncements[i],
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
        ),
      ),
    ),
  );
  Widget _buildHeroSlider() => banners.isEmpty
      ? const SizedBox()
      : SizedBox(
          height: 400,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PageView.builder(
                controller: _heroController,
                itemCount: banners.length,
                onPageChanged: (i) => setState(() => _currentBannerIndex = i),
                itemBuilder: (c, i) => _AnimatedBannerItem(banner: banners[i]),
              ),
              Positioned(
                bottom: 20,
                child: Row(
                  children: List.generate(
                    banners.length,
                    (i) => _dot(i == _currentBannerIndex),
                  ),
                ),
              ),
            ],
          ),
        );
  Widget _dot(bool a) => Container(
    margin: const EdgeInsets.symmetric(horizontal: 4),
    width: 8,
    height: 8,
    decoration: BoxDecoration(
      color: a ? Colors.white : Colors.white.withOpacity(0.5),
      shape: BoxShape.circle,
      border: Border.all(color: Colors.white),
    ),
  );

  // --- الأصناف والمنتجات ---
  Widget _buildCategoriesSection() => Column(
    children: [
      const SizedBox(height: 35),
      const Text(
        "أصنافنا",
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Color(0xFF0D47A1),
        ),
      ),
      Container(
        margin: const EdgeInsets.only(top: 5),
        width: 40,
        height: 2,
        color: Colors.orange[300],
      ),
      const SizedBox(height: 25),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _categoryCircle("حقائب"),
          _categoryCircle("ساعات"),
          _categoryCircle("إكسسوارات"),
        ],
      ),
      const SizedBox(height: 35),
    ],
  );
  Widget _categoryCircle(String l) => Column(
    children: [
      Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFFF5F5F5),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: const Icon(Icons.local_mall_outlined, color: Colors.grey),
      ),
      const SizedBox(height: 8),
      Text(
        l,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      ),
    ],
  );
  Widget _buildProductCard(Product p) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFFF9F9F9),
            borderRadius: BorderRadius.circular(4),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Image.network(
              p.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (c, e, s) => const Icon(Icons.broken_image),
            ),
          ),
        ),
      ),
      const SizedBox(height: 12),
      Text(
        p.brand.toUpperCase(),
        style: const TextStyle(
          fontSize: 10,
          color: Colors.grey,
          fontWeight: FontWeight.bold,
        ),
      ),
      Text(
        p.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 14),
      ),
      Row(
        children: [
          Text(
            "\$${p.price}",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          if (p.oldPrice != null) ...[
            const SizedBox(width: 8),
            Text(
              "\$${p.oldPrice}",
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
                decoration: TextDecoration.lineThrough,
              ),
            ),
          ],
        ],
      ),
    ],
  );

  // --- الفوتر الفخم (Footer) ---
  Widget _buildFooter() {
    return Container(
      width: double.infinity,
      color: Colors.black,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 50),
      child: Column(
        children: [
          Wrap(
            spacing: 40,
            runSpacing: 40,
            textDirection: TextDirection.rtl,
            children: [
              _footerColumn("من نحن ؟", [
                "ديتيلز انطلق ليكون الوجهة الأولى للحقائب والساعات الفاخرة، نهتم بأدق التفاصيل لنقدم لكم قطعاً تعكس ذوقكم الرفيع.",
              ], isText: true),
              _footerColumn("اختصارات", [
                "النساء",
                "الرجال",
                "المحافظ",
                "ساعات",
              ]),
              _footerColumn("سياساتنا", [
                "سياسة إلغاء الطلب",
                "سياسة الإرجاع",
                "سياسة الشحن",
              ]),
              _footerEmailSection(),
            ],
          ),
          const SizedBox(height: 50),
          const Divider(color: Colors.white12),
          const SizedBox(height: 20),
          const Text(
            "Copyright all rights reserved © 2026 Details",
            style: TextStyle(color: Colors.white54, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _footerColumn(String t, List<String> items, {bool isText = false}) =>
      SizedBox(
        width: 180,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ...items.map(
              (i) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  i,
                  style: TextStyle(
                    color: isText ? Colors.white70 : Colors.white54,
                    fontSize: 13,
                    height: 1.6,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
  Widget _footerEmailSection() => SizedBox(
    width: 280,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "ابقى على إطلاع",
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 15),
        const Text(
          "اشترك لتصلك آخر العروض والمنتجات عبر بريدك الإلكتروني",
          style: TextStyle(color: Colors.white54, fontSize: 12),
        ),
        const SizedBox(height: 20),
        TextField(
          style: const TextStyle(color: Colors.white, fontSize: 13),
          decoration: InputDecoration(
            hintText: "بريدك الإلكتروني",
            hintStyle: const TextStyle(color: Colors.white24),
            filled: true,
            fillColor: Colors.white.withOpacity(0.05),
            contentPadding: const EdgeInsets.symmetric(horizontal: 15),
            enabledBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Colors.white10),
              borderRadius: BorderRadius.circular(5),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Colors.white30),
              borderRadius: BorderRadius.circular(5),
            ),
            suffixIcon: TextButton(
              onPressed: () {},
              child: const Text(
                "إشتراك",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
  Widget _buildBottomNav() => Container(
    height: 70,
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border(top: BorderSide(color: Colors.grey[100]!)),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _navIcon(Icons.search, "بحث"),
        _navIcon(Icons.person_outline, "الحساب"),
        _navIcon(Icons.shopping_bag_outlined, "السلة"),
        _navIcon(Icons.favorite_border, "الأمنيات"),
        _navIcon(Icons.chat_bubble_outline, "تسوق", c: Colors.green),
      ],
    ),
  );
  Widget _navIcon(IconData i, String l, {Color c = Colors.black}) => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Icon(i, color: c, size: 24),
      const SizedBox(height: 4),
      Text(l, style: TextStyle(color: c, fontSize: 10)),
    ],
  );
}

// --- ويجت الأنيميشن عند السكرول (Reveal On Scroll) ---
class RevealOnScroll extends StatefulWidget {
  final Widget child;
  const RevealOnScroll({super.key, required this.child});
  @override
  State<RevealOnScroll> createState() => _RevealOnScrollState();
}

class _RevealOnScrollState extends State<RevealOnScroll>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _f;
  late Animation<Offset> _s;
  bool _revealed = false;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _f = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _c, curve: Curves.easeOut));
    _s = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _c, curve: Curves.easeOutQuart));
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: Key('reveal-${widget.child.hashCode}'),
      onVisibilityChanged: (info) {
        // إذا ظهر أكثر من 10% من العنصر ولم يتم تشغيل الحركة من قبل
        if (info.visibleFraction > 0.1 && !_revealed) {
          _c.forward();
          _revealed = true;
        }
      },
      child: FadeTransition(
        opacity: _f,
        child: SlideTransition(position: _s, child: widget.child),
      ),
    );
  }
}

// --- الويجت المتحركة للبانر ---
class _AnimatedBannerItem extends StatefulWidget {
  final BannerModel banner;
  const _AnimatedBannerItem({required this.banner});
  @override
  State<_AnimatedBannerItem> createState() => _AnimatedBannerItemState();
}

class _AnimatedBannerItemState extends State<_AnimatedBannerItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _sc, _f;
  late Animation<Offset> _sl;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _sc = Tween<double>(
      begin: 1.15,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _c, curve: Curves.easeOut));
    _f = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _c,
        curve: const Interval(0.4, 1.0, curve: Curves.easeIn),
      ),
    );
    _sl = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _c,
        curve: const Interval(0.4, 1.0, curve: Curves.easeOutQuart),
      ),
    );
    _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ScaleTransition(
          scale: _sc,
          child: Image.network(widget.banner.imageUrl, fit: BoxFit.cover),
        ),
        Container(color: Colors.black.withOpacity(0.25)),
        FadeTransition(
          opacity: _f,
          child: SlideTransition(
            position: _sl,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  widget.banner.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Container(width: 50, height: 2, color: Colors.white),
                const SizedBox(height: 25),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white, width: 1.5),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(
                    widget.banner.buttonText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

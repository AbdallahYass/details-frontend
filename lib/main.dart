import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'package:visibility_detector/visibility_detector.dart';

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
  final String id, name, brand;
  final List<String> images; // دعم مصفوفة الصور للـ Hover واللمس
  final double price;
  final double? oldPrice;
  final bool isSoldOut;

  Product({
    required this.id,
    required this.name,
    required this.brand,
    required this.images,
    required this.price,
    this.oldPrice,
    this.isSoldOut = false,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    List<String> imgs = [];
    if (json['images'] != null) {
      imgs = List<String>.from(json['images']);
    } else if (json['imageUrl'] != null) {
      imgs = [json['imageUrl']];
    }
    return Product(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      brand: json['brand'] ?? 'DETAILS',
      images: imgs,
      price: (json['price'] as num).toDouble(),
      oldPrice: json['oldPrice'] != null
          ? (json['oldPrice'] as num).toDouble()
          : null,
      isSoldOut: json['isSoldOut'] ?? false,
    );
  }
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
    _heroTimer = Timer.periodic(const Duration(seconds: 5), (t) {
      if (banners.isNotEmpty && _heroController.hasClients) {
        _currentBannerIndex = (_currentBannerIndex + 1) % banners.length;
        _heroController.animateToPage(
          _currentBannerIndex,
          duration: const Duration(milliseconds: 1000),
          curve: Curves.easeInOutQuart,
        );
      }
    });
  }

  void _startAnnouncementScroll() {
    _announcementTimer = Timer.periodic(const Duration(seconds: 4), (t) {
      if (_topAnnouncements.isNotEmpty && _announcementController.hasClients) {
        _currentAnnouncementIndex =
            (_currentAnnouncementIndex + 1) % _topAnnouncements.length;
        _announcementController.animateToPage(
          _currentAnnouncementIndex,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
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
      debugPrint("Error: $e");
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
      debugPrint("Error: $e");
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
                  SliverToBoxAdapter(
                    child: RevealOnScroll(child: _buildFooter()),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

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
            child: Stack(
              children: [
                _AnimatedProductImage(images: p.images),
                if (p.isSoldOut)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      color: Colors.white.withOpacity(0.9),
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: const Text(
                        "SOLD OUT",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
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

  Widget _buildFooter() {
    return Container(
      width: double.infinity,
      color: Colors.black,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Column(
        children: [
          _buildFooterAbout(),
          const SizedBox(height: 30),
          _footerAccordion("اختصارات", [
            "النساء",
            "الرجال",
            "المحافظ",
            "ساعات",
          ]),
          const Divider(color: Colors.white12, height: 1),
          _footerAccordion("سياساتنا", [
            "سياسة إلغاء الطلب",
            "سياسة الإرجاع",
            "سياسة الشحن",
          ]),
          const Divider(color: Colors.white12, height: 1),
          _footerAccordion("ابق على إطلاع", [], isSubscribe: true),
          const SizedBox(height: 40),
          const Divider(color: Colors.white12),
          const SizedBox(height: 20),
          const Text(
            "تصميم و تطوير رواد || لخدمات وحلول الويب المتكاملة",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFFC5A059),
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            "Copyright all rights reserved © 2026 Details",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white54, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterAbout() => Column(
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      const Text(
        "من نحن ؟",
        style: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 15),
      const Text(
        "ديتيلز انطلق ليكون الوجهة الأولى للحقائب والساعات الفاخرة، نهتم بأدق التفاصيل لنقدم لكم قطعاً تعكس ذوقكم الرفيع.",
        textAlign: TextAlign.right,
        style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.6),
      ),
      const SizedBox(height: 20),
      _contactRow(Icons.email_outlined, "support@details-store.com"),
      _contactRow(Icons.phone_android, "+970-599477317"),
      const SizedBox(height: 15),
      Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.install_mobile,
              color: Colors.white,
              size: 20,
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.camera_alt_outlined,
              color: Colors.white,
              size: 20,
            ),
          ),
        ],
      ),
    ],
  );
  Widget _footerAccordion(
    String t,
    List<String> i, {
    bool isSubscribe = false,
  }) => Theme(
    data: ThemeData().copyWith(dividerColor: Colors.transparent),
    child: ExpansionTile(
      title: Text(
        t,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.bold,
        ),
      ),
      trailing: const Icon(Icons.add, color: Colors.white, size: 20),
      childrenPadding: const EdgeInsets.only(bottom: 20, right: 16, left: 16),
      expandedCrossAxisAlignment: CrossAxisAlignment.end,
      children: isSubscribe
          ? [_buildSubscribeField()]
          : i
                .map(
                  (item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Text(
                      item,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 13,
                      ),
                    ),
                  ),
                )
                .toList(),
    ),
  );
  Widget _buildSubscribeField() => Column(
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      const Text(
        "إشترك لتصل آخر العروض والمنتجات عبر بريدك الإلكتروني",
        textAlign: TextAlign.right,
        style: TextStyle(color: Colors.white54, fontSize: 12),
      ),
      const SizedBox(height: 15),
      Container(
        height: 50,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white24),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          children: [
            Container(
              margin: const EdgeInsets.all(4),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(25),
              ),
              child: const Center(
                child: Text(
                  "إشتراك",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const Expanded(
              child: TextField(
                textAlign: TextAlign.right,
                style: TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  hintText: "بريدك الإلكتروني",
                  hintStyle: TextStyle(color: Colors.white24),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    ],
  );
  Widget _contactRow(IconData i, String t) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(t, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(width: 10),
        Icon(i, color: Colors.white, size: 16),
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

// --- ويجت تبديل الصور (دعم اللمس والماوس) ---
class _AnimatedProductImage extends StatefulWidget {
  final List<String> images;
  const _AnimatedProductImage({required this.images});

  @override
  State<_AnimatedProductImage> createState() => _AnimatedProductImageState();
}

class _AnimatedProductImageState extends State<_AnimatedProductImage> {
  bool _active = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // تحميل الصورة الثانية مسبقاً لضمان عدم وجود تأخير (Lag) عند أول لمسة
    if (widget.images.length > 1) {
      precacheImage(NetworkImage(widget.images[1]), context);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.images.isEmpty)
      return const Center(child: Icon(Icons.broken_image));

    String currentImage = (_active && widget.images.length > 1)
        ? widget.images[1]
        : widget.images[0];

    return MouseRegion(
      onEnter: (_) => setState(() => _active = true),
      onExit: (_) => setState(() => _active = false),
      child: Listener(
        // Listener بضمن استجابة فورية وقوية للمس في الموبايل
        onPointerDown: (_) => setState(() => _active = true),
        onPointerUp: (_) => setState(() => _active = false),
        onPointerCancel: (_) => setState(() => _active = false),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          reverseDuration: const Duration(milliseconds: 500),
          switchInCurve: Curves.easeInOut,
          switchOutCurve: Curves.easeInOut,
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.95, end: 1.0).animate(animation),
                child: child,
              ),
            );
          },
          child: Image.network(
            currentImage,
            key: ValueKey<String>(currentImage),
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                color: const Color(0xFFF5F5F5),
              ); // خلفية هادئة أثناء التحميل
            },
            errorBuilder: (c, e, s) => const Icon(Icons.broken_image),
          ),
        ),
      ),
    );
  }
}

// --- بقية الويجت (RevealOnScroll, AnimatedBannerItem) ---
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

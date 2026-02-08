import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:details_app/models/product.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:details_app/models/banner_model.dart';
import 'package:details_app/widgets/reveal_on_scroll.dart';
import 'package:details_app/widgets/animated_banner_item.dart';
import 'package:details_app/widgets/animated_product_image.dart';
import 'package:details_app/screens/product_details_screen.dart';

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
      _startAnnouncementScroll(); // تفعيل التايمر الجديد
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

  // --- التحديث الجديد: تايمر الجمل لمدة 15 ثانية ---
  void _startAnnouncementScroll() {
    _announcementTimer = Timer.periodic(const Duration(seconds: 15), (t) {
      if (_topAnnouncements.isNotEmpty && _announcementController.hasClients) {
        _currentAnnouncementIndex =
            (_currentAnnouncementIndex + 1) % _topAnnouncements.length;
        _announcementController.animateToPage(
          _currentAnnouncementIndex,
          duration: const Duration(milliseconds: 800), // أنيميشن ناعم للانتقال
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
      if (res.statusCode == 200) {
        products = (json.decode(res.body) as List)
            .map((j) => Product.fromJson(j))
            .toList();
      }
    } catch (e) {
      debugPrint("Error: $e");
    }
  }

  Future<void> fetchBanners() async {
    try {
      final res = await http.get(
        Uri.parse('https://api.details-store.com/api/banners'),
      );
      if (res.statusCode == 200) {
        banners = (json.decode(res.body) as List)
            .map((j) => BannerModel.fromJson(j))
            .toList();
      }
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
                  SliverToBoxAdapter(
                    child: _buildSectionHeader(
                      "الأكثر شيوعاً",
                      "الأكثر مبيعاً هذا الأسبوع",
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.65,
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

  Widget _buildTopAnnouncement() {
    return Container(
      height: 35,
      color: const Color(0xFFF7F7F7),
      child: PageView.builder(
        controller: _announcementController,
        itemCount: _topAnnouncements.length,
        onPageChanged: (i) => _currentAnnouncementIndex = i,
        itemBuilder: (c, i) => Center(
          child: Text(
            _topAnnouncements[i],
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 25),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(width: 30, height: 1.5, color: Colors.black),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(width: 30, height: 1.5, color: Colors.black),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            subtitle,
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 15),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF222222),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 35, vertical: 12),
            ),
            child: const Text(
              "عرض الكل",
              style: TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(Product p) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: const Color(0xFFF9F9F9),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Stack(
                children: [
                  AnimatedProductImage(product: p),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: _circleIcon(Icons.favorite_border, size: 20),
                  ),
                  const Positioned(
                    top: 10,
                    left: 10,
                    child: Icon(
                      Icons.fullscreen,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  Positioned(
                    bottom: 15,
                    left: 10,
                    child: Column(
                      children: [
                        _circleIcon(
                          Icons.visibility_outlined,
                          isWhite: true,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (c) =>
                                    ProductDetailsScreen(product: p),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 8),
                        _circleIcon(Icons.link, isWhite: true),
                      ],
                    ),
                  ),
                  if (p.isSoldOut)
                    Positioned(
                      top: 15,
                      left: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: const BoxDecoration(
                          color: Color(0xFFE32F2F),
                          borderRadius: BorderRadius.only(
                            topRight: Radius.circular(20),
                            bottomRight: Radius.circular(20),
                          ),
                        ),
                        child: const Text(
                          "بيعت كلها",
                          style: TextStyle(
                            color: Colors.white,
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
          p.getName(context),
          textAlign: TextAlign.right,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            const Text(
              "شيكل",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(width: 4),
            Text(
              p.price.toStringAsFixed(2),
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _circleIcon(
    IconData icon, {
    bool isWhite = false,
    double size = 18,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isWhite ? Colors.white : Colors.black.withValues(alpha: 0.05),
          shape: BoxShape.circle,
          boxShadow: isWhite
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                  ),
                ]
              : [],
        ),
        child: Icon(icon, color: Colors.black54, size: size),
      ),
    );
  }

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
                itemBuilder: (c, i) => AnimatedBannerItem(banner: banners[i]),
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
      color: a ? Colors.white : Colors.white.withValues(alpha: 0.5),
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
      const SizedBox(height: 10),
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
  Widget _buildFooter() => Container(
    width: double.infinity,
    color: Colors.black,
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
    child: Column(
      children: [
        _buildFooterAbout(),
        const SizedBox(height: 30),
        _footerAccordion("اختصارات", ["النساء", "الرجال", "المحافظ", "ساعات"]),
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
            onPressed: () async {
              final Uri url = Uri.parse(
                'https://www.instagram.com/details__store__?igsh=c3Nuam5mNDM4ajBp',
              );
              if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
                debugPrint('Could not launch $url');
              }
            },
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

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:async';

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

  // التحكم في السلايدرات
  int _currentBannerIndex = 0;
  final PageController _heroController = PageController();
  final PageController _announcementController = PageController();
  Timer? _autoScrollTimer;

  // إعلانات الشريط العلوي (يمكنك جلبها لاحقاً من الـ API)
  final List<String> _topAnnouncements = [
    "توصيل مجاني للطلبات فوق 500 ريال",
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
    _autoScrollTimer?.cancel(); // إيقاف المؤقت عند إغلاق التطبيق
    _heroController.dispose();
    _announcementController.dispose();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    await Future.wait([fetchProducts(), fetchBanners()]);
    if (mounted) {
      setState(() => isLoading = false);
      _startAutoScroll(); // بدء التمرير التلقائي بعد تحميل البيانات
    }
  }

  void _startAutoScroll() {
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (banners.isNotEmpty) {
        _currentBannerIndex = (_currentBannerIndex + 1) % banners.length;
        if (_heroController.hasClients) {
          _heroController.animateToPage(
            _currentBannerIndex,
            duration: const Duration(milliseconds: 800),
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
      if (res.statusCode == 200) {
        products = (json.decode(res.body) as List)
            .map((j) => Product.fromJson(j))
            .toList();
      }
    } catch (e) {
      debugPrint("Error products: $e");
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
                  // 1. شريط الإعلانات العلوي الصغير
                  SliverToBoxAdapter(child: _buildTopAnnouncement()),

                  // 2. السلايدر الرئيسي (Hero)
                  SliverToBoxAdapter(child: _buildHeroSlider()),

                  // 3. الأصناف
                  SliverToBoxAdapter(child: _buildCategoriesSection()),

                  // 4. شبكة المنتجات
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
                ],
              ),
            ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // --- شريط الإعلانات العلوي ---
  Widget _buildTopAnnouncement() {
    return Container(
      height: 35,
      color: const Color(0xFFF7F7F7),
      child: Stack(
        children: [
          PageView.builder(
            controller: _announcementController,
            itemCount: _topAnnouncements.length,
            itemBuilder: (context, index) => Center(
              child: Text(
                _topAnnouncements[index],
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          _announcementArrow(Icons.chevron_left, isLeft: true),
          _announcementArrow(Icons.chevron_right, isLeft: false),
        ],
      ),
    );
  }

  Widget _announcementArrow(IconData icon, {required bool isLeft}) =>
      Positioned(
        left: isLeft ? 5 : null,
        right: isLeft ? null : 5,
        top: 0,
        bottom: 0,
        child: IconButton(
          icon: Icon(icon, size: 16, color: Colors.black54),
          onPressed: () => isLeft
              ? _announcementController.previousPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.ease,
                )
              : _announcementController.nextPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.ease,
                ),
        ),
      );

  // --- السلايدر الرئيسي (Hero) ---
  Widget _buildHeroSlider() {
    if (banners.isEmpty) return const SizedBox();
    return SizedBox(
      height: 400,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: [
          PageView.builder(
            controller: _heroController,
            itemCount: banners.length,
            onPageChanged: (index) =>
                setState(() => _currentBannerIndex = index),
            itemBuilder: (context, index) {
              final banner = banners[index];
              return Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(banner.imageUrl, fit: BoxFit.cover),
                  Container(color: Colors.black.withOpacity(0.2)),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        banner.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(width: 50, height: 2, color: Colors.white),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 25,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white, width: 1.5),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Text(
                          banner.buttonText,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
          _sliderArrow(Icons.arrow_back_ios, isLeft: true),
          _sliderArrow(Icons.arrow_forward_ios, isLeft: false),
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
  }

  Widget _sliderArrow(IconData icon, {required bool isLeft}) => Positioned(
    left: isLeft ? 15 : null,
    right: isLeft ? null : 15,
    child: IconButton(
      icon: Icon(icon, color: Colors.white70, size: 28),
      onPressed: () {
        _autoScrollTimer?.cancel(); // إيقاف المؤقت عند التحكم اليدوي مؤقتاً
        isLeft
            ? _heroController.previousPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.ease,
              )
            : _heroController.nextPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.ease,
              );
        _startAutoScroll(); // إعادة تشغيل المؤقت
      },
    ),
  );

  Widget _dot(bool active) => Container(
    margin: const EdgeInsets.symmetric(horizontal: 4),
    width: 8,
    height: 8,
    decoration: BoxDecoration(
      color: active ? Colors.white : Colors.white.withOpacity(0.5),
      shape: BoxShape.circle,
      border: Border.all(color: Colors.white),
    ),
  );

  // --- بقية العناصر (Categories, Products, Nav) ---
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

  Widget _categoryCircle(String label) => Column(
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
        label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      ),
    ],
  );

  Widget _buildProductCard(Product product) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        child: Stack(
          children: [
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFF9F9F9),
                borderRadius: BorderRadius.circular(4),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.network(
                  product.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (c, e, s) => const Icon(Icons.broken_image),
                ),
              ),
            ),
            if (product.isSoldOut)
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
      const SizedBox(height: 12),
      Text(
        product.brand.toUpperCase(),
        style: const TextStyle(
          fontSize: 10,
          color: Colors.grey,
          fontWeight: FontWeight.bold,
        ),
      ),
      Text(
        product.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 14),
      ),
      Row(
        children: [
          Text(
            "\$${product.price}",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          if (product.oldPrice != null) ...[
            const SizedBox(width: 8),
            Text(
              "\$${product.oldPrice}",
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
        _navIcon(Icons.chat_bubble_outline, "تسوق", color: Colors.green),
      ],
    ),
  );

  Widget _navIcon(IconData icon, String label, {Color color = Colors.black}) =>
      Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: color, fontSize: 10)),
        ],
      );
}

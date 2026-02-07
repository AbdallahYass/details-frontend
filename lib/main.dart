import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const DetailsStoreApp());
}

class DetailsStoreApp extends StatelessWidget {
  const DetailsStoreApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Details Store',
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
        primaryColor: Colors.black,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0.5,
          centerTitle: true,
          iconTheme: IconThemeData(color: Colors.black),
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

// موديل البيانات المطابق للـ Backend الخاص بك
class Product {
  final String id;
  final String name;
  final String brand;
  final double price;
  final double? oldPrice;
  final String imageUrl;
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

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
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
}

class StoreHomePage extends StatefulWidget {
  const StoreHomePage({super.key});

  @override
  State<StoreHomePage> createState() => _StoreHomePageState();
}

class _StoreHomePageState extends State<StoreHomePage> {
  List<Product> products = [];
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    fetchProducts();
  }

  // الربط مع الـ API الخاص بك
  Future<void> fetchProducts() async {
    final url = Uri.parse('https://api.details-store.com/api/products');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          products = data.map((json) => Product.fromJson(json)).toList();
          isLoading = false;
        });
      } else {
        setState(() {
          error = "حدث خطأ في جلب البيانات";
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = "تأكد من الاتصال بالإنترنت";
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const Icon(Icons.menu),
        title: const Text("DETAILS"),
        actions: const [
          Icon(Icons.search),
          SizedBox(width: 15),
          Icon(Icons.shopping_cart_outlined),
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
          : error != null
          ? Center(child: Text(error!))
          : RefreshIndicator(
              onRefresh: fetchProducts,
              color: Colors.black,
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
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
                        (context, index) => _buildProductCard(products[index]),
                        childCount: products.length,
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 50)),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: const Color(0xFF25D366),
        child: const Icon(Icons.message, color: Colors.white),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildHeroSlider() {
    return SizedBox(
      height: 400,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Image.network(
            'https://images.unsplash.com/photo-1548036328-c9fa89d128fa?q=80&w=1000',
            fit: BoxFit.cover,
            width: double.infinity,
          ),
          Container(color: Colors.black.withOpacity(0.15)),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "أفخم الساعات والحقائب",
                style: TextStyle(
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
                child: const Text(
                  "اكتشف ديتيلز",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesSection() {
    return Column(
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
  }

  Widget _categoryCircle(String label) {
    return Column(
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
  }

  Widget _buildProductCard(Product product) {
    return Column(
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
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.broken_image, color: Colors.grey),
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
                        letterSpacing: 1,
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
            letterSpacing: 1.2,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          product.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Text(
              "\$${product.price}",
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
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
  }

  Widget _buildBottomNav() {
    return Container(
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
  }

  Widget _navIcon(IconData icon, String label, {Color color = Colors.black}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: color, fontSize: 10)),
      ],
    );
  }
}

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
        // 1. سر التصميم: الخلفية البيضاء النقية
        scaffoldBackgroundColor: const Color(0xFFFFFFFF),
        primaryColor: Colors.black,

        // 2. تصميم البار العلوي (Minimal Header)
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          iconTheme: IconThemeData(color: Colors.black, size: 24),
          titleTextStyle: TextStyle(
            color: Colors.black,
            fontFamily: 'Times New Roman',
            fontSize: 28,
            fontWeight: FontWeight.w500,
            letterSpacing: 2.0,
          ),
        ),
      ),
      home: const StoreHomePage(),
    );
  }
}

class Product {
  final String name;
  final double price;
  final double? oldPrice;
  final String imageUrl;
  final String? brand;
  final bool isSoldOut;

  Product({
    required this.name,
    required this.price,
    this.oldPrice,
    required this.imageUrl,
    this.brand,
    this.isSoldOut = false,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      name: json['name'],
      price: (json['price'] as num).toDouble(),
      oldPrice: json['oldPrice'] != null
          ? (json['oldPrice'] as num).toDouble()
          : null,
      imageUrl: json['imageUrl'],
      brand: json['brand'],
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

  @override
  void initState() {
    super.initState();
    fetchProducts();
  }

  Future<void> fetchProducts() async {
    // الرابط الموجه لـ API الخاص بك
    final url = Uri.parse('https://api.details-store.com/api/products');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          products = data.map((json) => Product.fromJson(json)).toList();
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error: $e');
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    int crossAxisCount = width > 600 ? 4 : 2;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(onPressed: () {}, icon: const Icon(Icons.menu)),
        title: const Text("DETAILS"), // اسم البراند الخاص بك
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.search)),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.shopping_cart_outlined),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Colors.black,
                strokeWidth: 1,
              ),
            )
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: GridView.builder(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(top: 20, bottom: 40),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  childAspectRatio: 0.60, // نسبة الطول للعرض (Portrait)
                  crossAxisSpacing: 15,
                  mainAxisSpacing: 30,
                ),
                itemCount: products.length,
                itemBuilder: (context, index) {
                  return _buildDetailsCard(
                    products[index],
                  ); // الكارت الخاص بـ Details
                },
              ),
            ),
    );
  }

  // تصميم الكارت الخاص ببراند Details
  Widget _buildDetailsCard(Product product) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Stack(
            children: [
              Container(
                width: double.infinity,
                color: const Color(0xFFF5F5F5),
                child: Image.network(
                  product.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Center(
                    child: Icon(Icons.broken_image, color: Colors.grey),
                  ),
                ),
              ),
              if (product.isSoldOut)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    color: Colors.white.withOpacity(0.9),
                    alignment: Alignment.center,
                    child: const Text(
                      "SOLD OUT",
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (product.brand != null)
          Text(
            product.brand!.toUpperCase(),
            style: const TextStyle(
              fontSize: 10,
              color: Color(0xFF888888),
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
        const SizedBox(height: 4),
        Text(
          product.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontFamily: 'Times New Roman',
            fontSize: 15,
            color: Colors.black,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Text(
              "\$${product.price.toStringAsFixed(0)}",
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
            if (product.oldPrice != null) ...[
              const SizedBox(width: 8),
              Text(
                "\$${product.oldPrice!.toStringAsFixed(0)}",
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFFB0B0B0),
                  decoration: TextDecoration.lineThrough,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

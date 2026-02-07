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
      title: 'Details Store11', // اسم التبويب
      theme: ThemeData(
        // 1. سر التصميم: الخلفية البيضاء النقية
        scaffoldBackgroundColor: const Color(0xFFFFFFFF),
        primaryColor: Colors.black,

        // 2. تصميم البار العلوي (Minimal Header)
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0, // بدون ظل نهائياً
          centerTitle: true,
          iconTheme: IconThemeData(color: Colors.black, size: 24),
          titleTextStyle: TextStyle(
            color: Colors.black,
            fontFamily: 'Times New Roman', // خط كلاسيكي فخم للعنوان
            fontSize: 28,
            fontWeight: FontWeight.w500,
            letterSpacing: 2.0, // تباعد الأحرف
          ),
        ),
      ),
      home: const StoreHomePage(),
    );
  }
}

// موديل البيانات (نفس البنية اللي في السيرفر)
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
    // 🔴 تأكد أن هذا الرابط هو رابط الباك إند الصحيح
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
      print('Error: $e');
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // تحديد عدد الأعمدة حسب حجم الشاشة (للموبايل 2، للكمبيوتر 4)
    double width = MediaQuery.of(context).size.width;
    int crossAxisCount = width > 600 ? 4 : 2;

    return Scaffold(
      // الهيدر الفخم
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {},
          icon: const Icon(Icons.menu),
        ), // زر القائمة
        title: const Text("DETAILS"), // اللوجو
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
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
              ), // هوامش جانبية
              child: GridView.builder(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(top: 20, bottom: 40),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  childAspectRatio:
                      0.60, // 👈 السر هنا: نسبة الطول للعرض (جعلناها طويلة جداً)
                  crossAxisSpacing: 15, // مسافة أفقية بين المنتجات
                  mainAxisSpacing: 30, // مسافة عمودية كبيرة
                ),
                itemCount: products.length,
                itemBuilder: (context, index) {
                  return _buildLady90sCard(products[index]);
                },
              ),
            ),
    );
  }

  // تصميم الكارت (نسخة Lady90s)
  Widget _buildLady90sCard(Product product) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start, // كل النصوص تبدأ من اليسار
      children: [
        // 1. الصورة (تأخذ المساحة الأكبر)
        Expanded(
          child: Stack(
            children: [
              // الصورة نفسها
              Container(
                width: double.infinity,
                color: const Color(
                  0xFFF5F5F5,
                ), // خلفية رمادية خفيفة جداً للصورة (مثل الموقع)
                child: Image.network(
                  product.imageUrl,
                  fit: BoxFit.cover, // تغطية كاملة
                ),
              ),

              // بادج "SOLD OUT" (تصميم بسيط وراقي)
              if (product.isSoldOut)
                Positioned(
                  bottom: 0, // البادج في الأسفل فوق الصورة
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    color: Colors.white.withOpacity(
                      0.9,
                    ), // خلفية بيضاء شبه شفافة
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

        const SizedBox(height: 12), // مسافة بين الصورة والنصوص
        // 2. اسم الماركة (صغير، رمادي، حروف كبيرة)
        if (product.brand != null)
          Text(
            product.brand!.toUpperCase(),
            style: const TextStyle(
              fontSize: 10,
              color: Color(0xFF888888), // رمادي متوسط
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),

        const SizedBox(height: 4),

        // 3. اسم المنتج (خط عادي، ليس سميكاً)
        Text(
          product.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis, // نقاط (...) اذا الاسم طويل
          style: const TextStyle(
            fontFamily: 'Times New Roman', // نفس خط الهيدر لزيادة الفخامة
            fontSize: 15,
            color: Colors.black,
            height: 1.2,
          ),
        ),

        const SizedBox(height: 6),

        // 4. السعر (بسيط جداً)
        Row(
          children: [
            // السعر الجديد
            Text(
              "\$${product.price.toStringAsFixed(0)}",
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500, // وزن متوسط
                color: Colors.black,
              ),
            ),

            // السعر القديم (اذا وجد)
            if (product.oldPrice != null) ...[
              const SizedBox(width: 8),
              Text(
                "\$${product.oldPrice!.toStringAsFixed(0)}",
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFFB0B0B0), // رمادي فاتح
                  decoration: TextDecoration.lineThrough, // خط في المنتصف
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

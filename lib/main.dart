import 'package:flutter/material.dart';

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
        // تحسين الخطوط لتعطي الطابع الفخم
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

class StoreHomePage extends StatelessWidget {
  const StoreHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const Icon(Icons.menu),
        title: const Text("DETAILS"),
        actions: [
          const Icon(Icons.search),
          const SizedBox(width: 15),
          Stack(
            alignment: Alignment.center,
            children: [
              const Icon(Icons.shopping_cart_outlined),
              Positioned(
                top: 8,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Colors.black,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 14,
                    minHeight: 14,
                  ),
                  child: const Text(
                    '0',
                    style: TextStyle(color: Colors.white, fontSize: 8),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 15),
        ],
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // 1. Hero Slider (السلايدر العلوي)
          SliverToBoxAdapter(child: _buildHeroSlider()),

          // 2. قسم "أصنافنا"
          SliverToBoxAdapter(child: _buildCategoriesSection()),

          // 3. شبكة المنتجات (Products Grid)
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.65,
                crossAxisSpacing: 15,
                mainAxisSpacing: 20,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildProductCard(),
                childCount: 4, // تجريبي
              ),
            ),
          ),
          const SliverToBoxAdapter(
            child: SizedBox(height: 100),
          ), // مساحة للنافبار السفلي
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: const Color(0xFF25D366), // لون واتساب
        child: const Icon(Icons.message, color: Colors.white),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // --- مكونات الواجهة ---

  Widget _buildHeroSlider() {
    return Container(
      height: 400,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Image.network(
            'https://via.placeholder.com/800x1200', // استبدلها بصورة مودل فخمة
            fit: BoxFit.cover,
            width: double.infinity,
          ),
          Container(color: Colors.black.withOpacity(0.1)),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "أفخم الساعات الرجالية والنسائية",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Container(width: 60, height: 2, color: Colors.white),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white, width: 2),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: const Text(
                  "ساعات ديتيلز",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          // دوائر الترقيم (Pagination)
          Positioned(
            bottom: 20,
            child: Row(children: [_dot(true), _dot(false), _dot(false)]),
          ),
        ],
      ),
    );
  }

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

  Widget _buildCategoriesSection() {
    return Column(
      children: [
        const SizedBox(height: 30),
        const Text(
          "أصنافنا",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0D47A1),
          ),
        ),
        Container(
          margin: const EdgeInsets.only(top: 5),
          width: 60,
          height: 3,
          color: Colors.orange[200],
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _categoryItem("46", "https://via.placeholder.com/100"),
            _categoryItem("189", "https://via.placeholder.com/100"),
            _categoryItem("32", "https://via.placeholder.com/100"),
          ],
        ),
        const SizedBox(height: 30),
      ],
    );
  }

  Widget _categoryItem(String count, String img) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 85,
          height: 85,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey[200]!),
            image: DecorationImage(
              image: NetworkImage(img),
              fit: BoxFit.contain,
            ),
          ),
        ),
        Positioned(
          top: -5,
          left: -5,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              count,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProductCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFF9F9F9),
              borderRadius: BorderRadius.circular(5),
            ),
            child: Image.network(
              'https://via.placeholder.com/300',
              fit: BoxFit.contain,
            ),
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          "ROLEX",
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey,
            letterSpacing: 1.2,
          ),
        ),
        const Text(
          "ساعة رولكس كلاسيك",
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const Text(
          "\$1,200",
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildBottomNav() {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
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
        Text(label, style: TextStyle(color: color, fontSize: 10)),
      ],
    );
  }
}

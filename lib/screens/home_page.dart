import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:details_app/models/product.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:details_app/models/banner_model.dart';
import 'package:details_app/models/category_model.dart';
import 'package:details_app/widgets/reveal_on_scroll.dart';
import 'package:details_app/widgets/animated_banner_item.dart';
import 'package:details_app/widgets/animated_product_image.dart';
import 'package:details_app/constants/app_colors.dart';
import 'package:details_app/l10n/app_localizations.dart';
import 'package:details_app/providers/wishlist_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:details_app/providers/settings_provider.dart';
import 'package:details_app/providers/auth_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Product> products = [];
  List<BannerModel> banners = [];
  List<CategoryModel> categories = [];
  List<Product> popularProducts = [];
  bool isLoading = true;

  final ValueNotifier<int> _bannerIndexNotifier = ValueNotifier(0);
  final PageController _heroController = PageController();
  Timer? _heroTimer;

  String? _selectedCategory;
  final Map<String, int> _categoryPageIndices = {};

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  @override
  void dispose() {
    _heroTimer?.cancel();
    _bannerIndexNotifier.dispose();
    _heroController.dispose();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    await Future.wait([
      fetchProducts(),
      fetchBanners(),
      fetchCategories(),
      fetchPopularProducts(),
    ]);
    if (mounted) {
      setState(() => isLoading = false);
      _startHeroScroll();
    }
  }

  void _startHeroScroll() {
    _heroTimer?.cancel();
    _heroTimer = Timer.periodic(const Duration(seconds: 5), (t) {
      if (banners.isNotEmpty && _heroController.hasClients) {
        int nextIndex = (_bannerIndexNotifier.value + 1) % banners.length;
        _heroController.animateToPage(
          nextIndex,
          duration: const Duration(milliseconds: 1200),
          curve: Curves.easeInOutQuart,
        );
      }
    });
  }

  Future<void> fetchProducts({String? category}) async {
    try {
      String url = 'https://api.details-store.com/api/products';
      if (category != null) {
        url += '?category=$category';
      }
      final res = await http.get(Uri.parse(url));
      if (res.statusCode == 200) {
        setState(() {
          products = (json.decode(res.body) as List)
              .map((j) => Product.fromJson(j))
              .toList();
        });
      }
    } catch (e) {
      debugPrint("Error: $e");
    }
  }

  Future<void> fetchBanners({
    String location = 'home',
    String? category,
  }) async {
    try {
      String url =
          'https://api.details-store.com/api/banners?location=$location';
      if (category != null) {
        url += '&category=$category';
      }
      final res = await http.get(Uri.parse(url));
      if (res.statusCode == 200) {
        setState(() {
          banners = (json.decode(res.body) as List)
              .map((j) => BannerModel.fromJson(j))
              .toList();
          _bannerIndexNotifier.value = 0;
          if (_heroController.hasClients) {
            _heroController.jumpToPage(0);
          }
        });
      }
    } catch (e) {
      debugPrint("Error: $e");
    }
  }

  Future<void> fetchCategories() async {
    try {
      final res = await http.get(
        Uri.parse('https://api.details-store.com/api/categories'),
      );
      if (res.statusCode == 200) {
        setState(() {
          categories = (json.decode(res.body) as List)
              .map((j) => CategoryModel.fromJson(j))
              .toList();
        });
      }
    } catch (e) {
      debugPrint("Error fetching categories: $e");
    }
  }

  Future<void> fetchPopularProducts() async {
    try {
      final res = await http.get(
        Uri.parse('https://api.details-store.com/api/popular-products'),
      );
      if (res.statusCode == 200) {
        setState(() {
          popularProducts = (json.decode(res.body) as List)
              .map((j) => Product.fromJson(j))
              .toList();
        });
      }
    } catch (e) {
      debugPrint("Error fetching popular products: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
                strokeWidth: 1,
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadAllData,
              color: AppColors.primary,
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverAppBar(
                    floating: true,
                    pinned: true,
                    backgroundColor: AppColors.primary,
                    elevation: 0,
                    centerTitle: true,
                    iconTheme: const IconThemeData(color: Colors.white),
                    leading: IconButton(
                      icon: const Icon(Icons.menu, color: Colors.white),
                      onPressed: () {
                        Scaffold.of(context).openDrawer();
                      },
                    ),
                    title: Image.asset('assets/images/logo1.png', height: 40),
                    actions: [
                      IconButton(
                        icon: const Icon(
                          Icons.notifications_outlined,
                          color: Colors.white,
                        ),
                        onPressed: () {},
                      ),
                    ],
                  ),
                  SliverToBoxAdapter(child: _buildHeroSlider()),
                  SliverToBoxAdapter(child: _buildCategoriesSection()),
                  if (popularProducts.isNotEmpty && _selectedCategory == null)
                    SliverToBoxAdapter(child: _buildPopularSection()),
                  // هنا نستدعي الدالة التي تبني الأقسام
                  ..._buildCategoryGrids(),
                  const SliverToBoxAdapter(child: SizedBox(height: 50)),
                  SliverToBoxAdapter(
                    child: RevealOnScroll(child: _buildFooter()),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildPopularSection() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 20, 16, 10),
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.star, color: Colors.amber, size: 24),
              const SizedBox(width: 8),
              Text(
                AppLocalizations.of(context)!.translate('most_popular'),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.star, color: Colors.amber, size: 24),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            AppLocalizations.of(context)!.translate('best_seller_week'),
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 20),
          SizedBox(
            //
            height: 260,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: popularProducts.length,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemBuilder: (context, index) {
                return Container(
                  width: 160,
                  margin: const EdgeInsetsDirectional.only(end: 15),
                  child: _buildProductCard(popularProducts[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // دالة لبناء شبكات المنتجات مقسمة حسب الكاتيجوري
  List<Widget> _buildCategoryGrids() {
    // إذا كان المستخدم اختار كاتيجوري محدد من الدوائر العلوية، نعرض المنتجات كلها في شبكة واحدة
    if (_selectedCategory != null) {
      return [
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
      ];
    }

    // إذا لم يتم اختيار كاتيجوري، نعرض كل قسم ومنتجاته داخل بطاقات
    List<Widget> slivers = [];

    for (var category in categories) {
      // تصفية المنتجات التابعة لهذا القسم
      final categoryProducts = products
          .where((p) => p.categoryId == category.id)
          .toList();

      // إذا لم يكن هناك منتجات في هذا القسم، لا نعرضه
      if (categoryProducts.isEmpty) continue;

      // تحديد الصفحة الحالية لهذا القسم
      int pageIndex = _categoryPageIndices[category.id] ?? 0;
      int itemsPerPage = 4;
      int totalItems = categoryProducts.length;

      // حساب بداية ونهاية القائمة المعروضة
      int startIndex = pageIndex * itemsPerPage;
      // إذا كان الفهرس خارج النطاق (مثلاً بعد تحديث البيانات)، نعيده للصفر
      if (startIndex >= totalItems) {
        startIndex = 0;
        pageIndex = 0;
        _categoryPageIndices[category.id] = 0;
      }

      int endIndex = startIndex + itemsPerPage;
      if (endIndex > totalItems) endIndex = totalItems;

      final currentProducts = categoryProducts.sublist(startIndex, endIndex);

      slivers.add(
        SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                // اسم القسم في المنتصف
                Text(
                  category.getName(context),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkBlue,
                  ),
                ),
                const SizedBox(height: 15),

                // شبكة المنتجات (4 منتجات)
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: currentProducts.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.65,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemBuilder: (c, i) => _buildProductCard(currentProducts[i]),
                ),

                // أزرار التنقل (السابق / التالي)
                if (totalItems > itemsPerPage) ...[
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: pageIndex > 0
                            ? () {
                                setState(() {
                                  _categoryPageIndices[category.id] =
                                      pageIndex - 1;
                                });
                              }
                            : null,
                        icon: Icon(
                          Icons.arrow_back_ios,
                          size: 20,
                          color: pageIndex > 0
                              ? AppColors.primary
                              : Colors.grey.shade300,
                        ),
                      ),
                      Text(
                        '${pageIndex + 1} / ${(totalItems / itemsPerPage).ceil()}',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        onPressed: endIndex < totalItems
                            ? () {
                                setState(() {
                                  _categoryPageIndices[category.id] =
                                      pageIndex + 1;
                                });
                              }
                            : null,
                        icon: Icon(
                          Icons.arrow_forward_ios,
                          size: 20,
                          color: endIndex < totalItems
                              ? AppColors.primary
                              : Colors.grey.shade300,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    // في حال لم تكن هناك أي منتجات أو أقسام محملة بعد
    if (slivers.isEmpty && products.isNotEmpty) {
      // عرض المنتجات العامة كاحتياط
      slivers.add(
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
      );
    }

    return slivers;
  }

  Widget _buildProductCard(Product p) {
    final wishlistProvider = Provider.of<WishlistProvider>(context);
    final isFav = wishlistProvider.isInWishlist(p.id);
    final isHot = popularProducts.any((element) => element.id == p.id);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade100),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  GestureDetector(
                    onTap: () => context.push('/product/${p.id}', extra: p),
                    child: Hero(
                      tag: p.id,
                      child: AnimatedProductImage(product: p),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: _circleIcon(
                      isFav ? Icons.favorite : Icons.favorite_border,
                      size: 20,
                      color: isFav ? AppColors.red : AppColors.secondary,
                      onTap: () async {
                        final auth = Provider.of<AuthProvider>(
                          context,
                          listen: false,
                        );
                        if (!auth.isAuthenticated) {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: Text(
                                AppLocalizations.of(
                                  context,
                                )!.translate('please_login'),
                              ),
                              content: Text(
                                AppLocalizations.of(
                                  context,
                                )!.translate('login_subtitle'),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: const Text("Cancel"),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.pop(ctx);
                                    context.push('/login');
                                  },
                                  child: Text(
                                    AppLocalizations.of(
                                      context,
                                    )!.translate('login_button'),
                                  ),
                                ),
                              ],
                            ),
                          );
                          return;
                        }
                        bool added = await wishlistProvider.toggleWishlist(p);
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).hideCurrentSnackBar();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              added
                                  ? AppLocalizations.of(
                                      context,
                                    )!.translate('added_to_wishlist')
                                  : AppLocalizations.of(
                                      context,
                                    )!.translate('removed_from_wishlist'),
                            ),
                            backgroundColor: added
                                ? AppColors.primary
                                : AppColors.red,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      },
                    ),
                  ),
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Icon(
                      Icons.fullscreen,
                      color: AppColors.white,
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
                          onTap: () =>
                              context.push('/product/${p.id}', extra: p),
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
                          color: AppColors.red,
                          borderRadius: BorderRadius.only(
                            topRight: Radius.circular(20),
                            bottomRight: Radius.circular(20),
                          ),
                        ),
                        child: Text(
                          AppLocalizations.of(context)!.translate('sold_out'),
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  if (!p.isSoldOut && isHot)
                    Positioned(
                      top: 15,
                      left: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: const BoxDecoration(
                          color: AppColors.warning,
                          borderRadius: BorderRadius.only(
                            topRight: Radius.circular(20),
                            bottomRight: Radius.circular(20),
                          ),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.local_fire_department,
                              size: 12,
                              color: Colors.white,
                            ),
                            SizedBox(width: 2),
                            Text(
                              "HOT",
                              style: TextStyle(
                                color: AppColors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 10, right: 4, left: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                p.getName(context),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "${p.price.toStringAsFixed(2)} ${AppLocalizations.of(context)!.translate('currency')}",
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _circleIcon(
    IconData icon, {
    bool isWhite = false,
    double size = 18,
    VoidCallback? onTap,
    Color? color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isWhite
              ? AppColors.white
              : AppColors.primary.withValues(alpha: 0.05),
          shape: BoxShape.circle,
          boxShadow: isWhite
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    blurRadius: 4,
                  ),
                ]
              : [],
        ),
        child: Icon(icon, color: color ?? AppColors.secondary, size: size),
      ),
    );
  }

  Widget _buildHeroSlider() => banners.isEmpty
      ? const SizedBox()
      : SizedBox(
          height: 220,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PageView.builder(
                controller: _heroController,
                itemCount: banners.length,
                onPageChanged: (i) => _bannerIndexNotifier.value = i,
                itemBuilder: (c, i) => GestureDetector(
                  onTap: () => _onBannerTap(banners[i]),
                  child: AnimatedBannerItem(banner: banners[i]),
                ),
              ),
              Positioned(
                bottom: 20,
                child: ValueListenableBuilder<int>(
                  valueListenable: _bannerIndexNotifier,
                  builder: (context, currentIndex, child) {
                    return Row(
                      children: List.generate(
                        banners.length,
                        (i) => _dot(i == currentIndex),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );

  void _onBannerTap(BannerModel banner) {
    // تأكد من أن BannerModel يحتوي على حقل category
    if (banner.category != null) {
      try {
        // البحث عن القسم المطابق للـ ID الموجود في الإعلان
        final cat = categories.firstWhere((c) => c.id == banner.category);

        // تفعيل القسم وتحديث الصفحة (نفس منطق الضغط على دائرة القسم)
        setState(() {
          _selectedCategory = cat.slug;
          isLoading = true;
        });

        Future.wait([
          fetchProducts(category: _selectedCategory),
          fetchBanners(location: 'category', category: _selectedCategory),
        ]).then((_) {
          if (mounted) setState(() => isLoading = false);
        });
      } catch (e) {
        debugPrint('Category not found for banner: ${banner.category}');
      }
    }
  }

  Widget _dot(bool a) => Container(
    margin: const EdgeInsets.symmetric(horizontal: 4),
    width: 8,
    height: 8,
    decoration: BoxDecoration(
      color: a ? AppColors.white : AppColors.white.withValues(alpha: 0.5),
      shape: BoxShape.circle,
      border: Border.all(color: AppColors.white),
    ),
  );
  Widget _buildCategoriesSection() => Column(
    children: [
      const SizedBox(height: 20),
      Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              AppLocalizations.of(context)!.translate('categories'),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.darkBlue,
              ),
            ),
            const SizedBox(height: 15),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: categories.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 15,
                childAspectRatio: 0.85,
              ),
              itemBuilder: (c, i) =>
                  _buildCategoryItem(category: categories[i]),
            ),
          ],
        ),
      ),
      const SizedBox(height: 10),
    ],
  );
  Widget _buildCategoryItem({required CategoryModel category}) {
    bool isSelected = _selectedCategory == category.slug;
    return GestureDetector(
      onTap: () {
        setState(() {
          if (_selectedCategory == category.slug) {
            _selectedCategory = null;
          } else {
            _selectedCategory = category.slug;
          }
          isLoading = true;
        });
        Future.wait([
          fetchProducts(category: _selectedCategory),
          fetchBanners(
            location: _selectedCategory == null ? 'home' : 'category',
            category: _selectedCategory,
          ),
        ]).then((_) {
          if (mounted) {
            setState(() => isLoading = false);
          }
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.transparent,
                border: Border.all(
                  color: isSelected ? AppColors.primary : Colors.transparent,
                  width: 2,
                ),
                boxShadow: [
                  if (!isSelected)
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                ],
              ),
              child: ClipOval(
                child: CachedNetworkImage(
                  imageUrl: category.imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) =>
                      Container(color: Colors.grey[200]),
                  errorWidget: (context, url, error) => Icon(
                    Icons.category_outlined,
                    color: isSelected ? AppColors.white : AppColors.grey,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              category.getName(context),
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? AppColors.primary : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() => Container(
    width: double.infinity,
    color: AppColors.primary,
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
    child: Column(
      children: [
        _buildFooterAbout(),
        const SizedBox(height: 30),
        _footerAccordion(
          AppLocalizations.of(context)!.translate('language'),
          [],
          customChildren: [
            _buildLanguageItem('العربية', const Locale('ar', '')),
            _buildLanguageItem('English', const Locale('en', '')),
          ],
        ),
        const Divider(color: Colors.white12, height: 1),
        _footerAccordion(
          AppLocalizations.of(context)!.translate('policies'),
          [],
          customChildren: [
            _buildPolicyItem(
              AppLocalizations.of(context)!.translate('policy_cancel'),
            ),
            _buildPolicyItem(
              AppLocalizations.of(context)!.translate('policy_return'),
            ),
            _buildPolicyItem(
              AppLocalizations.of(context)!.translate('policy_shipping'),
            ),
          ],
        ),
        const Divider(color: Colors.white12, height: 1),
        _footerAccordion(
          AppLocalizations.of(context)!.translate('stay_updated'),
          [],
          isSubscribe: true,
        ),
        const SizedBox(height: 40),
        const Divider(color: Colors.white12),
        const SizedBox(height: 20),
        Text(
          AppLocalizations.of(context)!.translate('copyright'),
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ),
  );
  Widget _buildFooterAbout() => Column(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      Text(
        AppLocalizations.of(context)!.translate('footer_about_title'),
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: AppColors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 15),
      Text(
        AppLocalizations.of(context)!.translate('footer_about_desc'),
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 13,
          height: 1.6,
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 20),
      _contactRow(Icons.email_outlined, "support@details-store.com"),
      _contactRow(Icons.phone_android, "+972-598723438"),
      const SizedBox(height: 15),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: () async {
              final Uri url = Uri.parse(
                'https://www.instagram.com/details__store__?igsh=c3Nuam5mNDM4ajBp',
              );
              if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
                debugPrint('Could not launch $url');
              }
            },
            icon: const FaIcon(
              FontAwesomeIcons.instagram,
              color: AppColors.white,
              size: 20,
            ),
          ),
          IconButton(
            onPressed: () async {
              final Uri url = Uri.parse('https://wa.me/972598723438');
              if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
                debugPrint('Could not launch $url');
              }
            },
            icon: const FaIcon(
              FontAwesomeIcons.whatsapp,
              color: AppColors.white,
              size: 20,
            ),
          ),
        ],
      ),
    ],
  );
  Widget _buildLanguageItem(String label, Locale locale) {
    return GestureDetector(
      onTap: () {
        Provider.of<SettingsProvider>(context, listen: false).setLocale(locale);
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildPolicyItem(String title) {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (c) => AlertDialog(
            title: Text(title),
            content: Text(title),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(c),
                child: const Text("OK"),
              ),
            ],
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _footerAccordion(
    String t,
    List<String> i, {
    bool isSubscribe = false,
    List<Widget>? customChildren,
  }) => Theme(
    data: ThemeData().copyWith(dividerColor: Colors.transparent),
    child: ExpansionTile(
      title: Center(
        child: Text(
          t,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.white,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      trailing: const Icon(Icons.add, color: AppColors.white, size: 20),
      childrenPadding: const EdgeInsets.only(bottom: 20, right: 16, left: 16),
      expandedCrossAxisAlignment: CrossAxisAlignment.center,
      children: isSubscribe
          ? [_buildSubscribeField()]
          : customChildren ??
                i
                    .map(
                      (item) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        child: Text(
                          item,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    )
                    .toList(),
    ),
  );
  Widget _buildSubscribeField() => Column(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      Text(
        AppLocalizations.of(context)!.translate('subscribe_text'),
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white54,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
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
                  "Subscribe",
                  style: TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            Expanded(
              child: TextField(
                textAlign: TextAlign.right,
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(
                    context,
                  )!.translate('email_hint'),
                  hintStyle: const TextStyle(
                    color: Colors.white24,
                    fontWeight: FontWeight.bold,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20),
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
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          t,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 10),
        Icon(i, color: AppColors.white, size: 16),
      ],
    ),
  );
}

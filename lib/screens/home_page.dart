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

  int _currentBannerIndex = 0;
  int _currentAnnouncementIndex = 0;
  final PageController _heroController = PageController();
  final PageController _announcementController = PageController();
  Timer? _heroTimer, _announcementTimer;

  List<String> _topAnnouncements = [];
  String? _selectedCategory;
  final Map<String, bool> _expandedCategories = {};

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final loc = AppLocalizations.of(context);
    if (loc != null) {
      _topAnnouncements = [
        loc.translate('top_announcement_1'),
        loc.translate('top_announcement_2'),
        loc.translate('top_announcement_3'),
      ];
    }
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
    await Future.wait([
      fetchProducts(),
      fetchBanners(),
      fetchCategories(),
      fetchPopularProducts(),
    ]);
    if (mounted) {
      setState(() => isLoading = false);
      _startHeroScroll();
      _startAnnouncementScroll();
    }
  }

  void _startHeroScroll() {
    _heroTimer?.cancel();
    _heroTimer = Timer.periodic(const Duration(seconds: 5), (t) {
      if (banners.isNotEmpty && _heroController.hasClients) {
        _currentBannerIndex = (_currentBannerIndex + 1) % banners.length;
        _heroController.animateToPage(
          _currentBannerIndex,
          duration: const Duration(milliseconds: 1200),
          curve: Curves.easeInOutQuart,
        );
      }
    });
  }

  void _startAnnouncementScroll() {
    _announcementTimer?.cancel();
    _announcementTimer = Timer.periodic(const Duration(seconds: 15), (t) {
      if (_topAnnouncements.isNotEmpty && _announcementController.hasClients) {
        _currentAnnouncementIndex =
            (_currentAnnouncementIndex + 1) % _topAnnouncements.length;
        _announcementController.animateToPage(
          _currentAnnouncementIndex,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
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
          _currentBannerIndex = 0;
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
      backgroundColor: const Color(0xFFF8F9FA), // خلفية فاتحة عصرية
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
                  // تم استبدال شريط الإعلانات بشريط بحث عصري
                  SliverToBoxAdapter(child: _buildSearchHeader()),
                  SliverToBoxAdapter(child: _buildHeroSlider()),
                  SliverToBoxAdapter(child: _buildCategoriesSection()),
                  if (popularProducts.isNotEmpty)
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

  Widget _buildSearchHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: GestureDetector(
        onTap: () => context.push('/search'),
        child: Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.search, color: Colors.grey),
              const SizedBox(width: 10),
              Text(
                AppLocalizations.of(context)!.translate('nav_search'),
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPopularSection() {
    return Column(
      children: [
        _buildSectionHeader(
          AppLocalizations.of(context)!.translate('most_popular'),
          AppLocalizations.of(context)!.translate('best_seller_week'),
        ),
        SizedBox(
          height: 280, // زيادة الارتفاع قليلاً للتصميم الجديد
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: popularProducts.length,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemBuilder: (context, index) {
              return Container(
                width: 170,
                margin: const EdgeInsets.only(left: 15),
                child: _buildProductCard(popularProducts[index]),
              );
            },
          ),
        ),
        const SizedBox(height: 20),
      ],
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
              childAspectRatio: 0.62, // تعديل النسبة للتصميم الجديد
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

    // إذا لم يتم اختيار كاتيجوري، نعرض كل قسم ومنتجاته
    List<Widget> slivers = [];

    for (var category in categories) {
      // تصفية المنتجات التابعة لهذا القسم
      final categoryProducts = products
          .where((p) => p.categoryId == category.id)
          .toList();

      // إذا لم يكن هناك منتجات في هذا القسم، لا نعرضه
      if (categoryProducts.isEmpty) continue;

      final isExpanded = _expandedCategories[category.id] ?? false;
      final int itemCount = isExpanded
          ? categoryProducts.length
          : (categoryProducts.length > 10 ? 10 : categoryProducts.length);

      // إضافة عنوان القسم
      slivers.add(
        SliverToBoxAdapter(
          child: _buildSectionHeader(category.getName(context), ''),
        ),
      );

      // إضافة شبكة المنتجات لهذا القسم
      slivers.add(
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.62,
              crossAxisSpacing: 15,
              mainAxisSpacing: 25,
            ),
            delegate: SliverChildBuilderDelegate(
              (c, i) => _buildProductCard(categoryProducts[i]),
              childCount: itemCount,
            ),
          ),
        ),
      );

      // إضافة زر "اعرض الكل" في الأسفل إذا كان هناك أكثر من 10 منتجات
      if (categoryProducts.length > 10) {
        slivers.add(
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 20, bottom: 10),
              child: Center(
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _expandedCategories[category.id] = !isExpanded;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primary,
                    elevation: 0,
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 35,
                      vertical: 12,
                    ),
                  ),
                  child: Text(
                    isExpanded
                        ? AppLocalizations.of(context)!.translate('show_less')
                        : AppLocalizations.of(context)!.translate('view_all'),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }
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
      );
    }

    return slivers;
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 25, 20, 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 5),
          if (subtitle.isNotEmpty)
            Text(
              subtitle,
              style: const TextStyle(color: AppColors.grey, fontSize: 12),
            ),
        ],
      ),
    );
  }

  Widget _buildProductCard(Product p) {
    final wishlistProvider = Provider.of<WishlistProvider>(context);
    final isFav = wishlistProvider.isInWishlist(p.id);

    return GestureDetector(
      onTap: () => context.push('/product/${p.id}', extra: p),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Section
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                    child: Hero(
                      tag: p.id,
                      child: AnimatedProductImage(product: p),
                    ),
                  ),
                  // Favorite Button
                  Positioned(
                    top: 10,
                    right: 10,
                    child: GestureDetector(
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
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 5,
                            ),
                          ],
                        ),
                        child: Icon(
                          isFav ? Icons.favorite : Icons.favorite_border,
                          size: 18,
                          color: isFav ? AppColors.red : Colors.grey,
                        ),
                      ),
                    ),
                  ),
                  if (p.isSoldOut)
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          AppLocalizations.of(context)!.translate('sold_out'),
                          style: const TextStyle(
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
            // Info Section
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.brand.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[500],
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    p.getName(context),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "${p.price.toStringAsFixed(0)} ${AppLocalizations.of(context)!.translate('currency')}",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Colors.black,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.add,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroSlider() => banners.isEmpty
      ? const SizedBox()
      : Container(
          margin: const EdgeInsets.symmetric(vertical: 16),
          height: 200,
          child: PageView.builder(
            controller: _heroController,
            itemCount: banners.length,
            onPageChanged: (i) => setState(() => _currentBannerIndex = i),
            itemBuilder: (c, i) => GestureDetector(
              onTap: () => _onBannerTap(banners[i]),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: AnimatedBannerItem(banner: banners[i]),
                ),
              ),
            ),
          ),
        );

  void _onBannerTap(BannerModel banner) {
    // تأكد من أن BannerModel يحتوي على حقل category
    if (_selectedCategory != null) return;

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

  Widget _buildCategoriesSection() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Text(
          AppLocalizations.of(context)!.translate('categories'),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ),
      SizedBox(
        height: 100,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: categories.length,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          itemBuilder: (c, i) => _categoryCard(category: categories[i]),
        ),
      ),
    ],
  );

  Widget _categoryCard({required CategoryModel category}) {
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
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 65,
              height: 65,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withOpacity(0.1)
                    : Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: isSelected ? AppColors.primary : Colors.transparent,
                  width: 2,
                ),
                boxShadow: [
                  if (!isSelected)
                    BoxShadow(
                      color: Colors.grey.shade200,
                      blurRadius: 5,
                      spreadRadius: 1,
                    ),
                ],
              ),
              padding: const EdgeInsets.all(10),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: category.imageUrl,
                  fit: BoxFit.contain,
                  placeholder: (context, url) =>
                      Container(color: Colors.grey[200]),
                  errorWidget: (context, url, error) => Icon(
                    Icons.category_outlined,
                    color: isSelected ? AppColors.white : AppColors.grey,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              category.getName(context),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? AppColors.primary : Colors.black87,
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

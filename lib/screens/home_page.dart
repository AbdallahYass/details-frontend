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

class StoreHomePage extends StatefulWidget {
  const StoreHomePage({super.key});
  @override
  State<StoreHomePage> createState() => _StoreHomePageState();
}

class _StoreHomePageState extends State<StoreHomePage> {
  List<Product> products = [];
  List<BannerModel> banners = [];
  List<CategoryModel> categories = [];
  bool isLoading = true;

  int _currentBannerIndex = 0;
  int _currentAnnouncementIndex = 0;
  final PageController _heroController = PageController();
  final PageController _announcementController = PageController();
  Timer? _heroTimer, _announcementTimer;

  List<String> _topAnnouncements = [];
  String? _selectedCategory;

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
    await Future.wait([fetchProducts(), fetchBanners(), fetchCategories()]);
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

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
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
                    SliverToBoxAdapter(child: _buildTopAnnouncement()),
                    SliverToBoxAdapter(child: _buildHeroSlider()),
                    SliverToBoxAdapter(child: _buildCategoriesSection()),
                    // هنا نستدعي الدالة التي تبني الأقسام
                    ..._buildCategoryGrids(),
                    const SliverToBoxAdapter(child: SizedBox(height: 50)),
                    SliverToBoxAdapter(
                      child: RevealOnScroll(child: _buildFooter()),
                    ),
                  ],
                ),
              ),
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

    // إذا لم يتم اختيار كاتيجوري، نعرض كل قسم ومنتجاته
    List<Widget> slivers = [];

    for (var category in categories) {
      // تصفية المنتجات التابعة لهذا القسم
      final categoryProducts = products
          .where((p) => p.categoryId == category.id)
          .toList();

      // إذا لم يكن هناك منتجات في هذا القسم، لا نعرضه
      if (categoryProducts.isEmpty) continue;

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
              childAspectRatio: 0.65,
              crossAxisSpacing: 15,
              mainAxisSpacing: 25,
            ),
            delegate: SliverChildBuilderDelegate(
              (c, i) => _buildProductCard(categoryProducts[i]),
              childCount: categoryProducts.length,
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

  Widget _buildTopAnnouncement() {
    return Container(
      height: 35,
      color: AppColors.lightGrey,
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
              Container(width: 30, height: 1.5, color: AppColors.primary),
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
              Container(width: 30, height: 1.5, color: AppColors.primary),
            ],
          ),
          const SizedBox(height: 5),
          if (subtitle.isNotEmpty)
            Text(
              subtitle,
              style: const TextStyle(color: AppColors.grey, fontSize: 12),
            ),
          const SizedBox(height: 15),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 35, vertical: 12),
            ),
            child: Text(
              AppLocalizations.of(context)!.translate('view_all'),
              style: const TextStyle(color: AppColors.white, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(Product p) {
    final wishlistProvider = Provider.of<WishlistProvider>(context);
    final isFav = wishlistProvider.isInWishlist(p.id);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: AppColors.cardBackground,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
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
                  const Positioned(
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
            Text(
              AppLocalizations.of(context)!.translate('currency'),
              style: const TextStyle(fontSize: 12, color: AppColors.grey),
            ),
            const SizedBox(width: 4),
            Text(
              p.price.toStringAsFixed(2),
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
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
      color: a ? AppColors.white : AppColors.white.withValues(alpha: 0.5),
      shape: BoxShape.circle,
      border: Border.all(color: AppColors.white),
    ),
  );
  Widget _buildCategoriesSection() => Column(
    children: [
      const SizedBox(height: 35),
      Text(
        AppLocalizations.of(context)!.translate('categories'),
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: AppColors.darkBlue,
        ),
      ),
      Container(
        margin: const EdgeInsets.only(top: 5),
        width: 40,
        height: 2,
        color: AppColors.orange,
      ),
      const SizedBox(height: 25),
      SizedBox(
        height: 110,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: categories.length,
          itemBuilder: (c, i) => _categoryCircle(category: categories[i]),
        ),
      ),
      const SizedBox(height: 10),
    ],
  );
  Widget _categoryCircle({required CategoryModel category}) {
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
                color: isSelected
                    ? AppColors.primary
                    : AppColors.circleBackground,
                border: Border.all(
                  color: isSelected ? AppColors.primary : Colors.grey[200]!,
                ),
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

import 'package:flutter/cupertino.dart';
import 'package:details_app/app_imports.dart';
import 'package:details_app/widgets/custom_loading_overlay.dart';
import 'package:details_app/providers/notification_provider.dart';
import 'dart:ui';

// استيراد الملفات المفصولة
import 'package:details_app/widgets/home/hero_slider_widget.dart';
import 'package:details_app/widgets/home/categories_section_widget.dart';
import 'package:details_app/widgets/home/product_card_widget.dart';
import 'package:details_app/widgets/home/home_footer_widget.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  List<Product> products = [];
  List<BannerModel> banners = [];
  List<CategoryModel> categories = [];
  List<Product> popularProducts = [];
  Set<String> _popularIds = {};
  bool isLoading = true;
  String? errorMessage;
  int _requestId = 0;

  final ValueNotifier<int> _bannerIndexNotifier = ValueNotifier(0);
  late PageController _heroController;
  Timer? _heroTimer;

  String? _selectedCategory;
  final Map<String, List<Product>> _groupedProducts = {};
  final HomeRepository _homeRepository = HomeRepository();

  final ScrollController _scrollController = ScrollController();
  bool _isScrolled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Viewport Fraction يعطي تأثير الإعلانات الجانبية (Peeking effect)
    _heroController = PageController(viewportFraction: 0.85);

    _scrollController.addListener(() {
      if (_scrollController.offset > 50 && !_isScrolled) {
        setState(() => _isScrolled = true);
      } else if (_scrollController.offset <= 50 && _isScrolled) {
        setState(() => _isScrolled = false);
      }
    });

    _loadAllData();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      if (auth.isAuthenticated) {
        Provider.of<NotificationProvider>(
          context,
          listen: false,
        ).fetchNotifications(context, authProvider: auth);
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _heroTimer?.cancel();
    _bannerIndexNotifier.dispose();
    _heroController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _heroTimer?.cancel();
    } else if (state == AppLifecycleState.resumed && banners.isNotEmpty) {
      _startHeroScroll();
    }
  }

  Future<void> _loadAllData({bool forceRefresh = false}) async {
    final int currentRequest = ++_requestId;
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final results = await _homeRepository.loadHomeData(
        forceRefresh: forceRefresh,
      );
      if (mounted && currentRequest == _requestId) {
        setState(() {
          products = results[0] as List<Product>;
          banners = results[1] as List<BannerModel>;
          categories = results[2] as List<CategoryModel>;
          popularProducts = results[3] as List<Product>;
          _popularIds = popularProducts.map((e) => e.id).toSet();
          _groupProducts();
          isLoading = false;
          _bannerIndexNotifier.value = 0;
          if (_heroController.hasClients) {
            _heroController.jumpToPage(0);
          }
        });
        _startHeroScroll();
      }
    } catch (e) {
      debugPrint("Error loading data: $e");
      if (mounted && currentRequest == _requestId) {
        setState(() {
          isLoading = false;
          errorMessage = AppLocalizations.of(
            context,
          )!.translate('error_occurred');
        });
      }
    }
  }

  void _groupProducts() {
    _groupedProducts.clear();
    for (var product in products) {
      if (!_groupedProducts.containsKey(product.categoryId)) {
        _groupedProducts[product.categoryId] = [];
      }
      _groupedProducts[product.categoryId]!.add(product);
    }
  }

  void _startHeroScroll() {
    _heroTimer?.cancel();
    _heroTimer = Timer.periodic(const Duration(seconds: 4), (t) {
      if (banners.isNotEmpty && _heroController.hasClients) {
        int nextIndex = (_bannerIndexNotifier.value + 1) % banners.length;
        _heroController.animateToPage(
          nextIndex,
          duration: const Duration(milliseconds: 800),
          curve: Curves.fastOutSlowIn,
        );
      }
    });
  }

  void _onBannerTap(BannerModel banner) {
    if (banner.category != null) {
      try {
        final cat = categories.firstWhere((c) => c.id == banner.category);
        _onCategoryTap(cat);
      } catch (e) {
        debugPrint('Category not found for banner: ${banner.category}');
      }
    }
  }

  void _onCategoryTap(CategoryModel category) async {
    final int currentRequest = ++_requestId;
    setState(() {
      _selectedCategory = _selectedCategory == category.slug
          ? null
          : category.slug;
      isLoading = true;
      errorMessage = null;
      products = [];
    });

    try {
      final results = await Future.wait([
        _homeRepository.fetchProducts(category: _selectedCategory),
        _homeRepository.fetchBanners(
          location: _selectedCategory == null ? 'home' : 'category',
          category: _selectedCategory,
        ),
      ]);
      if (mounted && currentRequest == _requestId) {
        setState(() {
          products = results[0] as List<Product>;
          banners = results[1] as List<BannerModel>;
          if (_selectedCategory == null) _groupProducts();
          isLoading = false;
          _bannerIndexNotifier.value = 0;
          if (_heroController.hasClients) _heroController.jumpToPage(0);
        });
        _startHeroScroll();
      }
    } catch (e) {
      if (mounted && currentRequest == _requestId) {
        setState(() {
          isLoading = false;
          errorMessage = AppLocalizations.of(
            context,
          )!.translate('error_occurred');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA), // خلفية بيضاء فخمة
      extendBodyBehindAppBar: true,
      appBar: _buildGlassAppBar(),
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.only(top: 100),
                sliver: CupertinoSliverRefreshControl(
                  onRefresh: () => _loadAllData(forceRefresh: true),
                ),
              ),
              if (errorMessage != null)
                SliverFillRemaining(
                  child: CommonErrorWidget(
                    message: errorMessage!,
                    onRetry: () => _loadAllData(forceRefresh: true),
                  ),
                )
              else ...[
                // سلايدر الإعلانات المطور
                SliverToBoxAdapter(
                  child: (isLoading && banners.isEmpty)
                      ? _buildHeroSkeleton()
                      : HeroSliderWidget(
                          banners: banners,
                          heroController: _heroController,
                          bannerIndexNotifier: _bannerIndexNotifier,
                          onBannerTap: _onBannerTap,
                          onPointerDown: () => _heroTimer?.cancel(),
                          onPointerUp: _startHeroScroll,
                        ),
                ),

                // الأقسام
                SliverToBoxAdapter(
                  child: (isLoading && categories.isEmpty)
                      ? const SizedBox() // يمكنك إضافة Skeleton للأقسام هنا
                      : CategoriesSectionWidget(
                          categories: categories,
                          selectedCategory: _selectedCategory,
                          onCategoryTap: _onCategoryTap,
                        ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 10)),

                // قسم المنتجات الشائعة (Trending)
                if (popularProducts.isNotEmpty && _selectedCategory == null)
                  SliverToBoxAdapter(child: _buildTrendySection()),

                // عنوان شبكة المنتجات
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 15),
                    child: Text(
                      AppLocalizations.of(
                        context,
                      )!.translate('discover_collection'),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),

                // شبكة المنتجات (Discover Grid)
                if (isLoading && products.isEmpty)
                  SliverToBoxAdapter(child: _buildProductsSkeleton())
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.60, // تصميم طولي أكثر للأناقة
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 24,
                          ),
                      delegate: SliverChildBuilderDelegate(
                        (c, i) => ProductCardWidget(
                          product: products[i],
                          isHot: _popularIds.contains(products[i].id),
                        ),
                        childCount: products.length,
                      ),
                    ),
                  ),

                const SliverToBoxAdapter(child: SizedBox(height: 50)),
                const SliverToBoxAdapter(
                  child: HomeFooterWidget(),
                ), // الفوتر الجديد
              ],
            ],
          ),
          if (isLoading && products.isEmpty)
            const CustomLoadingOverlay(isOverlay: false),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildGlassAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: _isScrolled ? 15 : 0,
            sigmaY: _isScrolled ? 15 : 0,
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            color: _isScrolled
                ? Colors.white.withValues(alpha: 0.85)
                : Colors.transparent,
          ),
        ),
      ),
    );
  }

  Widget _buildTrendySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context)!.translate('trending_now'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                  color: Colors.black87,
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
            ],
          ),
        ),
        SizedBox(
          height: 280,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: popularProducts.length,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemBuilder: (context, index) {
              return Container(
                width: 170,
                margin: const EdgeInsetsDirectional.only(end: 16),
                child: ProductCardWidget(
                  product: popularProducts[index],
                  isHot: _popularIds.contains(popularProducts[index].id),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHeroSkeleton() => Container(
    height: 200,
    margin: const EdgeInsets.symmetric(horizontal: 16),
    decoration: BoxDecoration(
      color: Colors.grey[200],
      borderRadius: BorderRadius.circular(20),
    ),
  );

  Widget _buildProductsSkeleton() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 4,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.60,
        crossAxisSpacing: 16,
        mainAxisSpacing: 24,
      ),
      itemBuilder: (c, i) => Container(
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
  );
}

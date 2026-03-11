// ignore_for_file: use_build_context_synchronously

import 'package:flutter/cupertino.dart';
import 'package:details_app/app_imports.dart';
import 'package:details_app/widgets/custom_loading_overlay.dart';
import 'package:details_app/providers/notification_provider.dart';
import 'package:details_app/providers/home_provider.dart';
import 'widgets/announcement_bar.dart';
import 'widgets/home_footer.dart';
import 'widgets/hero_slider.dart';
import 'widgets/category_item.dart';
import 'widgets/product_card_item.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  final ValueNotifier<int> _bannerIndexNotifier = ValueNotifier(0);
  // 3️⃣ Memory Optimization
  final PageController _heroController = PageController(viewportFraction: 1.0);
  Timer? _heroTimer;
  // Scroll Controller للعودة للأعلى
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // دمج عمليات التهيئة في استدعاء واحد لضمان التسلسل والأداء
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      final homeProvider = Provider.of<HomeProvider>(context, listen: false);
      final auth = Provider.of<AuthProvider>(context, listen: false);

      // 1. تحميل بيانات الصفحة الرئيسية
      homeProvider.loadAllData();

      // 2. التحقق من حالة الحساب والإشعارات
      if (auth.token != null) {
        await auth.tryAutoLogin();

        if (mounted && auth.isAuthenticated) {
          Provider.of<NotificationProvider>(
            context,
            listen: false,
          ).fetchNotifications(context, authProvider: auth);
        }
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
    } else if (state == AppLifecycleState.resumed) {
      // إعادة تشغيل السلايدر إذا كان هناك بانرات
      final provider = Provider.of<HomeProvider>(context, listen: false);
      if (provider.banners.isNotEmpty) {
        _startHeroScroll();
      }
    }
  }

  void _startHeroScroll() {
    // 1️⃣ Timer Check: منع تكرار المؤقتات
    if (_heroTimer?.isActive ?? false) return;

    // الوصول للبانرات من المزود (أو تمريرها، هنا نصل لها عبر السياق لاحقاً،
    // لكن للتسهيل سنعتمد على أن الويدجت يعيد البناء عند تغير البيانات)
    // الأفضل تمرير طول القائمة للدالة أو التحقق داخل التايمر عبر المزود

    _heroTimer = Timer.periodic(const Duration(seconds: 5), (t) {
      // نحتاج للوصول للمزود هنا بأمان
      if (!mounted) {
        t.cancel();
        return;
      }

      final provider = Provider.of<HomeProvider>(context, listen: false);
      final banners = provider.banners;

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

  Future<void> _switchCategory(String? slug) async {
    // 4️⃣ UX: Scroll to top
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOut,
      );
    }

    await Provider.of<HomeProvider>(
      context,
      listen: false,
    ).loadCategoryData(slug);
    // إعادة ضبط السلايدر
    _bannerIndexNotifier.value = 0;
    if (_heroController.hasClients) {
      _heroController.jumpToPage(0);
    }
    _startHeroScroll();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<HomeProvider>(
      builder: (context, provider, child) {
        // بدء التمرير إذا لم يكن نشطاً وكانت البيانات جاهزة
        if (!provider.isLoading &&
            provider.banners.isNotEmpty &&
            (_heroTimer == null || !_heroTimer!.isActive)) {
          _startHeroScroll();
        }

        return Scaffold(
          backgroundColor: const Color(0xFFFDFBF7),
          extendBodyBehindAppBar: true,
          body: Stack(
            children: [
              Positioned.fill(
                child: Image.asset(
                  'assets/images/bg.png',
                  fit: BoxFit.cover,
                  gaplessPlayback: true,
                  cacheWidth: 1080,
                  filterQuality: FilterQuality.none, // 5️⃣ Performance
                ),
              ),
              CustomScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.only(top: 120),
                    sliver: CupertinoSliverRefreshControl(
                      onRefresh: () => provider.loadAllData(forceRefresh: true),
                      builder:
                          (
                            context,
                            refreshState,
                            pulledExtent,
                            refreshTriggerPullDistance,
                            refreshIndicatorExtent,
                          ) {
                            final double opacity =
                                (pulledExtent / refreshTriggerPullDistance)
                                    .clamp(0.0, 1.0);
                            return Container(
                              alignment: Alignment.center,
                              child: Opacity(
                                opacity: opacity,
                                child: SingleChildScrollView(
                                  physics: const NeverScrollableScrollPhysics(),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        AppLocalizations.of(
                                          context,
                                        )!.translate('app_name'),
                                        style: const TextStyle(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          letterSpacing: 1.2,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        AppLocalizations.of(
                                          context,
                                        )!.translate('app_slogan'),
                                        style: const TextStyle(
                                          color: AppColors.primary,
                                          fontSize: 12,
                                          letterSpacing: 2.0,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                    ),
                  ),
                  if (provider.errorMessage != null)
                    SliverFillRemaining(
                      child: CommonErrorWidget(
                        message: AppLocalizations.of(
                          context,
                        )!.translate(provider.errorMessage!),
                        onRetry: () => provider.loadAllData(forceRefresh: true),
                      ),
                    )
                  else ...[
                    const SliverToBoxAdapter(child: AnnouncementBar()),
                    SliverToBoxAdapter(
                      child: (provider.isLoading && provider.banners.isEmpty)
                          ? _buildHeroSkeleton()
                          : HomeHeroSlider(
                              banners: provider.banners,
                              controller: _heroController,
                              notifier: _bannerIndexNotifier,
                              onBannerTap: _onBannerTap,
                              onPointerDown: (_) => _heroTimer?.cancel(),
                              onPointerUp: (_) => _startHeroScroll(),
                            ),
                    ),
                    if (provider.isLoading && provider.categories.isEmpty)
                      SliverToBoxAdapter(child: _buildCategoriesSkeleton())
                    else
                      ..._buildCategoriesSlivers(provider),
                    if (provider.popularProducts.isNotEmpty &&
                        provider.selectedCategory == null) ...[
                      SliverToBoxAdapter(child: _buildSectionDivider()),
                      SliverToBoxAdapter(child: _buildPopularSection(provider)),
                    ],
                    if (!provider.isLoading && provider.products.isNotEmpty)
                      SliverToBoxAdapter(child: _buildSectionDivider()),
                    if (provider.isLoading && provider.products.isEmpty)
                      _buildProductsSkeletonSliver()
                    else
                      ..._buildCategoryGrids(provider),
                    const SliverToBoxAdapter(child: SizedBox(height: 50)),
                    SliverToBoxAdapter(
                      child: RevealOnScroll(child: const HomeFooter()),
                    ),
                  ],
                ],
              ),
              if (provider.isLoading && provider.products.isEmpty)
                const CustomLoadingOverlay(isOverlay: false),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 30),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    AppColors.secondary.withValues(alpha: 0.4),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Container(
              width: 6,
              height: 6,
              transform: Matrix4.rotationZ(0.785398), // 45 degrees
              decoration: BoxDecoration(
                color: AppColors.secondary,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.secondary.withValues(alpha: 0.4),
                    blurRadius: 6,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.secondary.withValues(alpha: 0.4),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSkeleton() {
    return Container(
      height: 220,
      width: double.infinity,
      color: AppColors.imagePlaceholder,
    );
  }

  Widget _buildCategoriesSkeleton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.homeBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Container(height: 20, width: 100, color: AppColors.imagePlaceholder),
          const SizedBox(height: 15),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 6,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 15,
              childAspectRatio: 0.85,
            ),
            itemBuilder: (c, i) => Container(
              decoration: BoxDecoration(
                color: AppColors.imagePlaceholder,
                shape: BoxShape.circle,
              ),
            ),
          ),
          // تم حذف زر تسجيل الخروج المؤقت من هنا
        ],
      ),
    );
  }

  Widget _buildProductsSkeletonSliver() {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      sliver: SliverGrid(
        delegate: SliverChildBuilderDelegate(
          (context, index) => Container(
            decoration: BoxDecoration(
              color: AppColors.imagePlaceholder,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          childCount: 4,
        ),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.65,
          crossAxisSpacing: 15,
          mainAxisSpacing: 25,
        ),
      ),
    );
  }

  Widget _buildPopularSection(HomeProvider provider) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.homeBackground,
            AppColors.secondary.withValues(alpha: 0.03),
            AppColors.homeBackground,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.trending_up,
                    color: AppColors.secondary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  AppLocalizations.of(context)!.translate('most_popular'),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF452512),
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height:
                MediaQuery.of(context).size.height *
                0.35, // 6️⃣ UX: Responsive Height
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: provider.popularProducts.length,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemBuilder: (context, index) {
                final product = provider.popularProducts[index];
                return Container(
                  width: 175,
                  margin: const EdgeInsetsDirectional.only(end: 16),
                  child: ProductCardItem(
                    product: product,
                    isHot: provider.popularIds.contains(product.id),
                    heroEnabled: false,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  List<Widget> _buildCategoryGrids(HomeProvider provider) {
    if (provider.selectedCategory != null) {
      return [
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.65,
              crossAxisSpacing: 12,
              mainAxisSpacing: 16,
            ),
            delegate: SliverChildBuilderDelegate(
              (c, i) => ProductCardItem(
                product: provider.products[i],
                isHot: provider.popularIds.contains(provider.products[i].id),
              ),
              childCount: provider.products.length,
            ),
          ),
        ),
      ];
    }

    List<Widget> slivers = [];

    for (var category in provider.categories) {
      final categoryProducts = provider.groupedProducts[category.id] ?? [];
      if (categoryProducts.isEmpty) continue;

      slivers.add(
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                child: Text(
                  category.getName(context),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF452512),
                  ),
                ),
              ),
              SizedBox(
                height: 260,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: categoryProducts.length,
                  itemBuilder: (context, index) {
                    final product = categoryProducts[index];
                    return Container(
                      width: 160,
                      margin: const EdgeInsetsDirectional.only(end: 15),
                      child: ProductCardItem(
                        product: product,
                        isHot: provider.popularIds.contains(product.id),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      );
    }

    if (slivers.isEmpty && provider.products.isNotEmpty) {
      slivers.add(
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.65,
              crossAxisSpacing: 12,
              mainAxisSpacing: 16,
            ),
            delegate: SliverChildBuilderDelegate(
              (c, i) => ProductCardItem(
                product: provider.products[i],
                isHot: provider.popularIds.contains(provider.products[i].id),
              ),
              childCount: provider.products.length,
            ),
          ),
        ),
      );
    }

    return slivers;
  }

  void _onBannerTap(BannerModel banner) {
    final provider = Provider.of<HomeProvider>(context, listen: false);
    if (banner.category != null) {
      try {
        final cat = provider.categories.firstWhere(
          (c) => c.id == banner.category,
        );
        _switchCategory(cat.slug);
      } catch (e) {
        debugPrint('Category not found for banner: ${banner.category}');
      }
    }
  }

  List<Widget> _buildCategoriesSlivers(HomeProvider provider) {
    return [
      const SliverToBoxAdapter(child: SizedBox(height: 20)),
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    AppLocalizations.of(context)!.translate('categories'),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w300,
                      color: Color(0xFF452512),
                      height: 1.2,
                    ),
                  ),
                  if (provider.selectedCategory != null) ...[
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        // Clear filter logic
                        _switchCategory(null);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          size: 16,
                          color: AppColors.secondary,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 5),
        sliver: SliverGrid(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 15,
            childAspectRatio: 0.85,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, index) => _buildCategoryItem(
              category: provider.categories[index],
              provider: provider,
            ),
            childCount: provider.categories.length,
          ),
        ),
      ),
      const SliverToBoxAdapter(child: SizedBox(height: 10)),
    ];
  }

  /* Old _buildCategoriesSection removed in favor of _buildCategoriesSlivers */

  Widget _buildCategoryItem({
    required CategoryModel category,
    required HomeProvider provider,
  }) {
    bool isSelected = provider.selectedCategory == category.slug;
    return CategoryItem(
      category: category,
      isSelected: isSelected,
      onTap: () {
        if (isSelected) {
          _switchCategory(null);
        } else {
          _switchCategory(category.slug);
        }
      },
    );
  }
}

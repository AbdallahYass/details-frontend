// ignore_for_file: use_build_context_synchronously

import 'package:flutter/cupertino.dart';
import 'package:details_app/app_imports.dart';
import 'package:details_app/widgets/custom_loading_overlay.dart';
import 'package:details_app/providers/notification_provider.dart';
import 'dart:ui';

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
  int _requestId = 0; // لمنع Race Condition

  final ValueNotifier<int> _bannerIndexNotifier = ValueNotifier(0);
  final PageController _heroController = PageController(viewportFraction: 0.92);
  Timer? _heroTimer;

  String? _selectedCategory;
  final Map<String, List<Product>> _groupedProducts = {};
  final HomeRepository _homeRepository = HomeRepository();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

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

  @override
  Widget build(BuildContext context) {
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
            ),
          ),
          CustomScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.only(top: 120),
                sliver: CupertinoSliverRefreshControl(
                  onRefresh: () => _loadAllData(forceRefresh: true),
                  builder:
                      (
                        context,
                        refreshState,
                        pulledExtent,
                        refreshTriggerPullDistance,
                        refreshIndicatorExtent,
                      ) {
                        final double opacity =
                            (pulledExtent / refreshTriggerPullDistance).clamp(
                              0.0,
                              1.0,
                            );
                        return Container(
                          alignment: Alignment.center,
                          child: Opacity(
                            opacity: opacity,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
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
                        );
                      },
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
                SliverToBoxAdapter(
                  child: (isLoading && banners.isEmpty)
                      ? _buildHeroSkeleton()
                      : _buildHeroSlider(),
                ),
                SliverToBoxAdapter(
                  child: (isLoading && categories.isEmpty)
                      ? _buildCategoriesSkeleton()
                      : _buildCategoriesSection(),
                ),
                if (popularProducts.isNotEmpty && _selectedCategory == null)
                  SliverToBoxAdapter(child: _buildPopularSection()),
                if (isLoading && products.isEmpty)
                  SliverToBoxAdapter(child: _buildProductsSkeleton())
                else
                  ..._buildCategoryGrids(),
                const SliverToBoxAdapter(child: SizedBox(height: 50)),
                SliverToBoxAdapter(
                  child: RevealOnScroll(child: _buildFooter()),
                ),
              ],
            ],
          ),
          if (isLoading && products.isEmpty)
            const CustomLoadingOverlay(isOverlay: false),
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
        ],
      ),
    );
  }

  Widget _buildProductsSkeleton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 4,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.65,
          crossAxisSpacing: 15,
          mainAxisSpacing: 25,
        ),
        itemBuilder: (context, index) => Container(
          decoration: BoxDecoration(
            color: AppColors.imagePlaceholder,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget _buildPopularSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 15),
          child: Row(
            children: [
              const Icon(
                Icons.local_fire_department,
                color: AppColors.primary,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                AppLocalizations.of(context)!.translate('most_popular'),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.homeSectionTitle,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 260,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
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
        const SizedBox(height: 10),
      ],
    );
  }

  List<Widget> _buildCategoryGrids() {
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

    List<Widget> slivers = [];

    for (var category in categories) {
      final categoryProducts = _groupedProducts[category.id] ?? [];
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
                    color: AppColors.homeSectionTitle,
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
                    return Container(
                      width: 160,
                      margin: const EdgeInsetsDirectional.only(end: 15),
                      child: _buildProductCard(categoryProducts[index]),
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

    if (slivers.isEmpty && products.isNotEmpty) {
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
    final isHot = _popularIds.contains(p.id);

    return Selector<WishlistProvider, bool>(
      selector: (context, wishlistProvider) =>
          wishlistProvider.isInWishlist(p.id),
      builder: (context, isFav, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  // الحل السحري لتفادي كراش الأبعاد: منع الـ Stack من إجبار الصورة على التمدد
                  fit: StackFit.loose,
                  children: [
                    // تم تغليف الصورة بـ Positioned.fill لتحجيمها بالشكل الصحيح داخل الـ Stack
                    Positioned.fill(
                      child: GestureDetector(
                        onTap: () => context.push('/product/${p.id}', extra: p),
                        child: Hero(
                          tag: p.id,
                          child: AnimatedProductImage(product: p),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 10,
                      right: 10,
                      child: _circleIcon(
                        isFav ? Icons.favorite : Icons.favorite_border,
                        size: 20,
                        color: isFav
                            ? AppColors.homeFavActive
                            : AppColors.homeFavInactive,
                        onTap: () async {
                          final messenger = ScaffoldMessenger.of(context);
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
                                    child: Text(
                                      AppLocalizations.of(
                                        context,
                                      )!.translate('cancel'),
                                    ),
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
                          final wishlistProvider =
                              Provider.of<WishlistProvider>(
                                context,
                                listen: false,
                              );
                          bool added = await wishlistProvider.toggleWishlist(p);
                          if (!mounted) return;
                          messenger.hideCurrentSnackBar();
                          messenger.showSnackBar(
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
                        color: AppColors.homeProductIcon,
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
                          _circleIcon(
                            Icons.share,
                            isWhite: true,
                            onTap: () async {
                              try {
                                final currency = AppLocalizations.of(
                                  context,
                                )!.translate('currency');
                                final text =
                                    '🌟 *Check out this amazing product!* 🌟\n\n'
                                    '🛍️ *${p.getName(context)}*\n'
                                    '💰 Price: *${p.price} $currency*\n\n'
                                    '🔗 Link: https://details-store.com/product/${p.id}\n\n'
                                    '_Sent from Details Store App_';

                                if (kIsWeb) {
                                  await SharePlus.instance.share(
                                    ShareParams(text: text),
                                  );
                                } else {
                                  final file = await DefaultCacheManager()
                                      .getSingleFile(p.imageUrl);
                                  await SharePlus.instance.share(
                                    ShareParams(
                                      files: [XFile(file.path)],
                                      text: text,
                                    ),
                                  );
                                }
                              } catch (e) {
                                debugPrint('Error sharing: $e');
                              }
                            },
                          ),
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
                            color: AppColors.homeBadgeSoldOut,
                            borderRadius: BorderRadius.only(
                              topRight: Radius.circular(20),
                              bottomRight: Radius.circular(20),
                            ),
                          ),
                          child: Text(
                            AppLocalizations.of(context)!.translate('sold_out'),
                            style: const TextStyle(
                              color: AppColors.homeBadgeText,
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
                            color: AppColors.homeBadgeHot,
                            borderRadius: BorderRadius.only(
                              topRight: Radius.circular(20),
                              bottomRight: Radius.circular(20),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.local_fire_department,
                                size: 12,
                                color: AppColors.homeBadgeText,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                AppLocalizations.of(context)!.translate('hot'),
                                style: const TextStyle(
                                  color: AppColors.homeBadgeText,
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
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.homeProductPrice,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
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
          color: isWhite ? AppColors.homeBackground : AppColors.homeIconBg,
          shape: BoxShape.circle,
          boxShadow: isWhite
              ? [BoxShadow(color: AppColors.homeIconShadow, blurRadius: 4)]
              : [],
        ),
        child: Icon(
          icon,
          color: color ?? AppColors.homeFavInactive,
          size: size,
        ),
      ),
    );
  }

  Widget _buildHeroSlider() => banners.isEmpty
      ? const SizedBox()
      : SizedBox(
          height: 320,
          child: VisibilityDetector(
            key: const Key('hero-slider'),
            onVisibilityChanged: (info) {
              if (info.visibleFraction == 0) {
                _heroTimer?.cancel();
              } else {
                _startHeroScroll();
              }
            },
            child: Column(
              children: [
                Expanded(
                  child: Listener(
                    onPointerDown: (_) => _heroTimer?.cancel(),
                    onPointerUp: (_) => _startHeroScroll(),
                    child: PageView.builder(
                      controller: _heroController,
                      itemCount: banners.length,
                      onPageChanged: (i) {
                        _bannerIndexNotifier.value = i;
                      },
                      itemBuilder: (c, i) {
                        return AnimatedBuilder(
                          animation: _heroController,
                          builder: (context, child) {
                            double value = 1.0;
                            if (_heroController.position.haveDimensions) {
                              value = _heroController.page! - i;
                              value = (1 - (value.abs() * 0.08)).clamp(
                                0.92,
                                1.0,
                              );
                            } else {
                              value = i == _bannerIndexNotifier.value
                                  ? 1.0
                                  : 0.92;
                            }
                            return Transform.scale(
                              scale: Curves.easeOut.transform(value),
                              child: child,
                            );
                          },
                          child: GestureDetector(
                            onTap: () => _onBannerTap(banners[i]),
                            child: Container(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.black.withValues(
                                      alpha: 0.3,
                                    ),
                                    blurRadius: 15,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: AnimatedBannerItem(banner: banners[i]),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ValueListenableBuilder<int>(
                  valueListenable: _bannerIndexNotifier,
                  builder: (context, currentIndex, child) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        banners.length,
                        (i) => _dot(i == currentIndex),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );

  void _onBannerTap(BannerModel banner) {
    if (banner.category != null) {
      try {
        final cat = categories.firstWhere((c) => c.id == banner.category);
        final int currentRequest = ++_requestId;
        setState(() {
          _selectedCategory = cat.slug;
          isLoading = true;
          errorMessage = null;
          products = [];
        });

        Future.wait<dynamic>([
              _homeRepository.fetchProducts(category: _selectedCategory),
              _homeRepository.fetchBanners(
                location: 'category',
                category: _selectedCategory,
              ),
            ])
            .then((results) {
              if (mounted && currentRequest == _requestId) {
                setState(() {
                  products = results[0] as List<Product>;
                  banners = results[1] as List<BannerModel>;
                  _groupProducts();
                  isLoading = false;
                  _bannerIndexNotifier.value = 0;
                  if (_heroController.hasClients) {
                    _heroController.jumpToPage(0);
                  }
                });
                _startHeroScroll();
              }
            })
            .catchError((e) {
              debugPrint("Error loading category data: $e");
              if (mounted && currentRequest == _requestId) {
                setState(() {
                  isLoading = false;
                  errorMessage = AppLocalizations.of(
                    context,
                  )!.translate('error_occurred');
                });
              }
            });
      } catch (e) {
        debugPrint('Category not found for banner: ${banner.category}');
      }
    }
  }

  Widget _dot(bool active) => AnimatedContainer(
    duration: const Duration(milliseconds: 300),
    margin: const EdgeInsets.symmetric(horizontal: 4),
    width: active ? 16 : 8,
    height: 8,
    decoration: BoxDecoration(
      color: active ? AppColors.homeDotActive : AppColors.homeDotInactive,
      borderRadius: BorderRadius.circular(20),
    ),
  );

  Widget _buildCategoriesSection() => Column(
    children: [
      const SizedBox(height: 20),
      Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            Text(
              AppLocalizations.of(context)!.translate('categories'),
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w300,
                color: AppColors.textPrimary,
                //letterSpacing: 12.0,
                height: 1.2,
              ),
            ),
            GridView.builder(
              padding: const EdgeInsets.all(15),
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
      onTap: () async {
        final int currentRequest = ++_requestId;
        setState(() {
          if (_selectedCategory == category.slug) {
            _selectedCategory = null;
          } else {
            _selectedCategory = category.slug;
          }
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
              if (_selectedCategory == null) {
                _groupProducts();
              }
              isLoading = false;
              _bannerIndexNotifier.value = 0;
              if (_heroController.hasClients) {
                _heroController.jumpToPage(0);
              }
            });
          }
        } catch (e) {
          debugPrint("Error loading category data: $e");
          if (mounted && currentRequest == _requestId) {
            setState(() {
              isLoading = false;
              errorMessage = AppLocalizations.of(
                context,
              )!.translate('error_occurred');
            });
          }
        }
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isSelected
                    ? [
                        AppColors.primary.withValues(alpha: 0.15),
                        AppColors.primary.withValues(alpha: 0.05),
                      ]
                    : [
                        Colors.white.withValues(alpha: 0.7),
                        Colors.white.withValues(alpha: 0.3),
                      ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.6)
                    : Colors.white.withValues(alpha: 0.8),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: isSelected
                      ? AppColors.primary.withValues(alpha: 0.1)
                      : AppColors.black.withValues(alpha: 0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                Expanded(
                  flex: 3,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(18),
                    ),
                    child: CachedNetworkImage(
                      imageUrl: category.imageUrl,
                      memCacheWidth: 250,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      placeholder: (context, url) =>
                          Container(color: AppColors.imagePlaceholder),
                      errorWidget: (context, url, error) => Center(
                        child: Icon(
                          Icons.category_outlined,
                          color: AppColors.homeCategoryIcon,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        category.getName(context),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isSelected
                              ? FontWeight.w800
                              : FontWeight.w600,
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.textPrimary,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() => Container(
    width: double.infinity,
    color: AppColors.homeFooterBackground,
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
        const Divider(color: AppColors.footerDivider, height: 1),
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
        const SizedBox(height: 40),
        const Divider(color: AppColors.footerDivider),
        const SizedBox(height: 20),
        Text(
          AppLocalizations.of(context)!.translate('copyright'),
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.footerText,
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
          color: AppColors.footerTextSecondary,
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
                debugPrint('Could not launch Instagram');
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
                debugPrint('Could not launch WhatsApp');
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
            color: AppColors.footerText,
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
                child: Text(AppLocalizations.of(context)!.translate('ok')),
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
            color: AppColors.footerText,
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
    List<Widget>? customChildren,
  }) => Theme(
    data: ThemeData().copyWith(dividerColor: AppColors.transparent),
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
      children:
          customChildren ??
          i
              .map(
                (item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Text(
                    item,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.footerText,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              )
              .toList(),
    ),
  );

  Widget _contactRow(IconData i, String t) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          t,
          style: const TextStyle(
            color: AppColors.footerTextSecondary,
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

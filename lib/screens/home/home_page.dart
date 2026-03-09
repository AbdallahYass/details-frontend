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
  final PageController _heroController = PageController();
  Timer? _heroTimer;

  String? _selectedCategory;
  final Map<String, List<Product>> _groupedProducts = {};
  final HomeRepository _homeRepository = HomeRepository();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _loadAllData();

    // التعديل هنا: فحص الجلسة فور الدخول للتأكد من أن الحساب غير محذوف
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final auth = Provider.of<AuthProvider>(context, listen: false);

      if (auth.token != null) {
        // بدلاً من الوثوق بالتوكن، نقوم بتجربة تسجيل دخول صامت سريع للتحقق من السيرفر
        await auth.tryAutoLogin();

        // إذا نجح التحقق ولا يزال المستخدم موجوداً، نجلب الإشعارات
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
              if (errorMessage != null)
                SliverFillRemaining(
                  child: CommonErrorWidget(
                    message: errorMessage!,
                    onRetry: () => _loadAllData(forceRefresh: true),
                  ),
                )
              else ...[
                SliverToBoxAdapter(child: _buildAnnouncementBar()),
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
                if (popularProducts.isNotEmpty &&
                    _selectedCategory == null) ...[
                  SliverToBoxAdapter(child: _buildSectionDivider()),
                  SliverToBoxAdapter(child: _buildPopularSection()),
                ],
                if (!isLoading && products.isNotEmpty)
                  SliverToBoxAdapter(child: _buildSectionDivider()),
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

  Widget _buildAnnouncementBar() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 5, 16, 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF452512),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFD4AF37).withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(
            Icons.local_shipping_outlined,
            color: Color(0xFFD4AF37),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "التوصيل متاح لجميع مناطق الضفة والقدس والداخل 🚛",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
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
            height: 290,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: popularProducts.length,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemBuilder: (context, index) {
                return Container(
                  width: 175,
                  margin: const EdgeInsetsDirectional.only(end: 16),
                  child: _buildProductCard(
                    popularProducts[index],
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

  List<Widget> _buildCategoryGrids() {
    if (_selectedCategory != null) {
      return [
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.58,
              crossAxisSpacing: 12,
              mainAxisSpacing: 16,
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
              childAspectRatio: 0.58,
              crossAxisSpacing: 12,
              mainAxisSpacing: 16,
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

  Widget _buildProductCard(Product p, {bool heroEnabled = true}) {
    final isHot = _popularIds.contains(p.id);

    return Selector<WishlistProvider, bool>(
      selector: (context, wishlistProvider) =>
          wishlistProvider.isInWishlist(p.id),
      builder: (context, isFav, child) {
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFFFDFBF7),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(12),
                        ),
                        child: GestureDetector(
                          onTap: () =>
                              context.push('/product/${p.id}', extra: p),
                          child: HeroMode(
                            enabled: heroEnabled,
                            child: Hero(
                              tag: p.id,
                              child: AnimatedProductImage(product: p),
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Badges
                    if (p.isSoldOut)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.black.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(4),
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
                      )
                    else if (isHot)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.red.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.local_fire_department,
                                size: 10,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                AppLocalizations.of(context)!.translate('hot'),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    // Fav Button
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: () async {
                          final messenger = ScaffoldMessenger.of(context);
                          final auth = Provider.of<AuthProvider>(
                            context,
                            listen: false,
                          );
                          if (!auth.isAuthenticated) {
                            context.push('/login');
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
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.9),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isFav ? Icons.favorite : Icons.favorite_border,
                            size: 16,
                            color: isFav ? AppColors.red : AppColors.grey,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 8,
                      left: 8,
                      child: Column(
                        children: [
                          _circleIcon(
                            Icons.visibility_outlined,
                            isWhite: true,
                            onTap: () =>
                                context.push('/product/${p.id}', extra: p),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Info Section
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      p.getName(context),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF452512),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${p.price.toStringAsFixed(2)} ${AppLocalizations.of(context)!.translate('currency')}",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 30,
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () async {
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
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          side: BorderSide(
                            color: AppColors.primary.withValues(alpha: 0.2),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.share,
                              size: 14,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              AppLocalizations.of(
                                context,
                              )!.translate('share_title'),
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
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
          height: 260,
          child: VisibilityDetector(
            key: const Key('hero-slider'),
            onVisibilityChanged: (info) {
              if (info.visibleFraction == 0) {
                _heroTimer?.cancel();
              } else {
                _startHeroScroll();
              }
            },
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                Listener(
                  onPointerDown: (_) => _heroTimer?.cancel(),
                  onPointerUp: (_) => _startHeroScroll(),
                  child: PageView.builder(
                    controller: _heroController,
                    itemCount: banners.length,
                    onPageChanged: (i) {
                      _bannerIndexNotifier.value = i;
                    },
                    itemBuilder: (c, i) {
                      return GestureDetector(
                        onTap: () => _onBannerTap(banners[i]),
                        child: Container(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.black.withValues(alpha: 0.2),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                AnimatedBannerItem(banner: banners[i]),
                                Positioned(
                                  bottom: 0,
                                  left: 0,
                                  right: 0,
                                  height: 80,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.bottomCenter,
                                        end: Alignment.topCenter,
                                        colors: [
                                          Colors.black.withValues(alpha: 0.7),
                                          Colors.transparent,
                                        ],
                                      ),
                                    ),
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
                Positioned(
                  bottom: 20,
                  child: ValueListenableBuilder<int>(
                    valueListenable: _bannerIndexNotifier,
                    builder: (context, currentIndex, child) {
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(
                          banners.length,
                          (i) => AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            width: i == currentIndex ? 20 : 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: i == currentIndex
                                  ? AppColors.white
                                  : AppColors.white.withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
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
                color: const Color(0xFF452512),
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
                              : const Color(0xFF452512),
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
    color: const Color(0xFF121212),
    padding: const EdgeInsets.only(
      top: 60,
      bottom: 120, // مساحة إضافية عشان الناف بار ما يغطي الفوتر
      left: 24,
      right: 24,
    ),
    child: Column(
      children: [
        // Branding
        const Text(
          'DETAILS',
          style: TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.w900,
            letterSpacing: 6,
          ),
        ),
        Text(
          'STORE',
          style: TextStyle(
            color: AppColors.secondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 8,
          ),
        ),
        const SizedBox(height: 30),

        // Description
        Text(
          AppLocalizations.of(context)!.translate('footer_about_desc'),
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 13,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 30),

        // Contact Info
        Column(
          children: [
            _contactRow(Icons.email_outlined, "support@details-store.com"),
            const SizedBox(height: 10),
            _contactRow(Icons.phone_android, "+972-598723438"),
          ],
        ),
        const SizedBox(height: 30),

        // Social Buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _socialButton(
              FontAwesomeIcons.instagram,
              'https://www.instagram.com/details__store__?igsh=c3Nuam5mNDM4ajBp',
            ),
            const SizedBox(width: 20),
            _socialButton(
              FontAwesomeIcons.whatsapp,
              'https://wa.me/972598723438',
            ),
          ],
        ),
        const SizedBox(height: 40),

        // Links (Accordions)
        Container(
          decoration: BoxDecoration(
            border: Border.symmetric(
              horizontal: BorderSide(
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
          ),
          child: Column(
            children: [
              _footerAccordion(
                AppLocalizations.of(context)!.translate('language'),
                customChildren: [
                  _buildLanguageItem('العربية', const Locale('ar', '')),
                  _buildLanguageItem('English', const Locale('en', '')),
                ],
              ),
              Divider(height: 1, color: Colors.white.withValues(alpha: 0.1)),
              _footerAccordion(
                AppLocalizations.of(context)!.translate('policies'),
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
            ],
          ),
        ),
        const SizedBox(height: 40),

        // Copyright
        Text(
          AppLocalizations.of(context)!.translate('copyright'),
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.3),
            fontSize: 11,
          ),
        ),
      ],
    ),
  );

  Widget _buildLanguageItem(String label, Locale locale) {
    return GestureDetector(
      onTap: () {
        Provider.of<SettingsProvider>(context, listen: false).setLocale(locale);
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        child: Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 13,
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
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        child: Text(
          title,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _footerAccordion(String title, {List<Widget>? customChildren}) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        iconColor: AppColors.secondary,
        collapsedIconColor: Colors.white.withValues(alpha: 0.5),
        tilePadding: const EdgeInsets.symmetric(horizontal: 10),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        children: customChildren ?? [],
      ),
    );
  }

  Widget _contactRow(IconData icon, String text) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: AppColors.secondary, size: 16),
        const SizedBox(width: 10),
        Text(
          text,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _socialButton(IconData icon, String url) {
    return GestureDetector(
      onTap: () async {
        if (!await launchUrl(
          Uri.parse(url),
          mode: LaunchMode.externalApplication,
        )) {
          debugPrint('Could not launch $url');
        }
      },
      child: Container(
        width: 45,
        height: 45,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.05),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: FaIcon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}

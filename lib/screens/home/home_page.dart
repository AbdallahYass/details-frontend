import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:details_app/app_imports.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
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
  final Map<String, PageController> _categoryControllers = {};
  final HomeRepository _homeRepository = HomeRepository();

  final TextEditingController _subscribeController = TextEditingController();
  bool _isSubscribing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadAllData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _heroTimer?.cancel();
    _bannerIndexNotifier.dispose();
    _heroController.dispose();
    for (var controller in _categoryControllers.values) {
      controller.dispose();
    }
    _subscribeController.dispose();
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
          _syncCategoryControllers(); // تنظيف الذاكرة
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

  void _syncCategoryControllers() {
    final currentIds = categories.map((e) => e.id).toSet();
    _categoryControllers.removeWhere((key, controller) {
      if (!currentIds.contains(key)) {
        controller.dispose();
        return true;
      }
      return false;
    });
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

  Future<void> _subscribe() async {
    final email = _subscribeController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.translate('enter_valid_email'),
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSubscribing = true);

    try {
      final response = await http.post(
        Uri.parse('https://api.details-store.com/api/subscribe'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email}),
      );

      if (!mounted) return;

      final data = json.decode(response.body);

      if (response.statusCode == 201 || response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? 'تم الاشتراك بنجاح'),
            backgroundColor: AppColors.success,
          ),
        );
        _subscribeController.clear();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? 'فشل الاشتراك'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.translate('error_occurred'),
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubscribing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () => _loadAllData(forceRefresh: true),
      color: AppColors.primary,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            floating: true,
            pinned: true,
            backgroundColor: AppColors.appBarBackground,
            foregroundColor: AppColors.appBarForeground,
            elevation: 0,
            centerTitle: true,
            leading: Builder(
              builder: (context) {
                return IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                );
              },
            ),
            title: Image.asset('assets/images/logo2.png', height: 100),
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () {},
              ),
            ],
          ),
          if (errorMessage != null)
            SliverFillRemaining(
              child: CommonErrorWidget(
                message: errorMessage!,
                onRetry: () => _loadAllData(forceRefresh: true),
              ),
            )
          else ...[
            // Hero Section (Show Skeleton only if loading AND empty)
            SliverToBoxAdapter(
              child: (isLoading && banners.isEmpty)
                  ? _buildHeroSkeleton()
                  : _buildHeroSlider(),
            ),

            // Categories Section (Show Skeleton only if loading AND empty)
            SliverToBoxAdapter(
              child: (isLoading && categories.isEmpty)
                  ? _buildCategoriesSkeleton()
                  : _buildCategoriesSection(),
            ),

            // Popular Section (Keep visible if data exists, even during loading)
            if (popularProducts.isNotEmpty && _selectedCategory == null)
              SliverToBoxAdapter(child: _buildPopularSection()),

            // Products Grid (Show Skeleton OVER content if loading, otherwise content)
            if (isLoading && products.isEmpty)
              SliverToBoxAdapter(child: _buildProductsSkeleton())
            else
              ..._buildCategoryGrids(),

            const SliverToBoxAdapter(child: SizedBox(height: 50)),
            SliverToBoxAdapter(child: RevealOnScroll(child: _buildFooter())),
          ],
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
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 20, 16, 10),
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: AppColors.homeBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.homeSectionBorder, width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColor,
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
              const Icon(Icons.star, color: AppColors.starColor, size: 24),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  AppLocalizations.of(context)!.translate('most_popular'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.homeSectionTitle,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.star, color: AppColors.starColor, size: 24),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            AppLocalizations.of(context)!.translate('best_seller_week'),
            style: const TextStyle(
              color: AppColors.homeSectionSubtitle,
              fontSize: 12,
            ),
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

    // حساب أبعاد PageView
    final double screenWidth = MediaQuery.of(context).size.width;
    final double availableWidth = screenWidth - 32; // margin 16 * 2
    final double viewportFraction = 0.92;
    final double pageWidth = availableWidth * viewportFraction;
    final double itemWidth =
        (pageWidth - 16 - 10) / 2; // padding 8*2 + spacing 10
    final double itemHeight = itemWidth / 0.65;
    final double pageViewHeight = (itemHeight * 2) + 10;

    for (var category in categories) {
      // تصفية المنتجات التابعة لهذا القسم
      final categoryProducts = _groupedProducts[category.id] ?? [];

      // إذا لم يكن هناك منتجات في هذا القسم، لا نعرضه
      if (categoryProducts.isEmpty) continue;

      if (!_categoryControllers.containsKey(category.id)) {
        _categoryControllers[category.id] = PageController(
          viewportFraction: viewportFraction,
        );
      }

      int itemsPerPage = 4;
      int totalPages = (categoryProducts.length / itemsPerPage).ceil();

      slivers.add(
        SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.homeBackground,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadowColor,
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
                    color: AppColors.homeSectionTitle,
                  ),
                ),
                const SizedBox(height: 15),

                SizedBox(
                  height: pageViewHeight,
                  child: PageView.builder(
                    controller: _categoryControllers[category.id],
                    itemCount: totalPages,
                    itemBuilder: (context, pageIndex) {
                      int startIndex = pageIndex * itemsPerPage;
                      int endIndex = startIndex + itemsPerPage;
                      if (endIndex > categoryProducts.length) {
                        endIndex = categoryProducts.length;
                      }
                      final currentProducts = categoryProducts.sublist(
                        startIndex,
                        endIndex,
                      );

                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        child: Column(
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Expanded(
                                    child: _buildProductCard(
                                      currentProducts[0],
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: currentProducts.length > 1
                                        ? _buildProductCard(currentProducts[1])
                                        : const SizedBox(),
                                  ),
                                ],
                              ),
                            ),
                            if (currentProducts.length > 2) ...[
                              const SizedBox(height: 10),
                              Expanded(
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: _buildProductCard(
                                        currentProducts[2],
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: currentProducts.length > 3
                                          ? _buildProductCard(
                                              currentProducts[3],
                                            )
                                          : const SizedBox(),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                ),
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
    final isFav = context.select<WishlistProvider, bool>(
      (w) => w.isInWishlist(p.id),
    );
    final isHot = _popularIds.contains(p.id);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: AppColors.homeBackground,
              border: Border.all(color: AppColors.cardBorder),
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
                        final wishlistProvider = Provider.of<WishlistProvider>(
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
                                  '🔗 Link: ${AppConstants.shareBaseUrl}/product/${p.id}\n\n'
                                  '_Sent from Details Store App_';

                              if (kIsWeb) {
                                await SharePlus.instance.share(
                                  ShareParams(text: text),
                                );
                              } else {
                                // استخدام الكاش لجلب الصورة
                                final file = await DefaultCacheManager()
                                    .getSingleFile(p.imageUrl);

                                // مشاركة الصورة مع النص
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
                            SizedBox(width: 2),
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
          height: 220,
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
              alignment: Alignment.center,
              children: [
                PageView.builder(
                  controller: _heroController,
                  itemCount: banners.length,
                  onPageChanged: (i) {
                    _bannerIndexNotifier.value = i;
                    _heroTimer?.cancel();
                    _startHeroScroll();
                  },
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
          ),
        );

  void _onBannerTap(BannerModel banner) {
    // تأكد من أن BannerModel يحتوي على حقل category
    if (banner.category != null) {
      try {
        // البحث عن القسم المطابق للـ ID الموجود في الإعلان
        final cat = categories.firstWhere((c) => c.id == banner.category);

        final int currentRequest = ++_requestId;
        // تفعيل القسم وتحديث الصفحة (نفس منطق الضغط على دائرة القسم)
        setState(() {
          _selectedCategory = cat.slug;
          isLoading = true;
          errorMessage = null;
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
                  _syncCategoryControllers();
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
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.homeBackground,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowColor,
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
                color: AppColors.homeSectionTitle,
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
              _syncCategoryControllers();
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
                color: AppColors.transparent,
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.transparent,
                  width: 2,
                ),
                boxShadow: [
                  if (!isSelected)
                    BoxShadow(
                      color: AppColors.shadowColor,
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
                      Container(color: AppColors.imagePlaceholder),
                  errorWidget: (context, url, error) => Icon(
                    Icons.category_outlined,
                    color: isSelected
                        ? AppColors.white
                        : AppColors.homeCategoryIcon,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              category.getName(context),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected
                    ? AppColors.primary
                    : AppColors.homeCategoryText,
              ),
            ),
          ],
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
        const Divider(color: AppColors.footerDivider, height: 1),
        _footerAccordion(
          AppLocalizations.of(context)!.translate('stay_updated'),
          [],
          isSubscribe: true,
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
    bool isSubscribe = false,
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
  Widget _buildSubscribeField() => Column(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      Text(
        AppLocalizations.of(context)!.translate('subscribe_text'),
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: AppColors.footerText,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 15),
      Container(
        height: 50,
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.inputBorder),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: _isSubscribing ? null : _subscribe,
              child: Container(
                margin: const EdgeInsets.all(4),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: AppColors.subscribeBg,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Center(
                  child: _isSubscribing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.white,
                          ),
                        )
                      : Text(
                          AppLocalizations.of(
                            context,
                          )!.translate('subscribe_button'),
                          style: const TextStyle(
                            color: AppColors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ),
            Expanded(
              child: TextField(
                controller: _subscribeController,
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
                    color: AppColors.hintText,
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

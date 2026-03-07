// ignore_for_file: curly_braces_in_flow_control_structures, use_build_context_synchronously

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:details_app/app_imports.dart';
import 'package:details_app/widgets/custom_loading_overlay.dart';
import 'package:details_app/providers/notification_provider.dart';
import 'package:details_app/screens/home/notifications_screen.dart';
import 'dart:ui';

class ProductDetailsScreen extends StatefulWidget {
  final Product? product;
  final String? productId;
  const ProductDetailsScreen({super.key, this.product, this.productId});

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  Product? _product;
  bool _isLoadingProduct = true;
  int _currentImageIndex = 0;
  List<Product> relatedProducts = [];
  bool isLoadingRelated = true;
  String? _selectedSize;
  bool _isActionLoading = false;
  final PageController _pageController = PageController();
  int _selectedColorIndex = 0;

  // اللون البني الداكن الخاص بهوية المتجر
  final Color _dsBrown = const Color(0xFF452512);

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      _product = widget.product;
      _isLoadingProduct = false;
      _fetchRelatedProducts();
    } else if (widget.productId != null) {
      _fetchProductById(widget.productId!);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _fetchProductById(String id) async {
    try {
      final res = await http.get(
        Uri.parse('https://api.details-store.com/api/products/$id'),
      );
      if (res.statusCode == 200) {
        if (mounted) {
          setState(() {
            _product = Product.fromJson(json.decode(res.body));
            _isLoadingProduct = false;
          });
          _fetchRelatedProducts();
        }
      }
    } catch (e) {
      debugPrint("Error fetching product details: $e");
      if (mounted) setState(() => _isLoadingProduct = false);
    }
  }

  Future<void> _fetchRelatedProducts() async {
    if (_product == null) return;
    try {
      final res = await http.get(
        Uri.parse('https://api.details-store.com/api/products'),
      );
      if (res.statusCode == 200) {
        final List<dynamic> data = json.decode(res.body);
        if (mounted) {
          setState(() {
            relatedProducts = data
                .map((j) => Product.fromJson(j))
                .where((p) => p.id != _product!.id)
                .take(5)
                .toList();
            isLoadingRelated = false;
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching related: $e");
      if (mounted) setState(() => isLoadingRelated = false);
    }
  }

  int get _availableQuantity {
    if (_product == null) return 0;
    if (_product!.sizes.isNotEmpty) {
      if (_selectedSize == null) return 0;
      final sizeObj = _product!.sizes.firstWhere(
        (s) => s.size == _selectedSize,
        orElse: () => ProductSize(size: '', quantity: 0),
      );
      return sizeObj.quantity;
    }
    return _product!.quantity;
  }

  Color _parseColor(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return Colors.grey;
    }
  }

  void _shareProduct() async {
    try {
      final currency = AppLocalizations.of(context)!.translate('currency');
      final text =
          '🌟 *${AppLocalizations.of(context)!.translate('share_title')}* 🌟\n\n'
          '🛍️ *${_product!.getName(context)}*\n'
          '💰 ${AppLocalizations.of(context)!.translate('price_label')}: *${_product!.price} $currency*\n\n'
          '🔗 ${AppLocalizations.of(context)!.translate('link_label')}: ${AppConstants.shareBaseUrl}/product/${_product!.id}\n\n'
          '_${AppLocalizations.of(context)!.translate('sent_from_app')}_';

      if (kIsWeb) {
        await SharePlus.instance.share(ShareParams(text: text));
      } else {
        final file = await DefaultCacheManager().getSingleFile(
          _product!.imageUrl,
        );
        await SharePlus.instance.share(
          ShareParams(files: [XFile(file.path)], text: text),
        );
      }
    } catch (e) {
      debugPrint('Error sharing: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingProduct) {
      return const Scaffold(
        backgroundColor: Color(0xFFFDFBF7),
        body: CustomLoadingOverlay(isOverlay: false),
      );
    }
    if (_product == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFFDFBF7),
        body: Center(
          child: Text(
            AppLocalizations.of(context)!.translate('product_not_found'),
          ),
        ),
      );
    }

    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFFFDFBF7),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // 1. Scrollable Content (Image + Details)
          Positioned.fill(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(
                bottom: 120,
              ), // مساحة للشريط السفلي
              child: Column(
                children: [
                  // معرض الصور
                  SizedBox(
                    height: screenHeight * 0.55,
                    child: _buildImageGallery(),
                  ),
                  // الكارد اللي بيركب فوق الصورة
                  Container(
                    transform: Matrix4.translationValues(0, -35, 0),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFDFBF7),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(35),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _dsBrown.withValues(alpha: 0.1),
                          blurRadius: 20,
                          offset: const Offset(0, -5),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 30, 24, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildTitleAndPrice(),
                          const SizedBox(height: 25),
                          if (_product!.images.length > 1) _buildThumbnails(),
                          if (_product!.images.length > 1)
                            const SizedBox(height: 25),
                          if (_product!.colors.isNotEmpty)
                            _buildColorSelector(),
                          if (_product!.sizes.isNotEmpty) _buildSizeSelector(),
                          const SizedBox(height: 30),
                          _buildDescription(),
                          if (relatedProducts.isNotEmpty)
                            _buildRelatedProducts(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 2. Glassmorphism Top Bar (Floating Buttons)
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 20,
            right: 20,
            child: _buildFloatingAppBar(),
          ),

          // 3. Fixed Bottom Action Bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomActionBar(),
          ),

          if (_isActionLoading) const CustomLoadingOverlay(),
        ],
      ),
    );
  }

  Widget _buildFloatingAppBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _glassButton(
          icon: Icons.arrow_back_ios_new,
          onTap: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/');
            }
          },
        ),
        Row(
          children: [
            _glassButton(icon: Icons.share_outlined, onTap: _shareProduct),
            const SizedBox(width: 12),
            Consumer<NotificationProvider>(
              builder: (context, notifProvider, child) {
                return Stack(
                  children: [
                    _glassButton(
                      icon: Icons.notifications_outlined,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const NotificationsScreen(),
                        ),
                      ),
                    ),
                    if (notifProvider.unreadCount > 0)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: AppColors.red,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 18,
                            minHeight: 18,
                          ),
                          child: Text(
                            '${notifProvider.unreadCount}',
                            style: const TextStyle(
                              color: AppColors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _glassButton({required IconData icon, required VoidCallback onTap}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(50),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFDFBF7).withValues(alpha: 0.7),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.5),
                width: 1,
              ),
            ),
            child: Icon(icon, color: _dsBrown, size: 22),
          ),
        ),
      ),
    );
  }

  Widget _buildImageGallery() {
    return PageView.builder(
      controller: _pageController,
      itemCount: _product!.images.length,
      onPageChanged: (index) => setState(() => _currentImageIndex = index),
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => Scaffold(
                  backgroundColor: AppColors.black,
                  appBar: AppBar(
                    backgroundColor: AppColors.black,
                    iconTheme: const IconThemeData(color: AppColors.white),
                  ),
                  body: Center(
                    child: InteractiveViewer(
                      child: CachedNetworkImage(
                        imageUrl: _product!.images[index],
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
          child: Hero(
            tag: index == 0 ? _product!.id : '${_product!.id}_$index',
            child: CachedNetworkImage(
              imageUrl: _product!.images[index],
              fit: BoxFit.cover,
              placeholder: (context, url) =>
                  Container(color: AppColors.imagePlaceholder),
            ),
          ),
        );
      },
    );
  }

  Widget _buildThumbnails() {
    return SizedBox(
      height: 70,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _product!.images.length,
        itemBuilder: (context, index) {
          final isSelected = _currentImageIndex == index;
          return GestureDetector(
            onTap: () {
              _pageController.animateToPage(
                index,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.only(right: 12),
              width: 70,
              decoration: BoxDecoration(
                border: Border.all(
                  color: isSelected ? _dsBrown : Colors.transparent,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: CachedNetworkImage(
                  imageUrl: _product!.images[index],
                  fit: BoxFit.cover,
                  placeholder: (context, url) =>
                      Container(color: AppColors.grey200),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTitleAndPrice() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _product!.brand.toUpperCase(),
              style: const TextStyle(
                color: AppColors.gold,
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: 2.0,
              ),
            ),
            Row(
              children: [
                const Icon(Icons.star_rounded, color: AppColors.gold, size: 20),
                const SizedBox(width: 4),
                Text(
                  "4.8 (120)",
                  style: TextStyle(
                    color: _dsBrown.withValues(alpha: 0.7),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          _product!.getName(context),
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            color: _dsBrown,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 15),
        Text(
          "${_product!.price.toStringAsFixed(2)} ${AppLocalizations.of(context)!.translate('currency')}",
          style: const TextStyle(
            fontSize: 24,
            color: AppColors.primary,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }

  Widget _buildColorSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.translate('colors'),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: _dsBrown,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 45,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _product!.colors.length,
            itemBuilder: (context, index) {
              final colorItem = _product!.colors[index];
              final color = _parseColor(colorItem.hex);
              final isSelected = _selectedColorIndex == index;
              return GestureDetector(
                onTap: () => setState(() => _selectedColorIndex = index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(right: 15),
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? _dsBrown : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Container(
                    width: 35,
                    height: 35,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.black12, width: 1),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: color.withValues(alpha: 0.4),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : [],
                    ),
                    child: isSelected
                        ? Icon(
                            Icons.check,
                            color: color.computeLuminance() > 0.5
                                ? Colors.black
                                : Colors.white,
                            size: 18,
                          )
                        : null,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSizeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              AppLocalizations.of(context)!.translate('size'),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: _dsBrown,
              ),
            ),
            Text(
              '${AppLocalizations.of(context)!.translate('available')} $_availableQuantity',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: _product!.sizes.map((s) {
            final isSelected = _selectedSize == s.size;
            final isOutOfStock = s.quantity <= 0;
            return GestureDetector(
              onTap: isOutOfStock
                  ? null
                  : () {
                      setState(() {
                        _selectedSize = isSelected ? null : s.size;
                      });
                    },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? _dsBrown : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? _dsBrown
                        : (isOutOfStock ? AppColors.grey200 : AppColors.grey),
                    width: 1.5,
                  ),
                ),
                child: Text(
                  '${s.size} ${isOutOfStock ? '(${AppLocalizations.of(context)!.translate('sold_out_short')})' : ''}',
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : (isOutOfStock ? AppColors.grey : _dsBrown),
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDescription() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.translate('product_desc'),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: _dsBrown,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          _product!.getDescription(context),
          style: TextStyle(
            fontSize: 15,
            height: 1.8,
            color: _dsBrown.withValues(alpha: 0.8),
          ),
        ),
        if (_product!.dimensions.isNotEmpty) ...[
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F5F2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _dsBrown.withValues(alpha: 0.05)),
            ),
            child: Row(
              children: [
                Icon(Icons.straighten, color: _dsBrown.withValues(alpha: 0.6)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "${AppLocalizations.of(context)!.translate('dimensions')}: ${_product!.dimensions}",
                    style: TextStyle(
                      fontSize: 14,
                      color: _dsBrown,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildRelatedProducts() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.translate('you_might_like'),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: _dsBrown,
          ),
        ),
        const SizedBox(height: 15),
        SizedBox(
          height: 250,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: relatedProducts.length,
            itemBuilder: (c, i) => _buildRelatedProductCard(relatedProducts[i]),
          ),
        ),
      ],
    );
  }

  Widget _buildRelatedProductCard(Product p) {
    return GestureDetector(
      onTap: () => context.push('/product/${p.id}', extra: p),
      child: Container(
        width: 150,
        margin: const EdgeInsetsDirectional.only(end: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: Hero(
                  tag: p.id,
                  child: CachedNetworkImage(
                    imageUrl: p.images.isNotEmpty ? p.images[0] : '',
                    fit: BoxFit.cover,
                    width: double.infinity,
                    placeholder: (context, url) =>
                        Container(color: AppColors.imagePlaceholder),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.getName(context),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: _dsBrown,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${p.price} ${AppLocalizations.of(context)!.translate('currency')}",
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomActionBar() {
    final wishlistProvider = Provider.of<WishlistProvider>(context);
    final isFav =
        _product != null && wishlistProvider.isInWishlist(_product!.id);

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          decoration: BoxDecoration(
            color: const Color(0xFFFDFBF7).withValues(alpha: 0.85),
            border: Border(
              top: BorderSide(color: _dsBrown.withValues(alpha: 0.1)),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                GestureDetector(
                  onTap: () async {
                    setState(() => _isActionLoading = true);
                    bool added = await wishlistProvider.toggleWishlist(
                      _product!,
                    );
                    if (mounted) setState(() => _isActionLoading = false);
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
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: isFav
                          ? AppColors.red.withValues(alpha: 0.1)
                          : Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isFav
                            ? AppColors.red
                            : _dsBrown.withValues(alpha: 0.2),
                        width: 1.5,
                      ),
                    ),
                    child: Icon(
                      isFav ? Icons.favorite : Icons.favorite_border,
                      color: isFav ? AppColors.red : _dsBrown,
                      size: 28,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: SizedBox(
                    height: 60,
                    child: ElevatedButton(
                      onPressed: _shareProduct,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _dsBrown,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.share_rounded, size: 22),
                          const SizedBox(width: 10),
                          Flexible(
                            child: Text(
                              AppLocalizations.of(
                                context,
                              )!.translate('share_title'),
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ],
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
}

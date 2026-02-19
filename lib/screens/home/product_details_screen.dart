import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:details_app/app_imports.dart';

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
  int _quantity = 1;
  String? _selectedSize;

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
                .where((p) => p.id != _product!.id) // استثناء المنتج الحالي
                .take(5) // عرض 5 منتجات فقط
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

  @override
  Widget build(BuildContext context) {
    final wishlistProvider = Provider.of<WishlistProvider>(context);
    final isFav =
        _product != null && wishlistProvider.isInWishlist(_product!.id);

    if (_isLoadingProduct) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }
    if (_product == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: Text("Product not found")),
      );
    }
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Image.asset('assets/images/logo1.png', height: 40),
        backgroundColor: AppColors.appBarBackground,
        foregroundColor: AppColors.appBarForeground,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/');
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Stack(
              alignment: Alignment.bottomCenter,
              children: [
                SizedBox(
                  height: 400,
                  child: PageView.builder(
                    itemCount: _product!.images.length,
                    onPageChanged: (index) {
                      setState(() {
                        _currentImageIndex = index;
                      });
                    },
                    itemBuilder: (c, i) {
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => Scaffold(
                                backgroundColor: Colors.black,
                                appBar: AppBar(
                                  backgroundColor: Colors.black,
                                  iconTheme: const IconThemeData(
                                    color: Colors.white,
                                  ),
                                ),
                                body: Center(
                                  child: InteractiveViewer(
                                    child: CachedNetworkImage(
                                      imageUrl: _product!.images[i],
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                        child: Hero(
                          tag: i == 0 ? _product!.id : '${_product!.id}_$i',
                          child: CachedNetworkImage(
                            imageUrl: _product!.images[i],
                            fit: BoxFit.cover,
                            placeholder: (context, url) => const Center(
                              child: CircularProgressIndicator(),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                if (_product!.images.length > 1)
                  Positioned(
                    bottom: 20,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _product!.images.length,
                        (index) => AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: _currentImageIndex == index ? 12 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _currentImageIndex == index
                                ? AppColors.primary
                                : Colors.grey.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.white, width: 1),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.share, color: AppColors.grey),
                        onPressed: () async {
                          try {
                            // 1. تحضير النص والبيانات
                            final currency = AppLocalizations.of(
                              context,
                            )!.translate('currency');
                            final text =
                                '🌟 *Check out this amazing product!* 🌟\n\n'
                                '🛍️ *${_product!.getName(context)}*\n'
                                '💰 Price: *${_product!.price} $currency*\n\n'
                                '🔗 Link: ${AppConstants.shareBaseUrl}/product/${_product!.id}\n\n'
                                '_Sent from Details Store App_';

                            if (kIsWeb) {
                              await SharePlus.instance.share(
                                ShareParams(text: text),
                              );
                            } else {
                              // استخدام الكاش لجلب الصورة
                              final file = await DefaultCacheManager()
                                  .getSingleFile(_product!.imageUrl);

                              // 4. تنفيذ عملية المشاركة
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
                      IconButton(
                        icon: Icon(
                          isFav ? Icons.favorite : Icons.favorite_border,
                          color: isFav ? AppColors.red : AppColors.grey,
                          size: 28,
                        ),
                        onPressed: () async {
                          bool added = await wishlistProvider.toggleWishlist(
                            _product!,
                          );
                          if (!context.mounted) return;
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
                      const Spacer(),
                      Flexible(
                        child: Text(
                          _product!.brand,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _product!.getName(context),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "${_product!.price} ${AppLocalizations.of(context)!.translate('currency')}",
                    style: TextStyle(
                      fontSize: 22,
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const Icon(Icons.star, color: AppColors.gold, size: 18),
                      const SizedBox(width: 4),
                      Text(
                        "4.8 (120 ${AppLocalizations.of(context)!.translate('reviews')})",
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  Text(
                    AppLocalizations.of(context)!.translate('product_desc'),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _product!.getDescription(context),

                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.6,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 30),
                  if (_product!.dimensions.isNotEmpty) ...[
                    Text(
                      AppLocalizations.of(context)!.translate('dimensions'),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _product!.dimensions,
                      style: const TextStyle(
                        fontSize: 15,
                        color: AppColors.grey,
                      ),
                    ),
                  ],
                  if (_product!.sizes.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Text(
                      AppLocalizations.of(context)!.translate('size'),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      children: _product!.sizes.map((s) {
                        final isSelected = _selectedSize == s.size;
                        final isOutOfStock = s.quantity <= 0;
                        return ChoiceChip(
                          label: Text(
                            '${s.size} ${isOutOfStock ? '(Out)' : ''}',
                          ),
                          selected: isSelected,
                          onSelected: isOutOfStock
                              ? null
                              : (selected) {
                                  setState(() {
                                    _selectedSize = selected ? s.size : null;
                                    _quantity = 1; // Reset quantity
                                  });
                                },
                          selectedColor: AppColors.primary,
                          disabledColor: Colors.grey.shade200,
                          labelStyle: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : isOutOfStock
                                ? Colors.grey
                                : Colors.black,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                  const SizedBox(height: 20),
                  Text(
                    '${AppLocalizations.of(context)!.translate('available')} $_availableQuantity',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (relatedProducts.isNotEmpty) ...[
                    const Divider(height: 50),
                    Text(
                      AppLocalizations.of(context)!.translate('you_might_like'),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 15),
                    SizedBox(
                      height: 240,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        reverse: true, // ليتناسب مع الاتجاه العربي
                        itemCount: relatedProducts.length,
                        itemBuilder: (c, i) =>
                            _buildRelatedProductCard(relatedProducts[i]),
                      ),
                    ),
                  ],
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        height: 70,
        decoration: BoxDecoration(
          color: AppColors.homeNavBackground,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _navIcon(
              Icons.home_outlined,
              AppLocalizations.of(context)!.translate('nav_shop'),
              0,
            ),
            _navIcon(
              Icons.search,
              AppLocalizations.of(context)!.translate('nav_search'),
              1,
            ),
            _navIcon(
              Icons.shopping_bag_outlined,
              AppLocalizations.of(context)!.translate('nav_cart'),
              2,
            ),
            _navIcon(
              Icons.favorite_border,
              AppLocalizations.of(context)!.translate('nav_wishlist'),
              3,
            ),
          ],
        ),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade200),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.remove, color: AppColors.primary),
                    onPressed: () {
                      if (_quantity > 1) setState(() => _quantity--);
                    },
                  ),
                  Text(
                    '$_quantity',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.add, color: AppColors.primary),
                    onPressed: () {
                      if (_quantity < _availableQuantity) {
                        setState(() => _quantity++);
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: ElevatedButton(
                onPressed: _availableQuantity == 0
                    ? null
                    : () {
                        if (_product!.sizes.isNotEmpty &&
                            _selectedSize == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                AppLocalizations.of(
                                  context,
                                )!.translate('select_size'),
                              ),
                            ),
                          );
                          return;
                        }
                        final cart = Provider.of<CartProvider>(
                          context,
                          listen: false,
                        );
                        for (int i = 0; i < _quantity; i++) {
                          cart.addItem(
                            _product!.id,
                            _product!.price.toDouble(),
                            _product!.getName(context),
                            _product!.imageUrl,
                            size: _selectedSize,
                            maxQuantity: _availableQuantity,
                          );
                        }
                        ScaffoldMessenger.of(context).hideCurrentSnackBar();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              AppLocalizations.of(
                                context,
                              )!.translate('added_to_cart'),
                            ),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  minimumSize: const Size(double.infinity, 55),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  AppLocalizations.of(context)!.translate('add_to_cart'),
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRelatedProductCard(Product p) {
    return GestureDetector(
      onTap: () {
        context.push('/product/${p.id}', extra: p);
      },
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(left: 15),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(8),
                ),
                child: Hero(
                  tag: p.id,
                  child: CachedNetworkImage(
                    imageUrl: p.images.isNotEmpty ? p.images[0] : '',
                    placeholder: (context, url) =>
                        Container(color: Colors.grey[200]),
                    fit: BoxFit.cover,
                    width: double.infinity,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    p.getName(context),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${p.price} ${AppLocalizations.of(context)!.translate('currency')}",
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.gold,
                      fontWeight: FontWeight.bold,
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

  Widget _navIcon(IconData icon, String label, int index) {
    // نعتبر الصفحة الحالية هي المتجر (Shop)
    final isSelected = index == 0;

    return GestureDetector(
      onTap: () => _onNavTap(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: isSelected
            ? const EdgeInsets.symmetric(horizontal: 12, vertical: 8)
            : const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primary : AppColors.homeNavInactive,
              size: 24,
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _onNavTap(int index) {
    switch (index) {
      case 0:
        context.go('/');
        break;
      case 1:
        context.go('/search');
        break;
      case 2:
        context.go('/cart');
        break;
      case 3:
        context.go('/wishlist');
        break;
    }
  }
}

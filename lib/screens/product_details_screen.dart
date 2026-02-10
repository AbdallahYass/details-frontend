import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:details_app/models/product.dart';
import 'package:details_app/constants/app_colors.dart';
import 'package:details_app/l10n/app_localizations.dart';
import 'package:details_app/providers/wishlist_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:details_app/providers/cart_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

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
      body: SingleChildScrollView(
        child: Column(
          children: [
            Stack(
              alignment: Alignment.bottomCenter,
              children: [
                SizedBox(
                  height: 500,
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
              padding: const EdgeInsets.all(25),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
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
                      Text(
                        _product!.brand,
                        style: const TextStyle(
                          color: AppColors.grey,
                          fontSize: 14,
                          letterSpacing: 1.5,
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
                    ),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    "\$${_product!.price}",
                    style: const TextStyle(
                      fontSize: 22,
                      color: AppColors.gold,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(height: 50),
                  Text(
                    AppLocalizations.of(context)!.translate('product_desc'),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _product!.getDescription(context),
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.7,
                      color: AppColors.secondary,
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
      bottomSheet: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.white,
          border: Border(top: BorderSide(color: Colors.grey[100]!)),
        ),
        child: ElevatedButton(
          onPressed: () {
            Provider.of<CartProvider>(context, listen: false).addItem(
              _product!.id,
              _product!.price.toDouble(),
              _product!.getName(context),
              _product!.imageUrl,
            );
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('تمت الإضافة للسلة بنجاح'),
                duration: Duration(seconds: 1),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            minimumSize: const Size(double.infinity, 55),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5),
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
                    "\$${p.price}",
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
}

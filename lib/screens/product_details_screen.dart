import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:details_app/models/product.dart';
import 'package:details_app/constants/app_colors.dart';
import 'package:details_app/l10n/app_localizations.dart';
import 'package:details_app/widgets/language_button.dart';

class ProductDetailsScreen extends StatefulWidget {
  final Product product;
  const ProductDetailsScreen({super.key, required this.product});

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  int _currentImageIndex = 0;
  List<Product> relatedProducts = [];
  bool isLoadingRelated = true;

  @override
  void initState() {
    super.initState();
    _fetchRelatedProducts();
  }

  Future<void> _fetchRelatedProducts() async {
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
                .where(
                  (p) => p.id != widget.product.id,
                ) // استثناء المنتج الحالي
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.product.getName(context)),
        elevation: 0.5,
        actions: const [LanguageButton(), SizedBox(width: 10)],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Stack(
              alignment: Alignment.bottomCenter,
              children: [
                SizedBox(
                  height: 500,
                  child: PageView.builder(
                    itemCount: widget.product.images.length,
                    onPageChanged: (index) {
                      setState(() {
                        _currentImageIndex = index;
                      });
                    },
                    itemBuilder: (c, i) => Image.network(
                      widget.product.images[i],
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                if (widget.product.images.length > 1)
                  Positioned(
                    bottom: 20,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        widget.product.images.length,
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
                  Text(
                    widget.product.brand,
                    style: const TextStyle(
                      color: AppColors.grey,
                      fontSize: 14,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.product.getName(context),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    "\$${widget.product.price}",
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
                    widget.product.getDescription(context),
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.7,
                      color: AppColors.secondary,
                    ),
                  ),
                  const SizedBox(height: 30),
                  if (widget.product.dimensions.isNotEmpty) ...[
                    Text(
                      AppLocalizations.of(context)!.translate('dimensions'),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.product.dimensions,
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
          onPressed: () {},
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
        Navigator.push(
          context,
          MaterialPageRoute(builder: (c) => ProductDetailsScreen(product: p)),
        );
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
                child: Image.network(
                  p.images.isNotEmpty ? p.images[0] : '',
                  fit: BoxFit.cover,
                  width: double.infinity,
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

import 'package:flutter/material.dart';
import 'package:details_app/models/product.dart';
import 'package:details_app/constants/app_colors.dart';
import 'package:details_app/l10n/app_localizations.dart';

class ProductDetailsScreen extends StatelessWidget {
  final Product product;
  const ProductDetailsScreen({super.key, required this.product});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(product.name), elevation: 0.5),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(
              height: 450,
              child: PageView.builder(
                itemCount: product.images.length,
                itemBuilder: (c, i) =>
                    Image.network(product.images[i], fit: BoxFit.cover),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(25),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    product.brand,
                    style: const TextStyle(
                      color: AppColors.grey,
                      fontSize: 14,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    "\$${product.price}",
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
                    AppLocalizations.of(
                      context,
                    )!.translate(product.description),
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.7,
                      color: AppColors.secondary,
                    ),
                  ),
                  const SizedBox(height: 30),
                  if (product.dimensions.isNotEmpty) ...[
                    Text(
                      AppLocalizations.of(context)!.translate('dimensions'),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      product.dimensions,
                      style: const TextStyle(
                        fontSize: 15,
                        color: AppColors.grey,
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
}

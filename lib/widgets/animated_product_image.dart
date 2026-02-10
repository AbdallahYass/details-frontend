import 'package:flutter/material.dart';
import 'package:details_app/models/product.dart';

class AnimatedProductImage extends StatelessWidget {
  final Product product;
  const AnimatedProductImage({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Image.network(
      product.imageUrl,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (c, _, __) => const Center(child: Icon(Icons.error)),
    );
  }
}

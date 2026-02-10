import 'package:flutter/material.dart';
import 'package:details_app/models/product.dart';
import 'package:cached_network_image/cached_network_image.dart';

class AnimatedProductImage extends StatelessWidget {
  final Product product;
  const AnimatedProductImage({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: product.imageUrl,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      placeholder: (context, url) =>
          const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      errorWidget: (context, url, error) =>
          const Center(child: Icon(Icons.error)),
    );
  }
}

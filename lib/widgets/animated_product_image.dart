import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:details_app/models/product.dart';

class AnimatedProductImage extends StatefulWidget {
  final Product product;
  const AnimatedProductImage({super.key, required this.product});

  @override
  State<AnimatedProductImage> createState() => _AnimatedProductImageState();
}

class _AnimatedProductImageState extends State<AnimatedProductImage> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final hasSecondImage = widget.product.images.length > 1;
    final firstImage = widget.product.imageUrl;
    final secondImage = hasSecondImage ? widget.product.images[1] : firstImage;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isHovered = true),
        onTapUp: (_) => setState(() => _isHovered = false),
        onTapCancel: () => setState(() => _isHovered = false),
        // استخدمنا StackFit.expand عشان الصورة تملي الكرت بذكاء بدون Infinity
        child: Stack(
          fit: StackFit.expand,
          children: [
            // الصورة الأساسية
            _buildImage(firstImage),

            // الصورة الثانية تظهر فقط عند اللمس أو التمرير
            if (hasSecondImage)
              AnimatedOpacity(
                opacity: _isHovered ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOut,
                child: _buildImage(secondImage),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(String url) {
    // شلنا SizedBox(double.infinity) اللي كانت سبب الكراش
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(color: Colors.grey[200]),
      errorWidget: (context, url, error) =>
          const Icon(Icons.error, color: Colors.grey),
    );
  }
}

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

  // دالة سحرية لتسريع تحميل صور Cloudinary وتقليل حجمها بنسبة 90%
  String _optimizeImageUrl(String url) {
    // نطبق الضغط فقط إذا كانت الصورة من Cloudinary ولم يتم ضغطها مسبقاً
    if (url.contains('cloudinary.com') && !url.contains('q_auto')) {
      // إضافة أوامر الضغط: جودة تلقائية، صيغة تلقائية (WebP)، وعرض 400 بكسل (مناسب للبطاقات)
      final parts = url.split('/upload/');
      if (parts.length == 2) {
        return '${parts[0]}/upload/q_auto,f_auto,w_400/${parts[1]}';
      }
    }
    return url;
  }

  Widget _buildImage(String url) {
    final optimizedUrl = _optimizeImageUrl(url);

    return CachedNetworkImage(
      imageUrl: optimizedUrl,
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(
        color: Colors.grey[200],
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Color(0xFF9E773A),
            ),
          ),
        ),
      ),
      errorWidget: (context, url, error) =>
          const Icon(Icons.error, color: Colors.grey),
    );
  }
}

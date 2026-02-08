import 'package:flutter/material.dart';
import 'package:details_app/models/product.dart';

class AnimatedProductImage extends StatefulWidget {
  final Product product;
  const AnimatedProductImage({super.key, required this.product});
  @override
  State<AnimatedProductImage> createState() => _AnimatedProductImageState();
}

class _AnimatedProductImageState extends State<AnimatedProductImage> {
  bool _active = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.product.images.length > 1) {
      precacheImage(NetworkImage(widget.product.images[1]), context);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.product.images.isEmpty) {
      return const Center(child: Icon(Icons.broken_image));
    }
    String currentImg = (_active && widget.product.images.length > 1)
        ? widget.product.images[1]
        : widget.product.images[0];
    return MouseRegion(
      onEnter: (_) => setState(() => _active = true),
      onExit: (_) => setState(() => _active = false),
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: (_) => setState(() => _active = true),
        onPointerUp: (_) => setState(() => _active = false),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          reverseDuration: const Duration(milliseconds: 500),
          transitionBuilder: (child, anim) => FadeTransition(
            opacity: anim,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.96, end: 1.0).animate(anim),
              child: child,
            ),
          ),
          child: Image.network(
            currentImg,
            key: ValueKey(currentImg),
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (c, e, s) => const Icon(Icons.broken_image),
          ),
        ),
      ),
    );
  }
}

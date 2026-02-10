import 'package:flutter/material.dart';
import 'package:visibility_detector/visibility_detector.dart';

class RevealOnScroll extends StatefulWidget {
  final Widget child;
  const RevealOnScroll({super.key, required this.child});

  @override
  State<RevealOnScroll> createState() => _RevealOnScrollState();
}

class _RevealOnScrollState extends State<RevealOnScroll>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isVisible = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: const Key('reveal-on-scroll'),
      onVisibilityChanged: (info) {
        if (info.visibleFraction > 0.1 && !_isVisible) {
          _isVisible = true;
          _controller.forward();
        }
      },
      child: FadeTransition(
        opacity: _animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.2),
            end: Offset.zero,
          ).animate(_animation),
          child: widget.child,
        ),
      ),
    );
  }
}

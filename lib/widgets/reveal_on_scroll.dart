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
  late AnimationController _c;
  late Animation<double> _f;
  late Animation<Offset> _s;
  bool _revealed = false;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _f = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _c, curve: Curves.easeOut));
    _s = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _c, curve: Curves.easeOutQuart));
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: Key('reveal-${widget.child.hashCode}'),
      onVisibilityChanged: (info) {
        if (info.visibleFraction > 0.1 && !_revealed) {
          _c.forward();
          _revealed = true;
        }
      },
      child: FadeTransition(
        opacity: _f,
        child: SlideTransition(position: _s, child: widget.child),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:details_app/models/banner_model.dart';

class AnimatedBannerItem extends StatefulWidget {
  final BannerModel banner;
  const AnimatedBannerItem({super.key, required this.banner});
  @override
  State<AnimatedBannerItem> createState() => _AnimatedBannerItemState();
}

class _AnimatedBannerItemState extends State<AnimatedBannerItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _sc, _f;
  late Animation<Offset> _sl;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _sc = Tween<double>(
      begin: 1.15,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _c, curve: Curves.easeOut));
    _f = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _c,
        curve: const Interval(0.4, 1.0, curve: Curves.easeIn),
      ),
    );
    _sl = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _c,
        curve: const Interval(0.4, 1.0, curve: Curves.easeOutQuart),
      ),
    );
    _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ScaleTransition(
          scale: _sc,
          child: Image.network(widget.banner.imageUrl, fit: BoxFit.cover),
        ),
        Container(color: Colors.black.withValues(alpha: 0.25)),
        FadeTransition(
          opacity: _f,
          child: SlideTransition(
            position: _sl,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  widget.banner.getTitle(context),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Container(width: 50, height: 2, color: Colors.white),
                const SizedBox(height: 25),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white, width: 1.5),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(
                    widget.banner.getButtonText(context),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

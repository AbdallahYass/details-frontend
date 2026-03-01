import 'package:flutter/material.dart';
import 'package:details_app/constants/app_colors.dart';
import 'package:details_app/l10n/app_localizations.dart';

class CustomLoadingOverlay extends StatefulWidget {
  final bool
  isOverlay; // لتحديد ما إذا كانت خلفية شفافة (Overlay) أو شاشة كاملة
  const CustomLoadingOverlay({super.key, this.isOverlay = true});

  @override
  State<CustomLoadingOverlay> createState() => _CustomLoadingOverlayState();
}

class _CustomLoadingOverlayState extends State<CustomLoadingOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _fadeAnimation = Tween<double>(
      begin: 0.6,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _scaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.05,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: widget.isOverlay
          ? AppColors.black.withValues(alpha: 0.8)
          : AppColors.white,
      child: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Opacity(
              opacity: _fadeAnimation.value,
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      AppLocalizations.of(context)?.translate('app_name') ??
                          'Details Store',
                      style: TextStyle(
                        color: widget.isOverlay
                            ? AppColors.white
                            : AppColors.black,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        fontFamily: 'Tajawal',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppLocalizations.of(context)?.translate('app_slogan') ??
                          'Live in style',
                      style: TextStyle(
                        color:
                            (widget.isOverlay
                                    ? AppColors.white
                                    : AppColors.black)
                                .withValues(alpha: 0.9),
                        fontSize: 14,
                        fontWeight: FontWeight.w300,
                        letterSpacing: 4.0,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

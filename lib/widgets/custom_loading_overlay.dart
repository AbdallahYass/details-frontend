import 'package:flutter/material.dart';
import 'package:details_app/constants/app_colors.dart';

class CustomLoadingOverlay extends StatelessWidget {
  final bool
  isOverlay; // لتحديد ما إذا كانت خلفية شفافة (Overlay) أو شاشة كاملة
  const CustomLoadingOverlay({super.key, this.isOverlay = true});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: isOverlay
          ? AppColors.black.withValues(alpha: 0.4)
          : AppColors.white,
      alignment: Alignment.center,
      child: const CircularProgressIndicator(color: AppColors.primary),
    );
  }
}

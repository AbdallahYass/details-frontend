import 'package:flutter/material.dart';

class AppColors {
  // الألوان الأساسية
  static const Color primary = Color(0xFF452512); // بني داكن
  static const Color secondary = Color(0xFFD4AF37); // ذهبي
  static const Color accent = Color(0xFF9E773A); // ذهبي داكن
  static const Color goldBorder = Color(0xFFB89560);
  static const Color background = Color(0xFFFDFBF7); // خلفية التطبيق
  static const Color lightBackground = Color(0xFFF8F5F2);

  // الألوان العامة
  static const Color white = Colors.white;
  static const Color black = Colors.black;
  static const Color black87 = Colors.black87;
  static const Color transparent = Colors.transparent;

  // ألوان الحالات
  static const Color success = Colors.green;
  static const Color error = Colors.red;
  static const Color red = Colors.red;
  static const Color warning = Colors.orange;

  // الرمادي والنصوص
  static const Color grey = Colors.grey;
  static final Color grey200 = Colors.grey.shade200;
  static final Color grey500 = Colors.grey.shade500;
  static const Color textPrimary = Color(0xFF333333);
  static const Color textSecondary = Color(0xFF666666);
  static const Color lightGrey = Color(0xFFE0E0E0);
  static const Color imagePlaceholder = Color(0xFFEEEEEE);

  // عناصر محددة
  static const Color homeNavBackground = white;
  static const Color homeNavInactive = grey;
  static const Color appBarBackground = transparent;
  static const Color appBarForeground = primary;
  static const Color shadowColor = Color(0x1A000000);
  static const Color arrowInactive = Color(0xFFBDBDBD);
  static const Color gold = secondary;

  // ألوان لوحة التحكم (Admin)
  static const Color adminBackground = Color(0xFFF4F6F8);
  static const Color adminDashProducts = Color(0xFF2196F3);
  static const Color adminDashOrders = Color(0xFFFF9800);
  static const Color adminDashCoupons = Color(0xFF4CAF50);
  static const Color adminDashBanners = Color(0xFF9C27B0);
  static const Color adminDashCategories = Color(0xFFE91E63);
  static const Color adminDashUsers = Color(0xFF00BCD4);
  static const Color adminEdit = Color(0xFF2196F3);
  static const Color adminDelete = Color(0xFFF44336);

  // ألوان تمت إضافتها للتوافق مع باقي الشاشات
  static const Color cardBackground = white;
  static const Color adminSurface = white;
  static const Color adminAdd = primary;
  static const Color aboutLogoFallback = primary;
  static const Color aboutTitle = primary;
  static const Color aboutTextSecondary = textSecondary;
  static const Color aboutTextPrimary = textPrimary;
  static const Color homeBackground = background;
  static final Color grey300 = Colors.grey.shade300;
  static final Color grey700 = Colors.grey.shade700;
  static const Color blue = Colors.blue;
  static const Color homeCategoryIcon = primary;
  static const Color homeEmptyStateIcon = grey;
  static const Color homeEmptyStateText = textSecondary;
  static const Color homeButtonPrimary = primary;
  static const Color homeButtonText = white;
  static const Color homeCardBackground = white;
  static const Color homeProductPrice = primary;
  static const Color homeWishlistIcon = red;
}

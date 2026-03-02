import 'package:flutter/material.dart';

class AppColors {
  // --- Base Palette (الألوان الأساسية) ---
  static const Color primary = Color(
    0xFF1A1A1A,
  ); // أسود ملكي فاخر (Luxury Black)
  static const Color secondary = Color(0xFFD4AF37); // ذهبي (Gold Accent)
  static const Color background = Color(
    0xFFFAFAFA,
  ); // أبيض ثلجي ناعم (Snow White)
  static const Color white = Colors.white;
  static const Color black = Color(0xFF000000);
  static const Color grey = Color(0xFF9E9E9E); // رمادي محايد
  static const Color lightGrey = Color(0xFFF5F5F5); // رمادي فاتح جداً
  static const Color transparent = Colors.transparent;
  static const Color success = Color(0xFF2E7D32); // أخضر غامق
  static const Color error = Color(0xFFD32F2F);
  static const Color warning = Color(0xFFFFA000);
  static const Color whatsapp = Color(0xFF25D366);
  static const Color amber = Color(0xFFFFC107);

  // --- Neutral Colors (ألوان محايدة إضافية) ---
  static const Color grey200 = Color(0xFFEEEEEE);
  static const Color grey300 = Color(0xFFE0E0E0);
  static const Color grey500 = Colors.grey;
  static const Color grey700 = Color(0xFF616161);
  static const Color black87 = Colors.black87;
  static const Color blue = Color(0xFF1565C0);

  // --- Text Colors (ألوان النصوص) ---
  static const Color textPrimary = Color(0xFF1A1A1A); // أسود ناعم
  static const Color textSecondary = Color(0xFF757575); // رمادي متوسط

  // --- Common Mappings (تعيينات عامة) ---
  static const Color red = error;
  static const Color gold = Color(0xFFD4AF37); // ذهبي
  static const Color darkBlue = Color(0xFF0D47A1);
  static const Color orange = Color(0xFFFF6F00);
  static const Color cardBackground = white; // الكروت بيضاء دائماً أنظف
  static const Color circleBackground = Color(0xFFF5F5F5);

  // --- AppBar ---
  static const Color appBarBackground = background; // لدمج الهيدر مع الخلفية
  static const Color appBarForeground = primary; // الأيقونات باللون البني

  // --- Home Screen (ألوان الصفحة الرئيسية) ---
  static const Color homeBackground = background;
  static const Color starColor = gold;
  static const Color shadowColor = Color(0x0D000000); // ظل أسود خفيف جداً
  static const Color cardBorder = Color(0xFFEEEEEE);
  static const Color arrowInactive = Color(0xFFBDBDBD);
  static const Color imagePlaceholder = Color(0xFFF5F5F5);
  static const Color footerDivider = Color(0xFF424242);
  static const Color footerText = Color(0xFFFAFAFA);
  static const Color footerTextSecondary = Color(0xFFBDBDBD);
  static const Color inputBorder = Color(0xFFE0E0E0);
  static const Color subscribeBg = primary;
  static const Color hintText = Color(0xFF9E9E9E);
  static const Color homeSectionTitle = primary;
  static const Color homeSectionSubtitle = textSecondary;
  static const Color homeProductPrice = secondary; // السعر باللون الذهبي
  static const Color homeFavActive = error;
  static const Color homeFavInactive = Color(0xFFBDBDBD);
  static const Color homeBadgeSoldOut = Color(0xFF212121);
  static const Color homeBadgeHot = error;
  static const Color homeBadgeText = white;
  static const Color homeCategoryText = textPrimary;
  static const Color homeCategoryIcon = primary;
  static const Color homeFooterBackground = Color(0xFF121212); // فوتر أسود
  static const Color homeNavActive = primary;
  static const Color homeNavInactive = Color(0xFF9E9E9E);
  static const Color homeNavBackground = white;
  static const Color homeSectionBorder = Color(0xFFEEEEEE);
  static const Color homeArrowActive = primary;
  static const Color homePageNumber = textSecondary;
  static const Color homeIconBg = white;
  static const Color homeIconShadow = Color(0x1A000000);
  static const Color homeDotActive = primary;
  static const Color homeDotInactive = Color(0xFFE0E0E0);
  static const Color homeProductIcon = primary;
  static const Color homeDrawerHeader = background;
  static const Color homeDrawerAvatarBg = primary;
  static const Color homeDrawerAvatarText = white;
  static const Color homeDrawerIcon = primary;
  static const Color homeDrawerLogout = red;
  static const Color homeEmptyStateIcon = Color(0xFFE0E0E0);
  static const Color homeEmptyStateText = grey;
  static const Color homeButtonPrimary = primary;
  static const Color homeButtonText = white;
  static const Color homeCardBackground = white;
  static const Color homeOrderPrice = secondary;
  static const Color homeOrderStatusDelivered = success;
  static const Color homeOrderStatusPending = warning;
  static const Color homeOrderExpandIcon = primary;
  static const Color homeWishlistIcon = red;

  // --- About Screen (ألوان صفحة من نحن) ---
  static const Color aboutLogoBackground = background;
  static const Color aboutTextPrimary = textPrimary;
  static const Color aboutTextSecondary = textSecondary;
  static const Color aboutTitle = primary;
  static const Color aboutLogoFallback = primary;

  // --- Admin Panel (لوحة التحكم) ---
  static const Color adminBackground = Color(0xFFF5F7FA);
  static const Color adminSurface = white;
  static const Color adminEdit = Color(0xFF1976D2);
  static const Color adminDelete = error;
  static const Color adminAdd = primary;
  static const Color adminDashProducts = Color(0xFF0288D1);
  static const Color adminDashOrders = warning;
  static const Color adminDashCoupons = success;
  static const Color adminDashBanners = secondary;
  static const Color adminDashCategories = Color(0xFF0097A7);
  static const Color adminDashUsers = error;
}

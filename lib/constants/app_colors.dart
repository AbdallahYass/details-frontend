import 'package:flutter/material.dart';

class AppColors {
  // --- Base Palette (الألوان الأساسية) ---
  static const Color primary = Color(0xFF800020); // خمري بارد
  static const Color secondary = Color(0xFFD4AF37); // ذهبي (يتناسق مع الخمري)
  static const Color background = Color(
    0xFFFAFAFA,
  ); // أوف وايت (أنظف وأفخم مع الخمري)
  static const Color white = Colors.white;
  static const Color black = Color(0xFF2D3436); // أسود ناعم
  static const Color grey = Color(0xFF636E72); // رمادي متوسط
  static const Color lightGrey = Color(0xFFDFE6E9); // رمادي فاتح للفواصل
  static const Color transparent = Colors.transparent;
  static const Color success = Color(0xFF00B894); // أخضر نعناعي
  static const Color error = Color(0xFFD63031); // أحمر هادئ
  static const Color warning = Color(0xFFFDCB6E); // أصفر خردلي
  static const Color whatsapp = Color(0xFF25D366);
  static const Color amber = Color(0xFFFFC107);

  // --- Text Colors (ألوان النصوص) ---
  static const Color textPrimary = Color(0xFF2D3436); // للنصوص الأساسية
  static const Color textSecondary = Color(0xFF636E72); // للنصوص الفرعية

  // --- Common Mappings (تعيينات عامة) ---
  static const Color red = error;
  static const Color gold = secondary;
  static const Color darkBlue = primary;
  static const Color orange = secondary;
  static const Color cardBackground = white; // الكروت بيضاء دائماً أنظف
  static const Color circleBackground = lightGrey;

  // --- AppBar ---
  static const Color appBarBackground = primary;
  static const Color appBarForeground = white;

  // --- Home Screen (ألوان الصفحة الرئيسية) ---
  static const Color homeBackground = white;
  static const Color starColor = amber;
  static const Color shadowColor = Color(0x14000000); // ظل خفيف جداً
  static const Color cardBorder = Color(0xFFF1F2F6);
  static const Color arrowInactive = Color(0xFFCED6E0);
  static const Color imagePlaceholder = Color(0xFFF1F2F6);
  static const Color footerDivider = Colors.white12;
  static const Color footerText = Color(0xFFDFE6E9); // نص فاتح للخلفية الغامقة
  static const Color footerTextSecondary = Color(0xFFB2BEC3);
  static const Color inputBorder = Colors.white30;
  static const Color subscribeBg = Colors.white12;
  static const Color hintText = Colors.white38;
  static const Color homeSectionTitle = primary;
  static const Color homeSectionSubtitle = textSecondary;
  static const Color homeProductPrice =
      secondary; // السعر باللون البرتقالي للفت الانتباه
  static const Color homeFavActive = error;
  static const Color homeFavInactive = Color(0xFFB2BEC3);
  static const Color homeBadgeSoldOut = Color(
    0xFF2D3436,
  ); // "نفذت الكمية" بالأسود أفخم
  static const Color homeBadgeHot = warning;
  static const Color homeBadgeText = white;
  static const Color homeCategoryText = textPrimary;
  static const Color homeCategoryIcon = grey;
  static const Color homeFooterBackground = primary; // خلفية الفوتر
  static const Color homeNavActive = primary;
  static const Color homeNavInactive = Color(0xFFB2BEC3);
  static const Color homeNavBackground = white;
  static const Color homeSectionBorder = Color(0xFFF1F2F6);
  static const Color homeArrowActive = primary;
  static const Color homePageNumber = textSecondary;
  static const Color homeIconBg = Color(0xFFF1F2F6);
  static const Color homeIconShadow = Color(0x14000000);
  static const Color homeDotActive = white;
  static const Color homeDotInactive = Colors.white54;
  static const Color homeProductIcon = Color(
    0xFF2D3436,
  ); // أيقونة غامقة لتظهر على الصور الفاتحة
  static const Color homeDrawerHeader = primary;
  static const Color homeDrawerAvatarBg = white;
  static const Color homeDrawerAvatarText = primary;
  static const Color homeDrawerIcon = textSecondary;
  static const Color homeDrawerLogout = red;
  static const Color homeEmptyStateIcon = Color(0xFFDFE6E9);
  static const Color homeEmptyStateText = grey;
  static const Color homeButtonPrimary = primary;
  static const Color homeButtonText = white;
  static const Color homeCardBackground = white;
  static const Color homeOrderPrice = secondary;
  static const Color homeOrderStatusDelivered = success;
  static const Color homeOrderStatusPending = warning;
  static const Color homeOrderExpandIcon = grey;
  static const Color homeWishlistIcon = red;

  // --- About Screen (ألوان صفحة من نحن) ---
  static const Color aboutLogoBackground = Color(0xFFF1F2F6);
  static const Color aboutTextPrimary = textPrimary;
  static const Color aboutTextSecondary = textSecondary;
  static const Color aboutTitle = primary;
  static const Color aboutLogoFallback = primary;

  // --- Admin Panel (لوحة التحكم) ---
  static const Color adminBackground = background;
  static const Color adminSurface = white;
  static const Color adminEdit = Color(0xFF0984E3); // أزرق إلكتروني
  static const Color adminDelete = error;
  static const Color adminAdd = black;
  static const Color adminDashProducts = primary;
  static const Color adminDashOrders = warning;
  static const Color adminDashCoupons = success;
  static const Color adminDashBanners = secondary;
  static const Color adminDashCategories = Color(0xFF00CEC9); // تركواز
  static const Color adminDashUsers = error;
}

import 'package:flutter/material.dart';

class AppColors {
  // الألوان الأساسية (Modern Luxury Palette)
  static const Color primary = Color.fromARGB(255, 18, 17, 34); // بنفسجي حيوي
  static const Color secondary = Color(0xFF00D2D3); // تركواز
  static const Color background = Color(0xFFF8F9FA); // رمادي فاتح جداً للخلفيات
  static const Color cardBackground = Colors.white; // أبيض ناصع للكروت

  // ألوان النصوص
  static const Color textPrimary = Color(0xFF1E293B); // رمادي غامق للعناوين
  static const Color textSecondary = Color(0xFF64748B); // رمادي متوسط للشرح

  // ألوان وظيفية
  static const Color success = Color(0xFF10B981); // أخضر زمردي
  static const Color error = Color(0xFFEF4444); // أحمر هادئ
  static const Color warning = Color(0xFFF59E0B); // برتقالي
  static const Color white = Colors.white;
  static const Color black = Colors.black;
  static const Color grey = Color(0xFF94A3B8);
  static const Color lightGrey = Color(0xFFF1F5F9);

  // توافق مع الكود القديم (Mappings)
  static const Color red = error;
  static const Color gold = secondary;
  static const Color darkBlue = primary;
  static const Color orange = secondary;
  static const Color circleBackground = Color(0xFFE2E8F0);
}

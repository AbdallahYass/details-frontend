import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:details_app/constants/app_colors.dart';

class AppTheme {
  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: AppColors.primary,
    scaffoldBackgroundColor: AppColors.background,
    fontFamily: GoogleFonts.cairo().fontFamily,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      elevation: 0,
      iconTheme: IconThemeData(color: AppColors.primary),
      titleTextStyle: TextStyle(
        color: AppColors.primary,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
    colorScheme: const ColorScheme.light(
      primary: AppColors.primary,
      secondary: AppColors.secondary,
    ),
  );
}

import 'package:flutter/material.dart';
import 'package:details_app/constants/app_colors.dart';
import 'package:details_app/main.dart';

class LanguageButton extends StatelessWidget {
  const LanguageButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.language, color: AppColors.primary),
      onPressed: () {
        Locale currentLocale = Localizations.localeOf(context);
        Locale newLocale = currentLocale.languageCode == 'ar'
            ? const Locale('en', '')
            : const Locale('ar', '');
        DetailsStoreApp.setLocale(context, newLocale);
      },
    );
  }
}
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:details_app/constants/app_colors.dart';
import 'package:details_app/providers/settings_provider.dart';

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
        Provider.of<SettingsProvider>(
          context,
          listen: false,
        ).setLocale(newLocale);
      },
    );
  }
}

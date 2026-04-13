import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider with ChangeNotifier {
  late Locale _appLocale;

  Locale get appLocale => _appLocale;

  // استقبال اللغة المحفوظة كمتغير عند التهيئة
  LanguageProvider(String initialLanguage)
    : _appLocale = Locale(initialLanguage, '');

  // تغيير اللغة وحفظها في الذاكرة
  Future<void> changeLanguage(Locale newLocale) async {
    if (_appLocale.languageCode == newLocale.languageCode) return;

    _appLocale = Locale(newLocale.languageCode, '');
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', newLocale.languageCode);
  }
}

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider with ChangeNotifier {
  Locale _appLocale = const Locale('ar'); // اللغة الافتراضية

  Locale get appLocale => _appLocale;

  LanguageProvider() {
    _loadSavedLanguage();
  }

  // قراءة اللغة من الذاكرة عند تشغيل التطبيق
  Future<void> _loadSavedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLanguage = prefs.getString('language_code');

    if (savedLanguage != null) {
      _appLocale = Locale(savedLanguage);
      notifyListeners();
    }
  }

  // تغيير اللغة وحفظها في الذاكرة
  Future<void> changeLanguage(Locale newLocale) async {
    if (_appLocale == newLocale) return;

    _appLocale = newLocale;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', newLocale.languageCode);
  }
}

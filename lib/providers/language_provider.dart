import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider with ChangeNotifier {
  late Locale _appLocale;

  Locale get appLocale => _appLocale;

  // استقبال اللغة المحفوظة كمتغير عند التهيئة
  LanguageProvider(String initialLanguage)
    : _appLocale = Locale(initialLanguage, '');

  // دالة ذكية جداً تقبل النص ('en') أو الكائن (Locale('en')) لضمان عملها بأي شكل برمجته في الفوتر
  Future<void> changeLanguage(dynamic newLang) async {
    String langCode = 'ar';
    if (newLang is String) {
      langCode = newLang;
    } else if (newLang is Locale) {
      langCode = newLang.languageCode;
    }

    if (_appLocale.languageCode == langCode) return;

    _appLocale = Locale(langCode, '');
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', langCode);
  }
}

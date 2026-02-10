import 'package:flutter/material.dart';

class SettingsProvider with ChangeNotifier {
  Locale _locale = const Locale('ar');

  Locale get locale => _locale;

  void setLocale(Locale locale) {
    if (!['ar', 'en'].contains(locale.languageCode)) return;
    _locale = locale;
    notifyListeners();
  }
}

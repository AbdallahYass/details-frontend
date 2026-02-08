import 'package:flutter/material.dart';

class BannerModel {
  final String imageUrl;
  final Map<String, dynamic> title, buttonText;
  BannerModel({
    required this.title,
    required this.imageUrl,
    required this.buttonText,
  });
  factory BannerModel.fromJson(Map<String, dynamic> json) => BannerModel(
    title: json['title'] is Map
        ? json['title']
        : {'en': json['title'] ?? '', 'ar': json['title'] ?? ''},
    imageUrl: json['imageUrl'] ?? '',
    buttonText: json['buttonText'] is Map
        ? json['buttonText']
        : {'en': json['buttonText'] ?? '', 'ar': json['buttonText'] ?? ''},
  );
  String getTitle(BuildContext context) {
    String lang = Localizations.localeOf(context).languageCode;
    return title[lang] ?? title['en'] ?? title['ar'] ?? '';
  }

  String getButtonText(BuildContext context) {
    String lang = Localizations.localeOf(context).languageCode;
    return buttonText[lang] ?? buttonText['en'] ?? buttonText['ar'] ?? '';
  }
}

import 'package:flutter/material.dart';

class CategoryModel {
  final String id, slug, imageUrl;
  final Map<String, dynamic> name;

  CategoryModel({
    required this.id,
    required this.name,
    required this.slug,
    required this.imageUrl,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) => CategoryModel(
    id: json['_id'] ?? '',
    name: json['name'] is Map
        ? json['name']
        : {'en': json['name'] ?? '', 'ar': json['name'] ?? ''},
    slug: json['slug'] ?? '',
    imageUrl: json['imageUrl'] ?? '',
  );

  String getName(BuildContext context) {
    String lang = Localizations.localeOf(context).languageCode;
    return name[lang] ?? name['en'] ?? name['ar'] ?? '';
  }
}

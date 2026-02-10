import 'package:flutter/material.dart';

class CategoryModel {
  final String id;
  final Map<String, dynamic> name;
  final String slug;
  final String imageUrl;

  CategoryModel({
    required this.id,
    required this.name,
    required this.slug,
    required this.imageUrl,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? {},
      slug: json['slug'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
    );
  }

  String getName(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    return name[locale] ?? name['en'] ?? '';
  }
}

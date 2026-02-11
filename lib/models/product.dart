import 'package:flutter/material.dart';

class Product {
  final String id;
  final Map<String, dynamic> name;
  final Map<String, dynamic> description;
  final double price;
  final String imageUrl;
  final List<String> images;
  final String brand;
  final String dimensions;
  final bool isSoldOut;
  final dynamic category; // يمكن أن يكون String ID أو Map
  final int popularity;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.images,
    required this.brand,
    required this.dimensions,
    required this.isSoldOut,
    required this.category,
    this.popularity = 0,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] is Map
          ? Map<String, dynamic>.from(json['name'])
          : {'en': json['name']?.toString() ?? ''},
      description: json['description'] is Map
          ? Map<String, dynamic>.from(json['description'])
          : {'en': json['description']?.toString() ?? ''},
      price: (json['price'] ?? 0).toDouble(),
      imageUrl: json['imageUrl'] ?? '',
      images: List<String>.from(json['images'] ?? []),
      brand: json['brand'] ?? '',
      dimensions: json['dimensions'] ?? '',
      isSoldOut: json['isSoldOut'] ?? false,
      category: json['category'],
      popularity: (json['popularity'] ?? 0).toInt(),
    );
  }

  String getName(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    return name[locale] ?? name['en'] ?? '';
  }

  String getDescription(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    return description[locale] ?? description['en'] ?? '';
  }

  // دالة مساعدة للحصول على معرف الكاتيجوري سواء كان كائن أو نص
  String get categoryId {
    if (category is Map) {
      return category['_id'] ?? category['id'] ?? '';
    } else if (category is String) {
      return category;
    }
    return '';
  }
}

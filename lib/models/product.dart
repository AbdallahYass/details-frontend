import 'package:flutter/material.dart';

class Product {
  final String id, brand, dimensions;
  final Map<String, dynamic> name, description;
  final List<String> images;
  final double price;
  final double? oldPrice;
  final bool isSoldOut;

  Product({
    required this.id,
    required this.name,
    required this.brand,
    required this.description,
    required this.dimensions,
    required this.images,
    required this.price,
    this.oldPrice,
    this.isSoldOut = false,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['_id'] ?? '',
      name: json['name'] is Map
          ? json['name']
          : {'en': json['name'] ?? '', 'ar': json['name'] ?? ''},
      brand: json['brand'] ?? 'DETAILS',
      description: json['description'] is Map
          ? json['description']
          : {'en': json['description'] ?? '', 'ar': json['description'] ?? ''},
      dimensions: json['dimensions'] ?? '',
      images: List<String>.from(json['images'] ?? [json['imageUrl'] ?? '']),
      price: (json['price'] as num).toDouble(),
      oldPrice: json['oldPrice'] != null
          ? (json['oldPrice'] as num).toDouble()
          : null,
      isSoldOut: json['isSoldOut'] ?? false,
    );
  }

  String getName(BuildContext context) {
    String lang = Localizations.localeOf(context).languageCode;
    return name[lang] ?? name['en'] ?? name['ar'] ?? '';
  }

  String getDescription(BuildContext context) {
    String lang = Localizations.localeOf(context).languageCode;
    return description[lang] ?? description['en'] ?? description['ar'] ?? '';
  }
}

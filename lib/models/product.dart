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
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? {},
      description: json['description'] ?? {},
      price: (json['price'] ?? 0).toDouble(),
      imageUrl: json['imageUrl'] ?? '',
      images: List<String>.from(json['images'] ?? []),
      brand: json['brand'] ?? '',
      dimensions: json['dimensions'] ?? '',
      isSoldOut: json['isSoldOut'] ?? false,
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
}

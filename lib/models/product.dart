import 'package:flutter/material.dart';

class ProductSize {
  final String size;
  final int quantity;

  ProductSize({required this.size, required this.quantity});

  factory ProductSize.fromJson(dynamic json) {
    if (json is String) {
      return ProductSize(size: json, quantity: 0);
    }
    return ProductSize(
      size: json['size']?.toString() ?? '',
      quantity: int.tryParse(json['quantity']?.toString() ?? '0') ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {'size': size, 'quantity': quantity};
}

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
  final int quantity;
  final List<ProductSize> sizes;

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
    this.quantity = 0,
    this.sizes = const [],
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name'] is Map
          ? Map<String, dynamic>.from(json['name'])
          : {'en': json['name']?.toString() ?? ''},
      description: json['description'] is Map
          ? Map<String, dynamic>.from(json['description'])
          : {'en': json['description']?.toString() ?? ''},
      price: (json['price'] is num)
          ? (json['price'] as num).toDouble()
          : double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
      imageUrl: json['imageUrl']?.toString() ?? '',
      images: (json['images'] is List)
          ? (json['images'] as List).map((e) => e.toString()).toList()
          : [],
      brand: json['brand']?.toString() ?? '',
      dimensions: json['dimensions']?.toString() ?? '',
      isSoldOut: json['isSoldOut'] == true,
      category: json['category'],
      popularity: (json['popularity'] is num)
          ? (json['popularity'] as num).toInt()
          : int.tryParse(json['popularity']?.toString() ?? '0') ?? 0,
      quantity: (json['quantity'] is num)
          ? (json['quantity'] as num).toInt()
          : int.tryParse(json['quantity']?.toString() ?? '0') ?? 0,
      sizes: (json['sizes'] is List)
          ? (json['sizes'] as List).map((e) => ProductSize.fromJson(e)).toList()
          : [],
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

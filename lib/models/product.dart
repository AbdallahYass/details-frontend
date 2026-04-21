import '../app_imports.dart';

class ProductColor {
  final String hex;
  final List<String> images;

  ProductColor({required this.hex, this.images = const []});

  factory ProductColor.fromJson(dynamic json) {
    if (json == null) return ProductColor(hex: '');
    if (json is String) {
      return ProductColor(hex: json);
    }

    List<String> parsedImages = [];
    // دعم المنتجات القديمة التي كانت تمتلك صورة واحدة
    if (json['imageUrl'] != null && json['imageUrl'].toString().isNotEmpty) {
      parsedImages.add(json['imageUrl'].toString());
    }
    // جلب قائمة الصور الجديدة
    if (json['images'] is List) {
      parsedImages.addAll((json['images'] as List).map((e) => e.toString()));
    }

    return ProductColor(
      hex: json['hex']?.toString() ?? '',
      images: parsedImages.toSet().toList(), // toSet لمنع تكرار الروابط
    );
  }

  Map<String, dynamic> toJson() => {
    'hex': hex,
    if (images.isNotEmpty) 'images': images,
  };
}

// 🌟 الكلاس الجديد لاستقبال مخزون المتغيرات (الكمية لكل لون ومقاس)
class ProductVariantModel {
  final String? colorHex;
  final String? size;
  final int quantity;

  ProductVariantModel({this.colorHex, this.size, this.quantity = 0});

  factory ProductVariantModel.fromJson(dynamic json) {
    if (json == null) return ProductVariantModel();
    return ProductVariantModel(
      colorHex: json['colorHex']?.toString(),
      size: json['size']?.toString(),
      quantity: int.tryParse(json['quantity']?.toString() ?? '0') ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    if (colorHex != null) 'colorHex': colorHex,
    if (size != null) 'size': size,
    'quantity': quantity,
  };
}

class Product {
  final String id;
  final Map<String, dynamic> name;
  final Map<String, dynamic> description;
  final double price;
  final double? oldPrice;
  final String imageUrl;
  final List<String> images;
  final String brand;
  final String dimensions;
  final bool isSoldOut;
  final dynamic category; // يمكن أن يكون String ID أو Map
  final int popularity;
  final int quantity;
  final List<String> sizes;
  final List<ProductColor> colors;
  final List<ProductVariantModel>
  variants; // 🌟 إضافة المتغيرات للموديل الرئيسي

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.oldPrice,
    required this.imageUrl,
    required this.images,
    required this.brand,
    required this.dimensions,
    required this.isSoldOut,
    required this.category,
    this.popularity = 0,
    this.quantity = 0,
    this.sizes = const [],
    this.colors = const [],
    this.variants = const [],
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
      oldPrice: json['oldPrice'] != null
          ? double.tryParse(json['oldPrice'].toString())
          : null,
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
      sizes:
          (json['sizes'] is List) // Backend sends List<String>
          ? List<String>.from(json['sizes'].map((e) => e.toString()))
          : [],
      colors: (json['colors'] is List)
          ? (json['colors'] as List)
                .map((e) => ProductColor.fromJson(e))
                .toList()
          : [],
      variants: (json['variants'] is List)
          ? (json['variants'] as List)
                .map((e) => ProductVariantModel.fromJson(e))
                .toList()
          : [],
    );
  }

  // الدالة الجديدة لتحويل المنتج إلى نص وحفظه في الجهاز
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'description': description,
      'price': price,
      'oldPrice': oldPrice,
      'imageUrl': imageUrl,
      'images': images,
      'brand': brand,
      'dimensions': dimensions,
      'isSoldOut': isSoldOut,
      'category': category,
      'popularity': popularity,
      'quantity': quantity,
      'sizes': sizes,
      'colors': colors.map((c) => c.toJson()).toList(),
      'variants': variants
          .map((v) => v.toJson())
          .toList(), // 🌟 إرسالها عند التعديل
    };
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

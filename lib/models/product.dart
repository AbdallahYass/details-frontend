class Product {
  final String id, name, brand, description, dimensions;
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
      name: json['name'] ?? '',
      brand: json['brand'] ?? 'DETAILS',
      description: json['description'] ?? 'no_desc',
      dimensions: json['dimensions'] ?? '',
      images: List<String>.from(json['images'] ?? [json['imageUrl'] ?? '']),
      price: (json['price'] as num).toDouble(),
      oldPrice: json['oldPrice'] != null
          ? (json['oldPrice'] as num).toDouble()
          : null,
      isSoldOut: json['isSoldOut'] ?? false,
    );
  }
}

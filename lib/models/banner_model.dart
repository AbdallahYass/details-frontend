class BannerModel {
  final String id;
  final String imageUrl;
  final Map<String, dynamic> title;
  final String? link;
  final String? category;

  BannerModel({
    required this.id,
    required this.imageUrl,
    required this.title,
    this.link,
    this.category,
  });

  factory BannerModel.fromJson(Map<String, dynamic> json) {
    String? catId;
    if (json['category'] is Map) {
      catId = json['category']['_id'] ?? json['category']['id'];
    } else if (json['category'] is String) {
      catId = json['category'];
    }

    return BannerModel(
      id: json['_id'] ?? json['id'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      title: json['title'] ?? {},
      link: json['link'],
      category: catId,
    );
  }
}

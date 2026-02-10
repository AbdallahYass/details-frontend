class BannerModel {
  final String id;
  final String imageUrl;
  final Map<String, dynamic> title;
  final String? link;

  BannerModel({
    required this.id,
    required this.imageUrl,
    required this.title,
    this.link,
  });

  factory BannerModel.fromJson(Map<String, dynamic> json) {
    return BannerModel(
      id: json['_id'] ?? json['id'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      title: json['title'] ?? {},
      link: json['link'],
    );
  }
}

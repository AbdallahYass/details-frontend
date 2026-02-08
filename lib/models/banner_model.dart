class BannerModel {
  final String title, imageUrl, buttonText;
  BannerModel({
    required this.title,
    required this.imageUrl,
    required this.buttonText,
  });
  factory BannerModel.fromJson(Map<String, dynamic> json) => BannerModel(
    title: json['title'] ?? '',
    imageUrl: json['imageUrl'] ?? '',
    buttonText: json['buttonText'] ?? 'discover_details',
  );
}

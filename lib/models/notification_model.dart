class NotificationModel {
  final String id;
  final String title;
  final String body;
  final String type; // system, order, promo
  final DateTime createdAt;
  bool isRead;

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.createdAt,
    this.isRead = false,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['_id'] ?? '',
      title: json['title'] ?? '',
      // الباك اند يرسل 'message' بدلاً من 'body'
      body: json['message'] ?? '',
      type: json['type'] ?? 'system',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      isRead: json['isRead'] ?? false,
    );
  }
}

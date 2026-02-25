import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:details_app/models/notification_model.dart';
import 'package:details_app/providers/auth_provider.dart';

class NotificationProvider with ChangeNotifier {
  List<NotificationModel> _notifications = [];
  bool _isLoading = false;

  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  Future<void> fetchNotifications(
    BuildContext context, {
    AuthProvider? authProvider,
  }) async {
    final auth = authProvider;
    if (auth == null || !auth.isAuthenticated) return;

    _isLoading = true;
    // notifyListeners();

    try {
      final url = Uri.parse('https://api.details-store.com/api/notifications');
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${auth.token}',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _notifications = data
            .map((json) => NotificationModel.fromJson(json))
            .toList();
        _notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      }
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markAsRead(String id, AuthProvider auth) async {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1 && !_notifications[index].isRead) {
      _notifications[index].isRead = true;
      notifyListeners();

      try {
        final url = Uri.parse(
          'https://api.details-store.com/api/notifications/$id/read',
        );
        await http.put(url, headers: {'Authorization': 'Bearer ${auth.token}'});
      } catch (e) {
        debugPrint('Error marking notification as read: $e');
      }
    }
  }

  Future<void> deleteNotification(String id, AuthProvider auth) async {
    // حذف محلي فقط (Local Dismiss) لأن الباك اند لا يوفر رابط حذف للإشعارات
    _notifications.removeWhere((n) => n.id == id);
    notifyListeners();
  }

  void clear() {
    _notifications = [];
    notifyListeners();
  }
}

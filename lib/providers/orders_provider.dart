import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:details_app/models/order_model.dart';
import 'package:details_app/providers/cart_provider.dart';

class OrdersProvider with ChangeNotifier {
  List<OrderModel> _orders = [];
  String? _token;
  VoidCallback? _onLogout; // لحفظ دالة تسجيل الخروج

  List<OrderModel> get orders => [..._orders];

  void updateToken(String? token, {VoidCallback? onLogout}) {
    _token = token;
    _onLogout = onLogout;
  }

  Future<void> fetchOrders() async {
    if (_token == null) return;
    try {
      final response = await http.get(
        Uri.parse('https://api.details-store.com/api/orders'),
        headers: {'Authorization': 'Bearer $_token'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _orders = data.map<OrderModel>((item) {
          return OrderModel(
            id: item['_id'],
            amount: (item['totalAmount'] as num).toDouble(), // تصحيح الاسم
            products: (item['products'] as List).map((p) {
              return CartItem(
                id: p['id'] ?? '',
                productId: p['productId'] ?? p['id'] ?? '',
                title: p['title'] ?? '',
                quantity: p['quantity'] ?? 1,
                price: (p['price'] as num).toDouble(),
                imageUrl: p['imageUrl'] ?? '',
                size: p['size'],
                color: p['color'],
                withBox: p['withBox'] ?? false,
              );
            }).toList(),
            dateTime: DateTime.parse(item['createdAt']),
            status: item['status'],
          );
        }).toList();
        notifyListeners();
      } else if (response.statusCode == 401) {
        _onLogout?.call(); // طرد المستخدم فوراً
      }
    } catch (e) {
      debugPrint('Error fetching orders: $e');
    }
  }

  Future<bool> addOrder(Map<String, dynamic> orderPayload) async {
    if (_token == null) return false;
    try {
      final url = Uri.parse('https://api.details-store.com/api/orders');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
        body: json.encode(orderPayload),
      );

      if (response.statusCode == 201) {
        await fetchOrders();
        return true;
      } else if (response.statusCode == 401) {
        _onLogout?.call(); // طرد المستخدم فوراً
        return false;
      }
      return false;
    } catch (e) {
      debugPrint('Error adding order: $e');
      return false;
    }
  }

  // دالة لتحديث حالة الطلب (مثل الإلغاء من قبل المستخدم)
  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    if (_token == null) return;
    try {
      final url = Uri.parse(
        'https://api.details-store.com/api/orders/$orderId/status',
      );
      final response = await http.patch(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
        body: json.encode({'status': newStatus}),
      );

      if (response.statusCode == 200) {
        // إعادة جلب الطلبات لتحديث القائمة في الواجهة فوراً
        await fetchOrders();
      } else if (response.statusCode == 401) {
        _onLogout?.call();
      } else {
        throw Exception('Failed to update status');
      }
    } catch (e) {
      debugPrint('Error updating order status: $e');
      rethrow; // نمرر الخطأ ليتم معالجته وإظهاره في شاشة الطلبات
    }
  }
}

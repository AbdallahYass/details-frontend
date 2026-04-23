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
    final bool isNewToken = _token != token;
    _token = token;
    _onLogout = onLogout;

    if (token != null) {
      if (isNewToken) fetchOrders();
    } else {
      _orders = []; // مسح القائمة عند تسجيل الخروج
      notifyListeners();
    }
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
        final List<OrderModel> loadedOrders = [];

        for (var item in data) {
          try {
            // 🌟 معالجة مرنة للحقول: فحص totalAmount و amount لتجنب الخطأ
            final double orderAmount =
                (item['totalAmount'] as num?)?.toDouble() ??
                (item['amount'] as num?)?.toDouble() ??
                0.0;

            final List<dynamic> productsData = item['products'] as List? ?? [];

            loadedOrders.add(
              OrderModel(
                id: item['_id']?.toString() ?? '',
                amount: orderAmount,
                products: productsData.map((p) {
                  return CartItem(
                    id: p['id']?.toString() ?? '',
                    productId:
                        p['productId']?.toString() ?? p['id']?.toString() ?? '',
                    title: p['title'] ?? '',
                    quantity: (p['quantity'] as num?)?.toInt() ?? 1,
                    price: (p['price'] as num?)?.toDouble() ?? 0.0,
                    imageUrl: p['imageUrl'] ?? '',
                    size: p['size'],
                    color: p['color'],
                    withBox: p['withBox'] ?? false,
                  );
                }).toList(),
                dateTime: item['createdAt'] != null
                    ? DateTime.parse(item['createdAt'])
                    : DateTime.now(),
                status: item['status']?.toString() ?? '',
              ),
            );
          } catch (e) {
            debugPrint('Error parsing individual order item: $e');
          }
        }

        _orders = loadedOrders;
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

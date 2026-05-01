import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:details_app/models/order_model.dart';
import 'package:details_app/providers/cart_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OrdersProvider with ChangeNotifier {
  List<OrderModel> _orders = [];
  String? _token;
  bool _isAdmin = false;
  VoidCallback? _onLogout; // لحفظ دالة تسجيل الخروج
  List<String> _guestOrderIds = [];

  List<OrderModel> get orders => [..._orders];

  OrdersProvider() {
    _loadGuestOrderIds();
  }

  // تحميل أرقام طلبات الزوار من ذاكرة الهاتف
  Future<void> _loadGuestOrderIds() async {
    final prefs = await SharedPreferences.getInstance();
    _guestOrderIds = prefs.getStringList('guest_order_ids') ?? [];
  }

  // حفظ رقم طلب جديد للزائر في الذاكرة
  Future<void> _saveGuestOrderId(String id) async {
    _guestOrderIds.add(id);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('guest_order_ids', _guestOrderIds);
  }

  void updateToken(
    String? token, {
    bool isAdmin = false,
    VoidCallback? onLogout,
  }) {
    final bool isNewToken = _token != token || _isAdmin != isAdmin;
    _token = token;
    _isAdmin = isAdmin;
    _onLogout = onLogout;

    if (token != null) {
      if (isNewToken) fetchOrders();
    } else {
      fetchOrders(); // محاولة جلب طلبات الزوار إذا كان مسجل خروج
    }
  }

  Future<void> fetchOrders() async {
    // إذا لم يكن مسجلاً وليس لديه طلبات زوار، لا نفعل شيئاً
    if (_token == null && _guestOrderIds.isEmpty) {
      _orders = [];
      notifyListeners();
      return;
    }

    try {
      // تحديد الرابط: إذا كان زائر نرسل أرقام الطلبات في الـ Query
      final url = _token != null
          ? (_isAdmin
                ? Uri.parse('https://api.details-store.com/api/admin/orders')
                : Uri.parse('https://api.details-store.com/api/orders'))
          : Uri.parse(
              'https://api.details-store.com/api/orders/guest?ids=${_guestOrderIds.join(',')}',
            );

      final response = await http.get(
        url,
        headers: _token != null ? {'Authorization': 'Bearer $_token'} : {},
      );

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);

        // Defensive check: Ensure the response is actually a List
        if (decoded is! List) {
          debugPrint('Expected List from API but got: ${decoded.runtimeType}');
          _orders = [];
          notifyListeners();
          return;
        }

        final List<dynamic> data = decoded;
        final List<OrderModel> loadedOrders = [];

        for (var item in data) {
          if (item is! Map<String, dynamic>) continue;
          try {
            // 🌟 جلب مبلغ الطلب النهائي (المجموع بعد الخصم)
            final double orderAmount =
                (item['amount'] as num?)?.toDouble() ?? 0.0;
            final List<dynamic> productsData =
                (item['products'] as List?) ?? [];

            loadedOrders.add(
              OrderModel(
                id: item['_id']?.toString() ?? '',
                amount: orderAmount,
                products: productsData
                    .map((p) {
                      if (p is! Map<String, dynamic>) return null;
                      return CartItem(
                        id: p['id']?.toString() ?? '',
                        productId:
                            p['productId']?.toString() ??
                            p['id']?.toString() ??
                            '',
                        title: p['title'] ?? '',
                        quantity: (p['quantity'] as num?)?.toInt() ?? 1,
                        price: (p['price'] as num?)?.toDouble() ?? 0.0,
                        imageUrl: p['imageUrl'] ?? '',
                        size: p['size'],
                        color: p['color'],
                        withBox: p['withBox'] ?? false,
                      );
                    })
                    .whereType<CartItem>()
                    .toList(),
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
    try {
      final url = Uri.parse('https://api.details-store.com/api/orders');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (_token != null) 'Authorization': 'Bearer $_token',
        },
        body: json.encode(orderPayload),
      );

      if (response.statusCode == 201) {
        final responseData = json.decode(response.body);

        // إذا كان الطلب كزائر، نحفظ المعرف في الذاكرة المحلية
        if (_token == null && responseData['_id'] != null) {
          await _saveGuestOrderId(responseData['_id']);
        }

        await fetchOrders(); // تحديث القائمة فوراً
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
    if (_token == null && !_guestOrderIds.contains(orderId)) return;
    try {
      final url = _isAdmin
          ? Uri.parse(
              'https://api.details-store.com/api/admin/orders/$orderId/status',
            )
          : Uri.parse(
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

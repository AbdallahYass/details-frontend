import 'package:flutter/material.dart';
import 'package:details_app/models/order_model.dart';
import 'package:details_app/providers/cart_provider.dart';

class OrdersProvider with ChangeNotifier {
  List<OrderModel> _orders = [];

  // يمكن إضافة التوكن هنا لربطه بالـ API لاحقاً
  // String? _token;

  List<OrderModel> get orders => [..._orders];

  Future<void> fetchOrders() async {
    // محاكاة الاتصال بالسيرفر
    await Future.delayed(const Duration(seconds: 1));

    // بيانات تجريبية
    if (_orders.isEmpty) {
      _orders = [
        OrderModel(
          id: 'ORD-2024-001',
          amount: 599.99,
          products: [
            CartItem(
              id: 'p1',
              title: 'ساعة كلاسيكية فاخرة',
              quantity: 1,
              price: 599.99,
              imageUrl: 'https://placehold.co/600x400',
            ),
          ],
          dateTime: DateTime.now().subtract(const Duration(days: 2)),
          status: 'تم الشحن',
        ),
        OrderModel(
          id: 'ORD-2024-002',
          amount: 120.00,
          products: [
            CartItem(
              id: 'p2',
              title: 'سوار جلدي',
              quantity: 2,
              price: 60.00,
              imageUrl: 'https://placehold.co/600x400',
            ),
          ],
          dateTime: DateTime.now().subtract(const Duration(days: 5)),
          status: 'تم التوصيل',
        ),
      ];
      notifyListeners();
    }
  }
}

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:details_app/models/order_model.dart';
import 'package:details_app/providers/cart_provider.dart';

class OrdersProvider with ChangeNotifier {
  List<OrderModel> _orders = [];
  String? _token;

  List<OrderModel> get orders => [..._orders];

  void updateToken(String? token) {
    _token = token;
  }

  Future<void> fetchOrders() async {
    if (_token == null) return;
    try {
      final response = await http.get(
        Uri.parse('https://api.details-store.com/orders'),
        headers: {'Authorization': 'Bearer $_token'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _orders = data.map((item) {
          return OrderModel(
            id: item['_id'],
            amount: (item['amount'] as num).toDouble(),
            products: (item['products'] as List).map((p) {
              return CartItem(
                id: p['id'] ?? '',
                title: p['title'] ?? '',
                quantity: p['quantity'] ?? 1,
                price: (p['price'] as num).toDouble(),
                imageUrl: p['imageUrl'] ?? '',
              );
            }).toList(),
            dateTime: DateTime.parse(item['createdAt']),
            status: item['status'],
          );
        }).toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching orders: $e');
    }
  }

  Future<bool> addOrder(
    List<CartItem> cartProducts,
    double total,
    Map<String, String> address,
  ) async {
    if (_token == null) return false;
    try {
      final url = Uri.parse('https://api.details-store.com/orders');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
        body: json.encode({
          'products': cartProducts
              .map(
                (cp) => {
                  'id': cp.id,
                  'title': cp.title,
                  'quantity': cp.quantity,
                  'price': cp.price,
                  'imageUrl': cp.imageUrl,
                },
              )
              .toList(),
          'amount': total,
          'shippingAddress': address,
        }),
      );

      if (response.statusCode == 201) {
        await fetchOrders();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error adding order: $e');
      return false;
    }
  }
}

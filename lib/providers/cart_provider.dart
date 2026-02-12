import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class CartItem {
  final String id;
  final String title;
  final int quantity;
  final double price;
  final String imageUrl;

  CartItem({
    required this.id,
    required this.title,
    required this.quantity,
    required this.price,
    required this.imageUrl,
  });
}

class CartProvider with ChangeNotifier {
  Map<String, CartItem> _items = {};
  String? _couponCode;
  double _discountAmount = 0.0;

  Map<String, CartItem> get items => {..._items};

  int get itemCount => _items.length;

  double get subtotal {
    var total = 0.0;
    _items.forEach((key, cartItem) {
      total += cartItem.price * cartItem.quantity;
    });
    return total;
  }

  double get discountAmount => _discountAmount;
  String? get couponCode => _couponCode;

  double get totalAmount =>
      subtotal - _discountAmount > 0 ? subtotal - _discountAmount : 0.0;

  void addItem(String productId, double price, String title, String imageUrl) {
    if (_items.containsKey(productId)) {
      // زيادة الكمية إذا المنتج موجود
      _items.update(
        productId,
        (existingCartItem) => CartItem(
          id: existingCartItem.id,
          title: existingCartItem.title,
          quantity: existingCartItem.quantity + 1,
          price: existingCartItem.price,
          imageUrl: existingCartItem.imageUrl,
        ),
      );
    } else {
      // إضافة منتج جديد
      _items.putIfAbsent(
        productId,
        () => CartItem(
          id: productId,
          title: title,
          quantity: 1,
          price: price,
          imageUrl: imageUrl,
        ),
      );
    }
    notifyListeners();
  }

  void removeSingleItem(String productId) {
    if (!_items.containsKey(productId)) {
      return;
    }
    if (_items[productId]!.quantity > 1) {
      _items.update(
        productId,
        (existingCartItem) => CartItem(
          id: existingCartItem.id,
          title: existingCartItem.title,
          quantity: existingCartItem.quantity - 1,
          price: existingCartItem.price,
          imageUrl: existingCartItem.imageUrl,
        ),
      );
    } else {
      _items.remove(productId);
    }
    if (_items.isEmpty) {
      _couponCode = null;
      _discountAmount = 0.0;
    }
    notifyListeners();
  }

  void removeItem(String productId) {
    _items.remove(productId);
    if (_items.isEmpty) {
      _couponCode = null;
      _discountAmount = 0.0;
    }
    notifyListeners();
  }

  void clear() {
    _items = {};
    _couponCode = null;
    _discountAmount = 0.0;
    notifyListeners();
  }

  Future<bool> applyCoupon(String code) async {
    try {
      final url = Uri.parse(
        'https://api.details-store.com/api/coupons/validate',
      );
      final response = await http.post(
        url,
        body: json.encode({'code': code}),
        headers: {'Content-Type': 'application/json'},
      );

      final data = json.decode(response.body);
      if (response.statusCode == 200 && data['valid'] == true) {
        _couponCode = data['code'];
        final value = (data['value'] as num).toDouble();
        final type = data['discountType'];

        if (type == 'percentage') {
          _discountAmount = subtotal * (value / 100);
        } else {
          _discountAmount = value;
        }
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}

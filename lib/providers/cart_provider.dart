import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class CartItem {
  final String id;
  final String productId; // ID المنتج الأصلي
  final String title;
  final int quantity;
  final double price;
  final String imageUrl;
  final String? size; // المقاس المختار

  CartItem({
    required this.id,
    String? productId,
    required this.title,
    required this.quantity,
    required this.price,
    required this.imageUrl,
    this.size,
  }) : productId = productId ?? id;
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

  // دالة الإضافة المعدلة
  void addItem(
    String productId,
    double price,
    String title,
    String imageUrl, {
    String? size,
    int maxQuantity = 999,
  }) {
    // المفتاح في السلة يكون دمجاً بين الآيدي والمقاس لتمييز المنتجات المختلفة بالمقاس
    final cartKey = size != null ? '${productId}_$size' : productId;

    if (_items.containsKey(cartKey)) {
      // التحقق من عدم تجاوز الكمية المتوفرة
      if (_items[cartKey]!.quantity >= maxQuantity) {
        return; // لا تقم بالإضافة إذا وصلنا للحد الأقصى
      }

      // زيادة الكمية إذا المنتج موجود
      _items.update(
        cartKey,
        (existingCartItem) => CartItem(
          id: existingCartItem.id,
          productId: existingCartItem.productId,
          title: existingCartItem.title,
          quantity: existingCartItem.quantity + 1,
          price: existingCartItem.price,
          imageUrl: existingCartItem.imageUrl,
          size: existingCartItem.size,
        ),
      );
    } else {
      if (maxQuantity < 1) return; // لا يمكن إضافة منتج كميته 0

      // إضافة منتج جديد
      _items.putIfAbsent(
        cartKey,
        () => CartItem(
          id: cartKey,
          productId: productId,
          title: title,
          quantity: 1,
          price: price,
          imageUrl: imageUrl,
          size: size,
        ),
      );
    }
    notifyListeners();
  }

  void removeSingleItem(String cartKey) {
    if (!_items.containsKey(cartKey)) {
      return;
    }
    if (_items[cartKey]!.quantity > 1) {
      _items.update(
        cartKey,
        (existingCartItem) => CartItem(
          id: existingCartItem.id,
          productId: existingCartItem.productId,
          title: existingCartItem.title,
          quantity: existingCartItem.quantity - 1,
          price: existingCartItem.price,
          imageUrl: existingCartItem.imageUrl,
          size: existingCartItem.size,
        ),
      );
    } else {
      _items.remove(cartKey);
    }
    if (_items.isEmpty) {
      _couponCode = null;
      _discountAmount = 0.0;
    }
    notifyListeners();
  }

  void removeItem(String cartKey) {
    _items.remove(cartKey);
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

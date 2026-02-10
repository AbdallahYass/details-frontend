import 'package:flutter/material.dart';

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

  Map<String, CartItem> get items => {..._items};

  int get itemCount => _items.length;

  double get totalAmount {
    var total = 0.0;
    _items.forEach((key, cartItem) {
      total += cartItem.price * cartItem.quantity;
    });
    return total;
  }

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
    notifyListeners();
  }

  void removeItem(String productId) {
    _items.remove(productId);
    notifyListeners();
  }

  void clear() {
    _items = {};
    notifyListeners();
  }
}

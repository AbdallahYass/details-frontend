import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:details_app/models/product.dart';

class WishlistProvider with ChangeNotifier {
  List<Product> _wishlist = [];
  // مؤقتاً نستخدم ID ثابت، في تطبيق حقيقي يجب أن يأتي من نظام المصادقة
  final String _userId = "guest_user_123";

  List<Product> get wishlist => _wishlist;

  bool isInWishlist(String productId) {
    return _wishlist.any((p) => p.id == productId);
  }

  Future<void> fetchWishlist() async {
    try {
      final res = await http.get(
        Uri.parse('https://api.details-store.com/api/wishlist/$_userId'),
      );
      if (res.statusCode == 200) {
        final List<dynamic> data = json.decode(res.body);
        _wishlist = data.map((j) => Product.fromJson(j)).toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error fetching wishlist: $e");
    }
  }

  Future<bool> toggleWishlist(Product product) async {
    // تحديث الواجهة فوراً (Optimistic UI Update)
    bool exists = isInWishlist(product.id);
    if (exists) {
      _wishlist.removeWhere((p) => p.id == product.id);
    } else {
      _wishlist.add(product);
    }
    notifyListeners();

    try {
      final res = await http.post(
        Uri.parse('https://api.details-store.com/api/wishlist'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'userId': _userId, 'productId': product.id}),
      );

      if (res.statusCode != 200) {
        // إذا فشل الطلب، نعيد الحالة كما كانت
        await fetchWishlist();
      }
    } catch (e) {
      debugPrint("Error toggling wishlist: $e");
    }
    return !exists;
  }
}

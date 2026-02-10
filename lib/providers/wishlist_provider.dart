import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:details_app/models/product.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class WishlistProvider with ChangeNotifier {
  List<Product> _wishlist = [];
  String? _token;

  List<Product> get wishlist => _wishlist;

  void updateToken(String? token) {
    if (_token == token) return;
    _token = token;
    if (_token != null) {
      fetchWishlist();
    } else {
      _wishlist = [];
      notifyListeners();
    }
  }

  bool isInWishlist(String productId) {
    return _wishlist.any((p) => p.id == productId);
  }

  Future<void> fetchWishlist() async {
    if (_token == null) return;
    try {
      final res = await http.get(
        Uri.parse('${dotenv.env['API_URL']}/wishlist'),
        headers: {'Authorization': 'Bearer $_token'},
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
    if (_token == null) return false;

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
        Uri.parse('${dotenv.env['API_URL']}/wishlist'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
        body: json.encode({'productId': product.id}),
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

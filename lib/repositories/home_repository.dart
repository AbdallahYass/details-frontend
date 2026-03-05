import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:details_app/models/product.dart';
import 'package:details_app/models/banner_model.dart';
import 'package:details_app/models/category_model.dart';
import 'package:details_app/services/cache_service.dart';

// --- Top-Level Functions for Compute ---
List<Product> _parseProducts(String responseBody) {
  final parsed = json.decode(responseBody) as List;
  return parsed.map((json) => Product.fromJson(json)).toList();
}

List<BannerModel> _parseBanners(String responseBody) {
  final parsed = json.decode(responseBody) as List;
  return parsed.map((json) => BannerModel.fromJson(json)).toList();
}

List<CategoryModel> _parseCategories(String responseBody) {
  final parsed = json.decode(responseBody) as List;
  return parsed.map((json) => CategoryModel.fromJson(json)).toList();
}

class HomeRepository {
  Future<List<dynamic>> loadHomeData({bool forceRefresh = false}) async {
    return Future.wait([
      fetchProducts(forceRefresh: forceRefresh),
      fetchBanners(forceRefresh: forceRefresh),
      fetchCategories(forceRefresh: forceRefresh),
      fetchPopularProducts(forceRefresh: forceRefresh),
    ]);
  }

  Future<List<Product>> fetchProducts({
    String? category,
    bool forceRefresh = false,
  }) async {
    String url = 'https://api.details-store.com/api/products';
    if (category != null) {
      url += '?category=$category';
    }

    if (!forceRefresh) {
      // جلب النص الخام من الكاش لتقليل الضغط
      final cachedString = CacheService().get<String>(url);
      if (cachedString != null) {
        return compute(_parseProducts, cachedString);
      }
    }

    final res = await http
        .get(Uri.parse(url))
        .timeout(const Duration(seconds: 15));
    if (res.statusCode == 200) {
      // تخزين النص الخام مباشرة (سريع جداً ولا يسبب تعليق)
      CacheService().set(url, res.body);
      final data = await compute(_parseProducts, res.body);
      return data;
    }
    throw Exception('Failed to load products');
  }

  Future<List<BannerModel>> fetchBanners({
    String location = 'home',
    String? category,
    bool forceRefresh = false,
  }) async {
    String url = 'https://api.details-store.com/api/banners?location=$location';
    if (category != null) {
      url += '&category=$category';
    }

    if (!forceRefresh) {
      final cachedString = CacheService().get<String>(url);
      if (cachedString != null) {
        return compute(_parseBanners, cachedString);
      }
    }

    final res = await http
        .get(Uri.parse(url))
        .timeout(const Duration(seconds: 15));
    if (res.statusCode == 200) {
      CacheService().set(url, res.body);
      final data = await compute(_parseBanners, res.body);
      return data;
    }
    throw Exception('Failed to load banners');
  }

  Future<List<CategoryModel>> fetchCategories({
    bool forceRefresh = false,
  }) async {
    const url = 'https://api.details-store.com/api/categories';
    if (!forceRefresh) {
      final cachedString = CacheService().get<String>(url);
      if (cachedString != null) {
        // استخدام compute للتصنيفات أيضاً لضمان عدم تجميد الواجهة نهائياً
        return compute(_parseCategories, cachedString);
      }
    }

    final res = await http
        .get(Uri.parse(url))
        .timeout(const Duration(seconds: 15));
    if (res.statusCode == 200) {
      CacheService().set(url, res.body);
      // استخدام compute هنا أيضاً
      return compute(_parseCategories, res.body);
    }
    throw Exception('Failed to load categories');
  }

  Future<List<Product>> fetchPopularProducts({
    bool forceRefresh = false,
  }) async {
    const url = 'https://api.details-store.com/api/popular-products';
    if (!forceRefresh) {
      final cachedString = CacheService().get<String>(url);
      if (cachedString != null) {
        return compute(_parseProducts, cachedString);
      }
    }

    final res = await http
        .get(Uri.parse(url))
        .timeout(const Duration(seconds: 15));
    if (res.statusCode == 200) {
      CacheService().set(url, res.body);
      final data = await compute(_parseProducts, res.body);
      return data;
    }
    throw Exception('Failed to load popular products');
  }
}

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:details_app/models/product.dart';
import 'package:details_app/models/banner_model.dart';
import 'package:details_app/models/category_model.dart';
import 'package:details_app/services/cache_service.dart';

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
      final cached = CacheService().get<List<Product>>(url);
      if (cached != null) return cached;
    }

    final res = await http
        .get(Uri.parse(url))
        .timeout(const Duration(seconds: 15));
    if (res.statusCode == 200) {
      final data = (json.decode(res.body) as List)
          .map((j) => Product.fromJson(j))
          .toList();
      CacheService().set(url, data);
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
      final cached = CacheService().get<List<BannerModel>>(url);
      if (cached != null) return cached;
    }

    final res = await http
        .get(Uri.parse(url))
        .timeout(const Duration(seconds: 15));
    if (res.statusCode == 200) {
      final data = (json.decode(res.body) as List)
          .map((j) => BannerModel.fromJson(j))
          .toList();
      CacheService().set(url, data);
      return data;
    }
    throw Exception('Failed to load banners');
  }

  Future<List<CategoryModel>> fetchCategories({
    bool forceRefresh = false,
  }) async {
    const url = 'https://api.details-store.com/api/categories';
    if (!forceRefresh) {
      final cached = CacheService().get<List<CategoryModel>>(url);
      if (cached != null) return cached;
    }

    final res = await http
        .get(Uri.parse(url))
        .timeout(const Duration(seconds: 15));
    if (res.statusCode == 200) {
      final data = (json.decode(res.body) as List)
          .map((j) => CategoryModel.fromJson(j))
          .toList();
      CacheService().set(url, data);
      return data;
    }
    throw Exception('Failed to load categories');
  }

  Future<List<Product>> fetchPopularProducts({
    bool forceRefresh = false,
  }) async {
    const url = 'https://api.details-store.com/api/popular-products';
    if (!forceRefresh) {
      final cached = CacheService().get<List<Product>>(url);
      if (cached != null) return cached;
    }

    final res = await http
        .get(Uri.parse(url))
        .timeout(const Duration(seconds: 15));
    if (res.statusCode == 200) {
      final data = (json.decode(res.body) as List)
          .map((j) => Product.fromJson(j))
          .toList();
      CacheService().set(url, data);
      return data;
    }
    throw Exception('Failed to load popular products');
  }
}

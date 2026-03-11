import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:details_app/app_imports.dart'; // تأكد من مسار الـ Product model

class SearchService {
  static const String baseUrl = 'https://api.details-store.com/api';

  // نظام كاش ذكي لتخزين نتائج البحث السابقة لمنع تكرار طلب الـ API
  static final Map<String, Map<String, dynamic>> _searchCache = {};

  /// جلب المنتجات مع دعم الـ Pagination والـ Caching
  static Future<Map<String, dynamic>> searchProducts({
    required String query,
    required int page,
    required String sortOption,
  }) async {
    // إنشاء مفتاح فريد للكاش بناءً على البحث والصفحة والترتيب
    final cacheKey = '${query.trim().toLowerCase()}_${page}_$sortOption';

    // إذا كان البحث موجوداً في الكاش مسبقاً، نرجعه فوراً بـ 0 ثانية!
    if (_searchCache.containsKey(cacheKey)) {
      debugPrint('🟢 جلب النتائج من الـ Cache: $cacheKey');
      return _searchCache[cacheKey]!;
    }

    final uri = Uri.parse(
      '$baseUrl/products?search=${Uri.encodeComponent(query)}&page=$page&limit=10&sort=$sortOption',
    );

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final body = json.decode(response.body);

      List<Product> products = [];
      bool hasMore = false;

      // التعامل مع الرد الجديد من السيرفر { data: [...], hasMore: bool }
      if (body is Map && body.containsKey('data')) {
        final List data = body['data'];
        products = data.map((e) => Product.fromJson(e)).toList();
        hasMore = body['hasMore'] ?? false;
      } else if (body is List) {
        // دعم احتياطي للرد القديم
        products = body.map((e) => Product.fromJson(e)).toList();
        hasMore = products.length == 10;
      }

      final result = {'products': products, 'hasMore': hasMore};

      // حفظ النتيجة في الكاش للزيارات القادمة
      _searchCache[cacheKey] = result;
      return result;
    } else {
      throw Exception('فشل في جلب المنتجات');
    }
  }

  /// جلب الاقتراحات السريعة الخفيفة
  static Future<List<String>> fetchSuggestions(
    String query,
    String langCode,
  ) async {
    final uri = Uri.parse(
      '$baseUrl/search-suggestions?q=${Uri.encodeComponent(query)}',
    );
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      // استخراج الاسم حسب لغة التطبيق الحالية
      return data
          .map((item) {
            final name = item['name'];
            if (name == null) return '';
            return (name[langCode] ?? name['en'] ?? '').toString();
          })
          .where((s) => s.isNotEmpty)
          .toSet()
          .toList();
    }
    return [];
  }

  /// جلب الكلمات التريند (الشائعة)
  static Future<List<String>> fetchTrendingTags() async {
    final uri = Uri.parse('$baseUrl/trending-searches');
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((e) => e.toString()).toList();
    }
    throw Exception('فشل في جلب الكلمات الشائعة');
  }

  /// تنظيف الكاش (يمكن استدعاؤه عند عمل Pull to refresh مثلاً)
  static void clearCache() {
    _searchCache.clear();
  }
}

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:details_app/app_imports.dart'; // تأكد من مسار الـ Product model

/// نموذج أمان البيانات (Type Safety) لنتائج البحث
class SearchResult {
  final List<Product> products;
  final bool hasMore;

  SearchResult({required this.products, required this.hasMore});
}

/// نموذج عنصر الكاش مع وقت الحفظ (لإدارة الـ TTL)
class CacheItem {
  final SearchResult data;
  final DateTime timestamp;

  CacheItem(this.data) : timestamp = DateTime.now();
}

class SearchService {
  static const String baseUrl = 'https://api.details-store.com/api';

  // 1. نظام كاش ذكي مع تحديد الحجم للحماية من استنزاف الذاكرة (Memory Leak)
  static final Map<String, CacheItem> _searchCache = {};
  static const int _maxCacheSize = 50; // الحد الأقصى لعدد عمليات البحث المحفوظة
  static const Duration _cacheTTL = Duration(
    minutes: 5,
  ); // صلاحية الكاش 5 دقائق

  /// جلب المنتجات مع دعم الـ Pagination، الـ Caching الذكي، والـ Timeout
  static Future<SearchResult> searchProducts({
    required String query,
    required int page,
    required String sortOption,
  }) async {
    // 2. منع الاستعلامات الفارغة وحماية السيرفر
    if (query.trim().isEmpty) {
      return SearchResult(products: [], hasMore: false);
    }

    final cacheKey = '${query.trim().toLowerCase()}_${page}_$sortOption';

    // 3. التحقق من الكاش والـ TTL (صلاحية البيانات)
    if (_searchCache.containsKey(cacheKey)) {
      final item = _searchCache[cacheKey]!;
      if (DateTime.now().difference(item.timestamp) < _cacheTTL) {
        debugPrint('🟢 جلب النتائج من الـ Cache (0ms): $cacheKey');
        return item.data;
      } else {
        debugPrint('🟡 الكاش انتهت صلاحيته (Stale Data)، جلب من السيرفر...');
        _searchCache.remove(cacheKey);
      }
    }

    // 4. بناء الرابط بطريقة آمنة جداً (Uri.replace)
    final uri = Uri.parse('$baseUrl/products').replace(
      queryParameters: {
        'search': query.trim(),
        'page': page.toString(),
        'limit': '10',
        'sort': sortOption,
      },
    );

    // 5. إضافة Timeout للحماية من الشبكات البطيئة جداً
    final response = await http
        .get(uri)
        .timeout(
          const Duration(seconds: 10),
          onTimeout: () => throw TimeoutException('الشبكة ضعيفة جداً'),
        );

    if (response.statusCode == 200) {
      final body = json.decode(response.body);

      List<Product> products = [];
      bool hasMore = false;

      if (body is Map && body.containsKey('data')) {
        final List data = body['data'];
        products = data.map((e) => Product.fromJson(e)).toList();
        hasMore = body['hasMore'] ?? false;
      } else if (body is List) {
        products = body.map((e) => Product.fromJson(e)).toList();
        hasMore = products.length == 10;
      }

      final result = SearchResult(products: products, hasMore: hasMore);

      // 6. إدارة حجم الكاش (Memory Protection) قبل الإضافة
      if (_searchCache.length >= _maxCacheSize) {
        _searchCache.remove(_searchCache.keys.first); // حذف أقدم عنصر
      }
      _searchCache[cacheKey] = CacheItem(result);

      return result;
    } else {
      throw Exception('فشل في جلب المنتجات');
    }
  }

  /// جلب الاقتراحات السريعة (خفيفة جداً، أسماء فقط)
  static Future<List<String>> fetchSuggestions(
    String query,
    String langCode,
  ) async {
    if (query.trim().isEmpty) return [];

    final uri = Uri.parse(
      '$baseUrl/search-suggestions',
    ).replace(queryParameters: {'q': query.trim()});

    final response = await http.get(uri).timeout(const Duration(seconds: 5));

    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
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

  /// جلب الكلمات الأكثر بحثاً
  static Future<List<String>> fetchTrendingTags() async {
    final uri = Uri.parse('$baseUrl/trending-searches');
    final response = await http.get(uri).timeout(const Duration(seconds: 5));

    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((e) => e.toString()).toList();
    }
    throw Exception('فشل في جلب الكلمات الشائعة');
  }

  /// تنظيف الكاش يدوياً
  static void clearCache() {
    _searchCache.clear();
  }
}

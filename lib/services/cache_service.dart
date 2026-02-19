class CacheEntry {
  final dynamic data;
  final DateTime expiry;

  CacheEntry({required this.data, required this.expiry});

  bool get isValid => DateTime.now().isBefore(expiry);
}

class CacheService {
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  final Map<String, CacheEntry> _cache = {};

  T? get<T>(String key) {
    final entry = _cache[key];
    if (entry != null && entry.isValid) {
      return entry.data as T;
    }
    if (entry != null && !entry.isValid) {
      _cache.remove(key);
    }
    return null;
  }

  void set(
    String key,
    dynamic data, {
    Duration duration = const Duration(minutes: 5),
  }) {
    _cache[key] = CacheEntry(data: data, expiry: DateTime.now().add(duration));
  }

  void clear() {
    _cache.clear();
  }
}

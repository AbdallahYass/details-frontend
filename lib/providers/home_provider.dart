import 'package:details_app/app_imports.dart';

class HomeProvider with ChangeNotifier {
  final HomeRepository _homeRepository = HomeRepository();

  List<Product> products = [];
  List<BannerModel> banners = [];
  List<CategoryModel> categories = [];
  List<Product> popularProducts = [];
  Set<String> popularIds = {};

  bool isLoading = true;
  String? errorMessage;

  // للتحكم في الطلبات المتزامنة
  int _requestId = 0;

  String? _selectedCategory;
  String? get selectedCategory => _selectedCategory;

  final Map<String, List<Product>> _groupedProducts = {};
  Map<String, List<Product>> get groupedProducts => _groupedProducts;

  // دالة لتحميل كل البيانات الأولية
  Future<void> loadAllData({bool forceRefresh = false}) async {
    final int currentRequest = ++_requestId;
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final results = await _homeRepository.loadHomeData(
        forceRefresh: forceRefresh,
      );

      // التأكد من أن هذا هو آخر طلب تم إرساله
      if (currentRequest == _requestId) {
        products = results[0] as List<Product>;
        banners = results[1] as List<BannerModel>;
        categories = results[2] as List<CategoryModel>;
        popularProducts = results[3] as List<Product>;
        popularIds = popularProducts.map((e) => e.id).toSet();

        _groupProducts();

        isLoading = false;
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error loading home data: $e");
      if (currentRequest == _requestId) {
        isLoading = false;
        errorMessage = 'error_occurred'; // سيتم ترجمته في الواجهة
        notifyListeners();
      }
    }
  }

  // دالة لتحميل بيانات تصنيف معين
  Future<void> loadCategoryData(String? slug) async {
    final int currentRequest = ++_requestId;
    _selectedCategory = slug;
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _homeRepository.fetchProducts(category: _selectedCategory),
        _homeRepository.fetchBanners(
          location: _selectedCategory == null ? 'home' : 'category',
          category: _selectedCategory,
        ),
      ]);

      if (currentRequest == _requestId) {
        products = results[0] as List<Product>;
        banners = results[1] as List<BannerModel>;

        if (_selectedCategory == null) {
          _groupProducts();
        }

        isLoading = false;
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error loading category data: $e");
      if (currentRequest == _requestId) {
        isLoading = false;
        errorMessage = 'error_occurred';
        notifyListeners();
      }
    }
  }

  void _groupProducts() {
    _groupedProducts.clear();
    for (var product in products) {
      if (!_groupedProducts.containsKey(product.categoryId)) {
        _groupedProducts[product.categoryId] = [];
      }
      _groupedProducts[product.categoryId]!.add(product);
    }
  }

  void clearFilter() {
    _selectedCategory = null;
    // العودة للبيانات الأصلية أو إعادة التحميل حسب المنطق المفضل
    loadAllData();
  }
}

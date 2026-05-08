import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class CartItem {
  final String id;
  final String productId; // ID المنتج الأصلي
  final String title;
  final int quantity;
  final double price;
  final String imageUrl;
  final String? size; // المقاس المختار
  final String? color; // اللون المختار
  final int maxQuantity; // 🌟 الحد الأقصى المتوفر في المخزون لهذا الموديل
  final bool withOriginalBox; // 🌟 خيار إضافة العلبة الأصلية
  final bool allowOriginalBox; // 🌟 هل التصنيف الخاص بالمنتج يدعم العلبة؟

  CartItem({
    required this.id,
    String? productId,
    required this.title,
    required this.quantity,
    required this.price,
    required this.imageUrl,
    this.size,
    this.color,
    this.maxQuantity = 999,
    this.withOriginalBox = false,
    this.allowOriginalBox = false,
  }) : productId = productId ?? id;

  // تحويل الكائن إلى Map ليتم حفظه كـ JSON
  Map<String, dynamic> toJson() => {
    'id': id,
    'productId': productId,
    'title': title,
    'quantity': quantity,
    'price': price,
    'imageUrl': imageUrl,
    'size': size,
    'color': color,
    'maxQuantity': maxQuantity,
    'withOriginalBox': withOriginalBox,
    'allowOriginalBox': allowOriginalBox,
  };

  // إنشاء كائن من Map (عند التحميل من JSON)
  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
    id: json['id'],
    productId: json['productId'],
    title: json['title'],
    quantity: json['quantity'],
    price: (json['price'] as num).toDouble(),
    imageUrl: json['imageUrl'],
    size: json['size'],
    color: json['color'],
    maxQuantity: json['maxQuantity'] ?? 999,
    withOriginalBox: json['withOriginalBox'] ?? false,
    allowOriginalBox: json['allowOriginalBox'] ?? false,
  );
}

class CartProvider with ChangeNotifier {
  Map<String, CartItem> _items = {};
  String? _couponCode;
  double _couponDiscountValue = 0.0;
  String? _couponType;
  bool _withGiftBox = false; // 🌟 خيار التغليف للاوردر كامل

  CartProvider() {
    _loadCartFromPrefs(); // تحميل البيانات فور إنشاء الـ Provider
  }

  Map<String, CartItem> get items => {..._items};

  int get itemCount => _items.length;

  bool get withGiftBox => _withGiftBox;

  // دالة لجلب العدد الإجمالي للقطع (مفيد لإظهار رقم فوق أيقونة السلة)
  int get totalItemsCount {
    var total = 0;
    _items.forEach((_, item) => total += item.quantity);
    return total;
  }

  double get subtotal {
    var total = 0.0;
    _items.forEach((key, cartItem) {
      total += cartItem.price * cartItem.quantity;
    });
    return total;
  }

  // 🌟 حساب رسوم التغليف الإجمالية (5 شيكل ثابتة للاوردر كامل)
  double get giftTotal {
    return _withGiftBox ? 5.0 : 0.0;
  }

  // 🌟 حساب رسوم العلب الأصلية الإجمالية (10 شيكل لكل قطعة)
  double get originalBoxTotal {
    var total = 0.0;
    _items.forEach((_, item) {
      if (item.withOriginalBox) {
        total += (10.0 * item.quantity);
      }
    });
    return total;
  }

  // حساب قيمة الخصم ديناميكياً لضمان دقة النسب المئوية عند تغيير السلة
  double get discountAmount {
    if (_couponType == 'percentage') {
      return subtotal * (_couponDiscountValue / 100);
    }
    return _couponDiscountValue;
  }

  String? get couponCode => _couponCode;

  double get totalAmount {
    final total = subtotal + giftTotal + originalBoxTotal - discountAmount;
    return total > 0 ? total : 0.0;
  }

  // دالة لحفظ البيانات في SharedPreferences
  Future<void> _saveCartToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartData = json.encode({
        'items': _items.map((key, item) => MapEntry(key, item.toJson())),
        'couponCode': _couponCode,
        'couponDiscountValue': _couponDiscountValue,
        'couponType': _couponType,
        'withGiftBox': _withGiftBox,
      });
      await prefs.setString('cart_items_data', cartData);
    } catch (e) {
      debugPrint('Error saving cart: $e');
    }
  }

  // دالة لتحميل البيانات من SharedPreferences
  Future<void> _loadCartFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!prefs.containsKey('cart_items_data')) return;

      final String? jsonString = prefs.getString('cart_items_data');
      if (jsonString == null) return;

      final decoded = json.decode(jsonString);
      if (decoded is! Map<String, dynamic>) return;

      final itemsData = decoded['items'];
      if (itemsData is! Map<String, dynamic>) return;

      final Map<String, CartItem> loadedItems = {};
      itemsData.forEach((key, value) {
        if (value is Map<String, dynamic>) {
          loadedItems[key] = CartItem.fromJson(value);
        }
      });

      _items = loadedItems;
      _couponCode = decoded['couponCode'];
      _couponDiscountValue =
          (decoded['couponDiscountValue'] as num?)?.toDouble() ?? 0.0;
      _couponType = decoded['couponType'];
      _withGiftBox = decoded['withGiftBox'] ?? false;

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading cart: $e');
    }
  }

  // دالة الإضافة مع ربطها بحدود المخزون
  void addItem(
    String productId,
    double price,
    String title,
    String imageUrl, {
    String? size,
    String? color,
    required int maxQuantity,
    int quantityToAdd = 1,
    bool withOriginalBox = false,
    bool allowOriginalBox = false,
  }) {
    // المفتاح في السلة يكون دمجاً بين الآيدي والمقاس واللون وخيار العلبة
    String cartKey = productId;
    if (size != null) cartKey += '_$size';
    if (color != null) cartKey += '_$color';
    if (withOriginalBox) cartKey += '_orig_box';

    if (_items.containsKey(cartKey)) {
      // التحقق من عدم تجاوز الكمية المتوفرة
      if (_items[cartKey]!.quantity + quantityToAdd > maxQuantity) {
        return; // لا تقم بالإضافة إذا وصلنا للحد الأقصى
      }

      // زيادة الكمية إذا المنتج موجود
      _items.update(
        cartKey,
        (existingCartItem) => CartItem(
          id: existingCartItem.id,
          productId: existingCartItem.productId,
          title: existingCartItem.title,
          quantity: existingCartItem.quantity + quantityToAdd,
          price: existingCartItem.price,
          imageUrl: existingCartItem.imageUrl,
          size: existingCartItem.size,
          color: existingCartItem.color,
          maxQuantity: maxQuantity,
          withOriginalBox: existingCartItem.withOriginalBox,
          allowOriginalBox: existingCartItem.allowOriginalBox,
        ),
      );
    } else {
      if (maxQuantity < quantityToAdd) return; // لا يمكن إضافة منتج كميته 0

      // إضافة منتج جديد
      _items.putIfAbsent(
        cartKey,
        () => CartItem(
          id: cartKey,
          productId: productId,
          title: title,
          quantity: quantityToAdd,
          price: price,
          imageUrl: imageUrl,
          size: size,
          color: color,
          maxQuantity: maxQuantity,
          withOriginalBox: withOriginalBox,
          allowOriginalBox: allowOriginalBox,
        ),
      );
    }
    notifyListeners();
    _saveCartToPrefs();
  }

  // 🌟 دالة لتبديل خيار التغليف للاوردر كامل
  void toggleGiftBox() {
    _withGiftBox = !_withGiftBox;
    notifyListeners();
    _saveCartToPrefs();
  }

  // 🌟 دالة لتبديل خيار العلبة الأصلية
  void toggleOriginalBox(String cartKey) {
    final existingItem = _items[cartKey];
    if (existingItem == null || !existingItem.allowOriginalBox) return;

    removeItem(cartKey);
    addItem(
      existingItem.productId,
      existingItem.price,
      existingItem.title,
      existingItem.imageUrl,
      size: existingItem.size,
      color: existingItem.color,
      maxQuantity: existingItem.maxQuantity,
      quantityToAdd: existingItem.quantity,
      withOriginalBox: !existingItem.withOriginalBox,
      allowOriginalBox: existingItem.allowOriginalBox,
    );
  }

  // 🌟 دالة جديدة لتحديث الكمية مباشرة (مثلاً من شاشة السلة)
  bool updateItemQuantity(String cartKey, int newQuantity) {
    if (!_items.containsKey(cartKey)) return false;

    final item = _items[cartKey]!;

    if (newQuantity <= 0) {
      removeItem(cartKey);
      return true;
    }

    // منع تجاوز المخزون المتوفر
    if (newQuantity > item.maxQuantity) return false;

    _items.update(
      cartKey,
      (existing) => CartItem(
        id: existing.id,
        productId: existing.productId,
        title: existing.title,
        quantity: newQuantity,
        price: existing.price,
        imageUrl: existing.imageUrl,
        size: existing.size,
        color: existing.color,
        maxQuantity: existing.maxQuantity,
        withOriginalBox: existing.withOriginalBox,
        allowOriginalBox: existing.allowOriginalBox,
      ),
    );
    notifyListeners();
    _saveCartToPrefs();
    return true;
  }

  void removeSingleItem(String cartKey) {
    if (!_items.containsKey(cartKey)) {
      return;
    }
    if (_items[cartKey]!.quantity > 1) {
      _items.update(
        cartKey,
        (existingCartItem) => CartItem(
          // تم التأكد من نقل كافة البيانات للحفاظ على التناسق
          id: existingCartItem.id,
          productId: existingCartItem.productId,
          title: existingCartItem.title,
          quantity: existingCartItem.quantity - 1,
          price: existingCartItem.price,
          imageUrl: existingCartItem.imageUrl,
          size: existingCartItem.size,
          color: existingCartItem.color,
          maxQuantity: existingCartItem.maxQuantity,
          withOriginalBox: existingCartItem.withOriginalBox,
          allowOriginalBox: existingCartItem.allowOriginalBox,
        ),
      );
    } else {
      _items.remove(cartKey);
    }
    if (_items.isEmpty) {
      _couponCode = null;
      _couponDiscountValue = 0.0;
      _couponType = null;
    }
    notifyListeners();
    _saveCartToPrefs();
  }

  void removeItem(String cartKey) {
    _items.remove(cartKey);
    if (_items.isEmpty) {
      _couponCode = null;
      _couponDiscountValue = 0.0;
      _couponType = null;
    }
    notifyListeners();
    _saveCartToPrefs();
  }

  void clear() {
    _items = {};
    _couponCode = null;
    _couponDiscountValue = 0.0;
    _couponType = null;
    notifyListeners();
    _saveCartToPrefs();
  }

  // دالة للتحقق من المخزون من السيرفر قبل الانتقال لإتمام الطلب
  Future<List<String>> validateInventoryBeforeCheckout() async {
    List<String> adjustedItems = [];
    try {
      final url = Uri.parse(
        'https://api.details-store.com/api/cart/validate-inventory',
      );

      final body = json.encode({
        'items': _items.values
            .map(
              (item) => {
                'productId': item.productId,
                'size': item.size,
                'color': item.color,
                'requestedQuantity': item.quantity,
                'cartKey': item.id,
              },
            )
            .toList(),
      });

      final response = await http
          .post(url, body: body, headers: {'Content-Type': 'application/json'})
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final updatesData = (data is Map<String, dynamic>)
            ? data['updates']
            : null;
        final List updates = (updatesData is List) ? updatesData : [];

        for (var update in updates) {
          final String key = update['cartKey'];
          final int currentStock = update['currentStock'];

          if (_items.containsKey(key)) {
            final existing = _items[key]!;
            if (existing.quantity > currentStock) {
              updateItemQuantity(key, currentStock); // تحديث للحد الأقصى المتاح
              if (currentStock > 0) {
                adjustedItems.add('${existing.title} (quantity_updated)');
              }
            }
            if (currentStock <= 0) {
              removeItem(key); // حذف المنتج إذا نفذ تماماً
              adjustedItems.add('${existing.title} (out_of_stock)');
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Inventory validation error: $e');
    }
    return adjustedItems;
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
        _couponDiscountValue = (data['value'] as num).toDouble();
        _couponType = data['discountType'];
        notifyListeners();
        _saveCartToPrefs();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}

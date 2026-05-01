// ignore_for_file: deprecated_member_use

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:details_app/app_imports.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:details_app/widgets/custom_loading_overlay.dart';
import 'package:details_app/providers/notification_provider.dart';
import 'package:details_app/screens/home/notifications_screen.dart';
import 'package:details_app/providers/home_provider.dart';

/// Data model for a product variant (a specific combination of color, size, and quantity).
class ProductVariant {
  final String? colorHex;
  final String? size;
  final TextEditingController quantityController;

  ProductVariant({this.colorHex, this.size, int quantity = 0})
    : quantityController = TextEditingController(text: quantity.toString());

  // To prevent memory leaks from TextEditingController
  void dispose() {
    quantityController.dispose();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'quantity': int.tryParse(quantityController.text) ?? 0,
    };
    if (colorHex != null) {
      data['colorHex'] = colorHex;
    }
    if (size != null) {
      data['size'] = size;
    }
    return data;
  }
}

class AddEditProductScreen extends StatefulWidget {
  final dynamic product; // If null, we are adding
  const AddEditProductScreen({super.key, this.product});

  @override
  State<AddEditProductScreen> createState() => _AddEditProductScreenState();
}

class _AddEditProductScreenState extends State<AddEditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameArController = TextEditingController();
  final _nameEnController = TextEditingController();
  final _priceController = TextEditingController();
  final _oldPriceController = TextEditingController();
  final _quantityController =
      TextEditingController(); // 🌟 حقل الكمية الإجمالية الجديد
  final _descArController = TextEditingController();
  final _descEnController = TextEditingController();
  final _brandController = TextEditingController();
  final _dimensionsController = TextEditingController();
  final _imageController = TextEditingController();
  final _newCategoryController = TextEditingController(); // للكاتيجوري الجديد
  final _sizeInputController = TextEditingController(); // لإضافة المقاسات
  final _colorHexController = TextEditingController();
  String? _selectedCategory;
  List<dynamic> _categories = [];
  List<String> _galleryImages = []; // قائمة الصور الإضافية
  List<String> _availableSizes = []; // المقاسات المتاحة مثل 'S', 'M'
  List<ProductVariant> _variants = []; // قائمة المتغيرات (لون+مقاس+كمية)
  bool _isLoading = false;
  bool _isImageUploading = false;
  bool _isNewCategory = false; // تحديد وضع الكاتيجوري
  bool _isSoldOut = false;
  bool _isFeatured = false;
  List<ProductColor> _colors = [];
  final List<String> _tempColorImages = [];

  @override
  void initState() {
    super.initState();
    _imageController.addListener(() => setState(() {}));
    _fetchCategories();
    if (widget.product != null) {
      // دعم التعامل مع المنتج سواء كان Map أو كائن Product
      final dynamic p = widget.product;
      final bool isMap = p is Map;

      _nameArController.text = isMap
          ? (p['name']?['ar']?.toString() ?? '')
          : (p.name['ar']?.toString() ?? '');
      _nameEnController.text = isMap
          ? (p['name']?['en']?.toString() ?? '')
          : (p.name['en']?.toString() ?? '');
      _priceController.text = (isMap ? p['price'] : p.price).toString();
      _oldPriceController.text =
          (isMap ? p['oldPrice'] : p.oldPrice)?.toString() ?? '';
      _quantityController.text =
          (isMap ? p['quantity'] : p.quantity)?.toString() ?? '0';

      _descArController.text = isMap
          ? (p['description']?['ar']?.toString() ?? '')
          : (p.description['ar']?.toString() ?? '');
      _descEnController.text = isMap
          ? (p['description']?['en']?.toString() ?? '')
          : (p.description['en']?.toString() ?? '');

      _brandController.text = (isMap ? p['brand'] : p.brand) ?? 'DETAILS';
      _dimensionsController.text =
          (isMap ? p['dimensions'] : p.dimensions) ?? '';
      _imageController.text = (isMap ? p['imageUrl'] : p.imageUrl) ?? '';
      _selectedCategory = isMap
          ? (p['category'] is Map ? p['category']['_id'] : p['category'])
          : p.categoryId;
      _isSoldOut = (isMap ? p['isSoldOut'] : p.isSoldOut) ?? false;
      _isFeatured =
          (isMap ? (p['featured'] ?? p['isFeatured']) : p.featured) ??
          false; // 🌟 استخدام الحقل الجديد

      // تحميل صور المعرض (باستثناء الصورة الرئيسية لتجنب التكرار في العرض)
      final dynamic imagesData = isMap ? p['images'] : p.images;
      if (imagesData != null && imagesData is List) {
        _galleryImages = List<String>.from(imagesData);
        _galleryImages.removeWhere((img) => img == _imageController.text);
      }

      final dynamic colorsData = isMap ? p['colors'] : p.colors;
      if (colorsData != null && colorsData is List) {
        _colors = colorsData.map((e) => ProductColor.fromJson(e)).toList();
      }

      final dynamic sizesData = isMap ? p['sizes'] : p.sizes;
      if (sizesData != null && sizesData is List) {
        _availableSizes = List<String>.from(sizesData);
      }

      final dynamic variantsData = isMap ? p['variants'] : p.variants;
      if (variantsData != null && variantsData is List) {
        _variants = (variantsData)
            .map(
              (v) => ProductVariant(
                colorHex: isMap ? v['colorHex'] : v.colorHex,
                size: isMap ? v['size'] : v.size,
                quantity: isMap ? (v['quantity'] ?? 0) : (v.quantity ?? 0),
              ),
            )
            .toList();
      }
    }
  }

  @override
  void dispose() {
    _nameArController.dispose();
    _nameEnController.dispose();
    _priceController.dispose();
    _oldPriceController.dispose();
    _quantityController.dispose();
    _descArController.dispose();
    _descEnController.dispose();
    _brandController.dispose();
    _dimensionsController.dispose();
    _imageController.dispose();
    _newCategoryController.dispose();
    _sizeInputController.dispose();
    _colorHexController.dispose();
    // Dispose all variant controllers to prevent memory leaks
    for (var variant in _variants) {
      variant.dispose();
    }
    super.dispose();
  }

  Future<void> _fetchCategories() async {
    try {
      final res = await http.get(
        Uri.parse('https://api.details-store.com/api/categories'),
      );
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        setState(() {
          if (data is List) {
            _categories = data;
            if (_selectedCategory == null && _categories.isNotEmpty) {
              _selectedCategory = _categories[0]['_id'];
            }
          }
        });
      }
    } catch (e) {
      debugPrint('Error fetching categories: $e');
    }
  }

  /// A generic helper to pick and upload an image, then run a success callback.
  Future<void> _handleImagePick({
    required void Function(String imageUrl) onSuccess,
    String? successMessage,
  }) async {
    setState(() => _isImageUploading = true);
    final String? imageUrl = await CloudinaryService().pickAndUploadImage();
    setState(() => _isImageUploading = false);

    if (imageUrl != null) {
      setState(() => onSuccess(imageUrl));
      if (mounted && successMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(successMessage),
            backgroundColor: AppColors.adminDashCoupons,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.translate('image_upload_failed'),
            ),
            backgroundColor: AppColors.adminDelete,
          ),
        );
      }
    }
  }

  // دالة عرض منتقي الألوان الشامل (Full Color Picker)
  void _showColorPicker() {
    Color pickerColor = _colorHexController.text.length >= 7
        ? Color(
            int.tryParse(_colorHexController.text.replaceFirst('#', '0xFF')) ??
                0xFF000000,
          )
        : const Color(0xFF000000);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.background,
          title: Text(
            AppLocalizations.of(context)!.translate('colors'),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: pickerColor,
              onColorChanged: (Color color) {
                pickerColor = color;
              },
              pickerAreaHeightPercent: 0.8,
              enableAlpha: false, // لا نحتاج للشفافية في ألوان المنتجات
              displayThumbColor: true,
              paletteType: PaletteType.hsvWithHue, // عجلة الألوان الكاملة
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppLocalizations.of(context)!.translate('cancel')),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  // تحويل اللون المختار إلى كود Hex (مثال: #FF5733)
                  _colorHexController.text =
                      '#${pickerColor.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
                });
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: Text(
                AppLocalizations.of(context)!.translate('save'),
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  void _generateVariants() {
    // 1. Clear old variants and dispose their controllers
    for (var variant in _variants) {
      variant.dispose();
    }

    setState(() {
      _variants.clear();

      final hasColors = _colors.isNotEmpty;
      final hasSizes = _availableSizes.isNotEmpty;

      if (hasColors && hasSizes) {
        // Case 1: Product has both colors and sizes (e.g., T-shirt)
        for (var color in _colors) {
          for (var size in _availableSizes) {
            _variants.add(ProductVariant(colorHex: color.hex, size: size));
          }
        }
      } else if (hasColors) {
        // Case 2: Product has colors but no sizes (e.g., Bracelet)
        for (var color in _colors) {
          // We use a null size to represent "one size" or "free size"
          _variants.add(ProductVariant(colorHex: color.hex, size: null));
        }
      } else if (hasSizes) {
        // Case 3: Product has sizes but no colors (e.g., a plain ring)
        for (var size in _availableSizes) {
          _variants.add(ProductVariant(size: size, colorHex: null));
        }
      } else {
        // Case 4: Simple product with no variants (e.g., a book)
        // We create one default variant to hold the quantity.
        _variants.add(ProductVariant());
      }
    });
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final loc = AppLocalizations.of(context)!;
    final auth = Provider.of<AuthProvider>(context, listen: false);

    // استخراج الـ ID بشكل آمن جداً
    String? productId;
    if (widget.product != null) {
      if (widget.product is Map) {
        productId = (widget.product['_id'] ?? widget.product['id'])?.toString();
      } else {
        // التأكد من أن الـ ID ليس نصاً فارغاً
        final String idStr = widget.product.id.toString();
        productId = idStr.isNotEmpty ? idStr : null;
      }
    }

    // إذا كان الـ ID نول أو فارغ، نعتبرها عملية إضافة (POST)
    final bool isUpdating = productId != null && productId.isNotEmpty;
    final url = !isUpdating
        ? 'https://api.details-store.com/api/products'
        : 'https://api.details-store.com/api/products/$productId';

    final method = !isUpdating ? 'POST' : 'PUT';

    try {
      String finalImageUrl = _imageController.text;

      // 1. تحديد ما إذا كان المنتج بسيطاً (بدون ألوان أو مقاسات محددة) بشكل أدق
      final bool isSimpleProduct =
          (_colors.isEmpty && _availableSizes.isEmpty) || _variants.isEmpty;

      int totalQuantity = 0;

      // 2. إذا كان المنتج له متغيرات (ألوان/مقاسات)، نعتمد مجموع قيم الجدول
      if (!isSimpleProduct) {
        totalQuantity = _variants.fold<int>(
          0,
          (sum, v) => sum + (int.tryParse(v.quantityController.text) ?? 0),
        );
      } else {
        // 3. إذا كان منتجاً بسيطاً، نعتمد القيمة المكتوبة في بوكس الكمية الرئيسي
        totalQuantity = int.tryParse(_quantityController.text) ?? 0;
      }

      // تجهيز قائمة الصور مع تجنب تكرار الصورة الرئيسية
      final List<String> allImages = [finalImageUrl];
      allImages.addAll(_galleryImages.where((img) => img != finalImageUrl));

      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${auth.token}',
      };

      // تحديد قيمة الكاتيجوري
      String? finalCategoryId = _selectedCategory;

      if (_isNewCategory) {
        // إنشاء التصنيف في الباك إند أولاً للحصول على الـ ID الخاص به
        final catResponse = await http.post(
          Uri.parse('https://api.details-store.com/api/categories'),
          headers: headers,
          body: json.encode({
            'name': {
              'ar': _newCategoryController.text.trim(),
              'en': _newCategoryController.text.trim(), // مبدئياً نفس الاسم
            },
            'slug': _newCategoryController.text.trim().toLowerCase().replaceAll(
              RegExp(r'\s+'),
              '-',
            ),
            'imageUrl':
                finalImageUrl, // نستخدم صورة المنتج كصورة للقسم الجديد مؤقتاً
          }),
        );

        if (!mounted) return;
        if (catResponse.statusCode == 201 || catResponse.statusCode == 200) {
          final catData = json.decode(catResponse.body);
          finalCategoryId =
              catData['_id'] ?? catData['id']; // استخراج آمن للـ ID
        } else {
          throw Exception(loc.translate('category_creation_failed'));
        }
      }

      if (finalCategoryId == null || finalCategoryId.isEmpty) {
        throw Exception(loc.translate('select_category_error'));
      }

      final Map<String, dynamic> requestBody = {
        'name': {
          'ar': _nameArController.text.trim(),
          'en': _nameEnController.text.trim(),
        },
        'price': num.tryParse(_priceController.text) ?? 0,
        'oldPrice': _oldPriceController.text.isNotEmpty
            ? num.tryParse(_oldPriceController.text)
            : null,
        'quantity': totalQuantity, // إرسال الكمية المحسوبة بدقة
        'description': {
          'ar': _descArController.text.trim(),
          'en': _descEnController.text.trim(),
        },
        'brand': _brandController.text.trim().isEmpty
            ? 'DETAILS'
            : _brandController.text.trim(),
        'dimensions': _dimensionsController.text.trim(),
        'imageUrl': finalImageUrl,
        'category': finalCategoryId,
        'isSoldOut': _isSoldOut,
        'featured': _isFeatured,
        'images': allImages,
        'colors': _colors.map((c) => c.toJson()).toList(),
        'sizes': _availableSizes,
        // إذا كان المنتج بسيطاً، نرسل [] لإخبار الباك إند ألا يبحث عن كميات في المتغيرات
        'variants': isSimpleProduct
            ? []
            : _variants.map((v) => v.toJson()).toList(),
      };

      final bodyStr = json.encode(requestBody);

      // 🔍 تتبع الطلب (Request Tracking)
      debugPrint('========= 🚀 PRODUCT UPDATE START =========');
      debugPrint('📍 URL: $url');
      debugPrint('🛠️ METHOD: $method');
      debugPrint('📦 BODY: $bodyStr');

      final response = await (method == 'POST'
          ? http.post(Uri.parse(url), headers: headers, body: bodyStr)
          : http.put(Uri.parse(url), headers: headers, body: bodyStr));

      // 🔍 تتبع الاستجابة (Response Tracking)
      debugPrint('📥 STATUS CODE: ${response.statusCode}');
      debugPrint('📄 RESPONSE BODY: ${response.body}');
      debugPrint('========= 🏁 PRODUCT UPDATE END =========');

      if (!mounted) return;
      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          // تحديث البيانات في الـ Provider لضمان ظهور التعديلات فوراً
          await Provider.of<HomeProvider>(
            context,
            listen: false,
          ).loadAllData(forceRefresh: true);
        } catch (e) {
          debugPrint('🚨 Error refreshing data: $e');
        }

        if (!mounted) return;
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loc.translate('product_saved')),
            backgroundColor: AppColors.success,
          ),
        );
      } else if (response.statusCode == 401) {
        await auth.logout();
        throw Exception(loc.translate('session_expired'));
      } else {
        String errorMessageForUser =
            '${loc.translate('error_label')} (${response.statusCode})';
        String backendErrorDetails = '';
        try {
          final respBody = json.decode(response.body);
          backendErrorDetails = respBody['error'] ?? respBody['message'] ?? '';
        } catch (_) {
          // إذا كان جسم الاستجابة ليس JSON، نستخدمه كنص خطأ خام
          backendErrorDetails = response.body;
        }
        // دمج رسالة الخطأ العامة مع التفاصيل المحددة من الباك إند
        throw Exception(
          '$errorMessageForUser\n${backendErrorDetails.isNotEmpty ? backendErrorDetails : loc.translate('error_occurred')}',
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${loc.translate('error_occurred')}\n$e'),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 110,
        title: Image.asset('assets/images/logo2.png', height: 100),
        backgroundColor: AppColors.appBarBackground,
        foregroundColor: AppColors.appBarForeground,
        scrolledUnderElevation: 0,
        surfaceTintColor: AppColors.transparent,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Consumer<NotificationProvider>(
            builder: (context, notifProvider, child) {
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const NotificationsScreen(),
                        ),
                      );
                    },
                  ),
                  if (notifProvider.unreadCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '${notifProvider.unreadCount}',
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        height: 70,
        decoration: BoxDecoration(
          color: AppColors.homeNavBackground,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _navIcon(context, Icons.home_outlined, 0),
            _navIcon(context, Icons.search, 1),
            _navIcon(context, Icons.shopping_bag_outlined, 2),
            _navIcon(context, Icons.favorite_border, 3),
          ],
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameArController,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(
                        context,
                      )!.translate('product_name_ar'),
                    ),
                    validator: (v) => v!.isEmpty
                        ? AppLocalizations.of(
                            context,
                          )!.translate('required_field')
                        : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _nameEnController,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(
                        context,
                      )!.translate('product_name_en'),
                    ),
                    validator: (v) => v!.isEmpty
                        ? AppLocalizations.of(
                            context,
                          )!.translate('required_field')
                        : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _priceController,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(
                        context,
                      )!.translate('price'),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v == null || v.isEmpty) {
                        return AppLocalizations.of(
                          context,
                        )!.translate('required_field');
                      }
                      if (double.tryParse(v) == null) {
                        return AppLocalizations.of(
                          context,
                        )!.translate('enter_valid_number');
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _oldPriceController,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(
                        context,
                      )!.translate('old_price'),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _quantityController,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(
                        context,
                      )!.translate('quantity'),
                      hintText: AppLocalizations.of(
                        context,
                      )!.translate('total_quantity_hint'),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _brandController,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(
                        context,
                      )!.translate('brand'),
                      hintText: AppLocalizations.of(
                        context,
                      )!.translate('app_name'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _dimensionsController,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(
                        context,
                      )!.translate('dimensions'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _sizeInputController,
                          decoration: InputDecoration(
                            labelText: AppLocalizations.of(
                              context,
                            )!.translate('add_size'),
                            hintText: AppLocalizations.of(
                              context,
                            )!.translate('size_example'),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      IconButton(
                        icon: const Icon(
                          Icons.add_circle,
                          color: AppColors.adminEdit,
                        ),
                        onPressed: () {
                          final size = _sizeInputController.text.trim();
                          if (size.isNotEmpty &&
                              !_availableSizes.contains(size)) {
                            setState(() {
                              _availableSizes.add(size);
                              _sizeInputController.clear();
                            });
                          }
                        },
                      ),
                    ],
                  ),
                  if (_availableSizes.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Wrap(
                        spacing: 8,
                        children: _availableSizes
                            .map(
                              (size) => Chip(
                                label: Text(size),
                                onDeleted: () {
                                  setState(() {
                                    _availableSizes.remove(size);
                                  });
                                },
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  const SizedBox(height: 10),
                  // --- Colors Section ---
                  Text(
                    AppLocalizations.of(context)!.translate('colors'),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _colorHexController,
                          decoration: InputDecoration(
                            labelText: AppLocalizations.of(
                              context,
                            )!.translate('hex_code'),
                            hintText: '#000000',
                            prefixIcon: Container(
                              margin: const EdgeInsets.all(12),
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: _colorHexController.text.length >= 7
                                    ? Color(
                                        int.tryParse(
                                              _colorHexController.text
                                                  .replaceFirst('#', '0xFF'),
                                            ) ??
                                            0x00000000,
                                      )
                                    : Colors.transparent,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.grey.shade400),
                              ),
                            ),
                            suffixIcon: IconButton(
                              icon: const Icon(
                                Icons.palette,
                                color: AppColors.primary,
                              ),
                              onPressed: _showColorPicker,
                            ),
                          ),
                          onChanged: (v) => setState(() {}),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.add_photo_alternate,
                          color: _tempColorImages.isNotEmpty
                              ? Colors.green
                              : AppColors.adminEdit,
                        ),
                        onPressed: _isImageUploading
                            ? null
                            : () => _handleImagePick(
                                onSuccess: (url) => _tempColorImages.add(url),
                              ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.add_circle,
                          color: AppColors.adminEdit,
                        ),
                        onPressed: () {
                          if (_colorHexController.text.isNotEmpty) {
                            setState(() {
                              _colors.add(
                                ProductColor(
                                  hex: _colorHexController.text.trim(),
                                  images: List.from(_tempColorImages),
                                ),
                              );
                              _colorHexController.clear();
                              _tempColorImages.clear();
                            });
                          }
                        },
                      ),
                    ],
                  ),
                  if (_tempColorImages.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _tempColorImages.map((img) {
                          return Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: CachedNetworkImage(
                                    imageUrl: img,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              Positioned(
                                top: -8,
                                right: -8,
                                child: GestureDetector(
                                  onTap: () => setState(
                                    () => _tempColorImages.remove(img),
                                  ),
                                  child: const CircleAvatar(
                                    radius: 10,
                                    backgroundColor: AppColors.adminDelete,
                                    child: Icon(
                                      Icons.close,
                                      size: 14,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  if (_colors.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Wrap(
                        spacing: 8,
                        children: _colors.map((c) {
                          return Chip(
                            avatar: c.images.isNotEmpty
                                ? CircleAvatar(
                                    backgroundImage: CachedNetworkImageProvider(
                                      c.images.first,
                                    ),
                                  )
                                : CircleAvatar(
                                    backgroundColor: Color(
                                      int.tryParse(
                                            c.hex.replaceFirst('#', '0xFF'),
                                          ) ??
                                          0xFF000000,
                                    ),
                                  ),
                            label: Text(c.hex),
                            onDeleted: () {
                              setState(() {
                                _colors.remove(c);
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ),
                  const SizedBox(height: 10),
                  // --- Variants Section ---
                  const Divider(height: 30),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.inventory_2_outlined),
                    label: Text(
                      AppLocalizations.of(
                        context,
                      )!.translate('generate_quantities'),
                    ),
                    onPressed: _generateVariants,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.adminDashProducts,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 45),
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (_variants.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          // Header
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: Text(
                                  AppLocalizations.of(
                                    context,
                                  )!.translate('color'),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  AppLocalizations.of(
                                    context,
                                  )!.translate('size'),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: Text(
                                  AppLocalizations.of(
                                    context,
                                  )!.translate('quantity'),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Divider(),
                          // Rows
                          ..._variants.map((variant) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 4.0,
                              ),
                              child: Row(
                                children: [
                                  // Color
                                  Expanded(
                                    flex: 2,
                                    child: variant.colorHex != null
                                        ? Chip(
                                            avatar: CircleAvatar(
                                              backgroundColor: Color(
                                                int.tryParse(
                                                      variant.colorHex!
                                                          .replaceFirst(
                                                            '#',
                                                            '0xFF',
                                                          ),
                                                    ) ??
                                                    0xFF000000,
                                              ),
                                            ),
                                            label: Text(variant.colorHex!),
                                            padding: EdgeInsets.zero,
                                          )
                                        : Text(
                                            AppLocalizations.of(
                                              context,
                                            )!.translate('default_val'),
                                          ),
                                  ),
                                  // Size
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      variant.size ??
                                          AppLocalizations.of(
                                            context,
                                          )!.translate('one_size'),
                                    ),
                                  ),
                                  // Quantity
                                  Expanded(
                                    flex: 1,
                                    child: TextFormField(
                                      controller: variant.quantityController,
                                      keyboardType: TextInputType.number,
                                      textAlign: TextAlign.center,
                                      decoration: const InputDecoration(
                                        border: OutlineInputBorder(),
                                        contentPadding: EdgeInsets.all(8),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),

                  // --- قسم اختيار الكاتيجوري ---
                  SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<bool>(
                      segments: [
                        ButtonSegment<bool>(
                          value: false,
                          label: Text(
                            AppLocalizations.of(
                              context,
                            )!.translate('existing_category'),
                          ),
                          icon: const Icon(Icons.category),
                        ),
                        ButtonSegment<bool>(
                          value: true,
                          label: Text(
                            AppLocalizations.of(
                              context,
                            )!.translate('new_category'),
                          ),
                          icon: const Icon(Icons.add),
                        ),
                      ],
                      selected: {_isNewCategory},
                      onSelectionChanged: (Set<bool> newSelection) {
                        setState(() {
                          _isNewCategory = newSelection.first;
                        });
                      },
                    ),
                  ),
                  if (!_isNewCategory)
                    DropdownButtonFormField<String>(
                      initialValue:
                          _selectedCategory != null &&
                              _categories.any(
                                (c) => c['_id'] == _selectedCategory,
                              )
                          ? _selectedCategory
                          : null,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(
                          context,
                        )!.translate('select_category'),
                      ),
                      items: _categories.map<DropdownMenuItem<String>>((c) {
                        final name = c['name']?.toString();
                        return DropdownMenuItem(
                          value: c['_id'],
                          child: Text(
                            name ??
                                AppLocalizations.of(
                                  context,
                                )!.translate('no_name'),
                          ),
                        );
                      }).toList(),
                      onChanged: (v) => setState(() => _selectedCategory = v),
                      validator: (v) => !_isNewCategory && v == null
                          ? AppLocalizations.of(
                              context,
                            )!.translate('required_field')
                          : null,
                    )
                  else
                    TextFormField(
                      controller: _newCategoryController,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(
                          context,
                        )!.translate('new_category_name'),
                      ),
                      validator: (v) => _isNewCategory && v!.isEmpty
                          ? AppLocalizations.of(
                              context,
                            )!.translate('required_field')
                          : null,
                    ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _imageController,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(
                        context,
                      )!.translate('image_url'),
                      suffixIcon: IconButton(
                        icon: const Icon(
                          Icons.image,
                          color: AppColors.adminEdit,
                        ),
                        onPressed: () => _handleImagePick(
                          onSuccess: (url) => _imageController.text = url,
                          successMessage: AppLocalizations.of(
                            context,
                          )!.translate('image_uploaded'),
                        ),
                      ),
                    ),
                    validator: (v) => v!.isEmpty
                        ? AppLocalizations.of(
                            context,
                          )!.translate('required_field')
                        : null,
                  ),
                  if (_imageController.text.isNotEmpty) ...[
                    const SizedBox(height: 15),
                    Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.arrowInactive),
                        borderRadius: BorderRadius.circular(12),
                        color: AppColors.lightGrey,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: CachedNetworkImage(
                          imageUrl: _imageController.text,
                          fit: BoxFit.contain,
                          placeholder: (context, url) => Container(
                            color: AppColors.grey200,
                            child: const Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.broken_image,
                                  color: AppColors.grey,
                                  size: 40,
                                ),
                                Text(
                                  AppLocalizations.of(
                                    context,
                                  )!.translate('invalid_url'),
                                  style: const TextStyle(color: AppColors.grey),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],

                  // --- قسم صور المعرض (Gallery) ---
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        AppLocalizations.of(
                          context,
                        )!.translate('gallery_images'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        onPressed: _isImageUploading
                            ? null
                            : () => _handleImagePick(
                                onSuccess: (url) => _galleryImages.add(url),
                                successMessage: AppLocalizations.of(
                                  context,
                                )!.translate('image_added_to_gallery'),
                              ),
                        icon: const Icon(Icons.add_photo_alternate),
                        color: AppColors.adminEdit,
                      ),
                    ],
                  ),
                  if (_galleryImages.isNotEmpty)
                    SizedBox(
                      height: 100,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _galleryImages.length,
                        itemBuilder: (ctx, i) {
                          return Stack(
                            children: [
                              Container(
                                margin: const EdgeInsets.only(right: 10),
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: AppColors.arrowInactive,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: CachedNetworkImage(
                                    imageUrl: _galleryImages[i],
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => const Center(
                                      child: SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 0,
                                right: 10,
                                child: GestureDetector(
                                  onTap: () => setState(() {
                                    _galleryImages.removeAt(i);
                                  }),
                                  child: const CircleAvatar(
                                    radius: 12,
                                    backgroundColor: AppColors.adminDelete,
                                    child: Icon(
                                      Icons.close,
                                      size: 16,
                                      color: AppColors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),

                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _descArController,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(
                        context,
                      )!.translate('description_ar'),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _descEnController,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(
                        context,
                      )!.translate('description_en'),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 10),
                  SwitchListTile(
                    title: Text(
                      AppLocalizations.of(context)!.translate('is_sold_out'),
                    ),
                    value: _isSoldOut,
                    onChanged: (val) => setState(() => _isSoldOut = val),
                  ),
                  SwitchListTile(
                    title: Text(
                      AppLocalizations.of(context)!.translate('is_featured'),
                    ),
                    subtitle: Text(
                      AppLocalizations.of(
                        context,
                      )!.translate('featured_subtitle'),
                    ),
                    value: _isFeatured,
                    onChanged: (val) => setState(() => _isFeatured = val),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: (_isLoading || _isImageUploading)
                        ? null
                        : _saveProduct,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: Text(
                      AppLocalizations.of(context)!.translate('save'),
                      style: const TextStyle(color: AppColors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isLoading || _isImageUploading) const CustomLoadingOverlay(),
        ],
      ),
    );
  }

  Widget _navIcon(BuildContext context, IconData icon, int index) {
    return GestureDetector(
      onTap: () => _onNavTap(context, index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(icon, color: AppColors.homeNavInactive, size: 24),
      ),
    );
  }

  void _onNavTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/');
        break;
      case 1:
        context.go('/search');
        break;
      case 2:
        context.go('/cart');
        break;
      case 3:
        context.go('/wishlist');
        break;
    }
  }
}

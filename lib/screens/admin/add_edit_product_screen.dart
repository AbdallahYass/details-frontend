// ignore_for_file: deprecated_member_use

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:details_app/app_imports.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:details_app/widgets/custom_loading_overlay.dart';
import 'package:details_app/providers/notification_provider.dart';
import 'package:details_app/screens/home/notifications_screen.dart';

/// Data model for a product variant (a specific combination of color, size, and quantity).
class ProductVariant {
  String? colorHex;
  String? size;
  final TextEditingController quantityController;

  ProductVariant({this.colorHex, this.size, int quantity = 0})
    : quantityController = TextEditingController(text: quantity.toString());

  // To prevent memory leaks from TextEditingController
  void dispose() {
    quantityController.dispose();
  }

  Map<String, dynamic> toJson() => {
    'colorHex': colorHex,
    'size': size,
    'quantity': int.tryParse(quantityController.text) ?? 0,
  };
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
      final p = widget.product;
      _nameArController.text = p['name'] is Map ? (p['name']['ar'] ?? '') : '';
      _nameEnController.text = p['name'] is Map ? (p['name']['en'] ?? '') : '';
      _priceController.text = p['price'].toString();
      _oldPriceController.text = p['oldPrice']?.toString() ?? '';
      _descArController.text = p['description'] is Map
          ? (p['description']['ar'] ?? '')
          : '';
      _descEnController.text = p['description'] is Map
          ? (p['description']['en'] ?? '')
          : '';
      _brandController.text = p['brand'] ?? 'DETAILS';
      _dimensionsController.text = p['dimensions'] ?? '';
      _imageController.text = p['imageUrl'] ?? '';
      _selectedCategory = p['category'] is Map
          ? p['category']['_id']
          : p['category'];
      _isSoldOut = p['isSoldOut'] ?? false;
      _isFeatured = p['featured'] ?? false;

      // تحميل صور المعرض (باستثناء الصورة الرئيسية لتجنب التكرار في العرض)
      if (p['images'] != null && p['images'] is List) {
        _galleryImages = List<String>.from(p['images']);
        // إزالة الصورة الرئيسية من القائمة إذا كانت موجودة
        _galleryImages.removeWhere((img) => img == p['imageUrl']);
      }
      if (p['colors'] != null) {
        _colors = (p['colors'] as List)
            .map((e) => ProductColor.fromJson(e))
            .toList();
      }
      if (p['sizes'] != null && p['sizes'] is List) {
        _availableSizes = List<String>.from(p['sizes']);
      }
      if (p['variants'] != null && p['variants'] is List) {
        _variants = (p['variants'] as List)
            .map(
              (v) => ProductVariant(
                colorHex: v['colorHex'],
                size: v['size'],
                quantity: v['quantity'] ?? 0,
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

  // دالة لرفع الصورة الرئيسية
  Future<void> _pickMainImage() async {
    setState(() => _isImageUploading = true);
    final String? imageUrl = await CloudinaryService().pickAndUploadImage();
    setState(() => _isImageUploading = false);

    if (imageUrl != null) {
      setState(() {
        _imageController.text = imageUrl;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.translate('image_uploaded'),
            ),
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

  // دالة لرفع صور المعرض
  Future<void> _pickGalleryImage() async {
    setState(() => _isImageUploading = true);
    final String? imageUrl = await CloudinaryService().pickAndUploadImage();
    setState(() => _isImageUploading = false);

    if (imageUrl != null) {
      setState(() {
        _galleryImages.add(imageUrl);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.translate('image_added_to_gallery'),
            ),
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

  // دالة لرفع صورة خاصة باللون المختار
  Future<void> _pickTempColorImage() async {
    setState(() => _isImageUploading = true);
    final String? imageUrl = await CloudinaryService().pickAndUploadImage();
    setState(() => _isImageUploading = false);

    if (imageUrl != null) {
      setState(() {
        _tempColorImages.add(imageUrl);
      });
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

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final url = widget.product == null
        ? 'https://api.details-store.com/api/products'
        : 'https://api.details-store.com/api/products/${widget.product['_id']}';

    final method = widget.product == null ? 'POST' : 'PUT';

    try {
      String finalImageUrl = _imageController.text;

      // Calculate total quantity from variants
      final totalQuantity = _variants.fold<int>(
        0,
        (sum, v) => sum + (int.tryParse(v.quantityController.text) ?? 0),
      );

      // تجهيز قائمة الصور مع تجنب تكرار الصورة الرئيسية
      final List<String> allImages = [finalImageUrl];
      allImages.addAll(_galleryImages.where((img) => img != finalImageUrl));

      // تحديد قيمة الكاتيجوري (إما ID موجود أو اسم جديد)
      final categoryValue = _isNewCategory
          ? _newCategoryController.text
          : _selectedCategory;

      final request = http.Request(method, Uri.parse(url));
      request.headers.addAll({
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${auth.token}',
      });
      request.body = json.encode({
        'name': {'ar': _nameArController.text, 'en': _nameEnController.text},
        'price': double.tryParse(_priceController.text) ?? 0.0,
        'oldPrice': _oldPriceController.text.isNotEmpty
            ? double.tryParse(_oldPriceController.text)
            : null,
        'quantity': totalQuantity, // الكمية الإجمالية المحسوبة
        'description': {
          'ar': _descArController.text,
          'en': _descEnController.text,
        },
        'brand': _brandController.text.isNotEmpty
            ? _brandController.text
            : 'DETAILS',
        'dimensions': _dimensionsController.text,
        'imageUrl': finalImageUrl,
        'category': categoryValue,
        'isSoldOut': _isSoldOut,
        'featured': _isFeatured,
        'images': allImages,
        'colors': _colors.map((c) => c.toJson()).toList(), // للألوان المعروضة
        'sizes': _availableSizes, // للمقاسات المعروضة
        'variants': _variants.map((v) => v.toJson()).toList(), // المخزون الفعلي
      });

      final response = await request.send();

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)!.translate('product_saved'),
              ),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } else if (response.statusCode == 401) {
        await auth.logout();
        throw Exception('انتهت صلاحية الجلسة، يرجى تسجيل الدخول مجدداً.');
      } else {
        final respBody = await response.stream.bytesToString();
        throw Exception('خطأ ${response.statusCode}: $respBody');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${AppLocalizations.of(context)!.translate('error_occurred')}\n$e',
            ),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 4),
          ),
        );
      }
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
                    controller: _brandController,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(
                        context,
                      )!.translate('brand'),
                      hintText: 'DETAILS',
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
                            : _pickTempColorImage,
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
                    label: const Text('توليد الكميات'),
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
                          const Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: Text(
                                  'اللون',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  'المقاس',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: Text(
                                  'الكمية',
                                  style: TextStyle(fontWeight: FontWeight.bold),
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
                                        : const Text('افتراضي'),
                                  ),
                                  // Size
                                  Expanded(
                                    flex: 2,
                                    child: Text(variant.size ?? 'مقاس موحد'),
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
                        final name = c['name'] is Map
                            ? c['name']['ar']
                            : c['name'];
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
                        onPressed: _pickMainImage,
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
                          placeholder: (context, url) =>
                              Container(color: AppColors.grey200),
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
                        onPressed: _isImageUploading ? null : _pickGalleryImage,
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

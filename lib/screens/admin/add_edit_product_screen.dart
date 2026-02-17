import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:details_app/constants/app_colors.dart';
import 'package:details_app/providers/auth_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:details_app/screens/home/cloudinary_service.dart';
import 'package:details_app/models/product.dart';

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
  final _quantityController = TextEditingController();
  final _descArController = TextEditingController();
  final _descEnController = TextEditingController();
  final _imageController = TextEditingController();
  final _newCategoryController = TextEditingController(); // للكاتيجوري الجديد
  final _sizeInputController = TextEditingController();
  final _sizeQtyController = TextEditingController();
  String? _selectedCategory;
  List<dynamic> _categories = [];
  List<String> _galleryImages = []; // قائمة الصور الإضافية
  List<ProductSize> _sizes = [];
  bool _isLoading = false;
  bool _isImageUploading = false;
  bool _isNewCategory = false; // تحديد وضع الكاتيجوري
  bool _isSoldOut = false;
  bool _isFeatured = false;

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
      _quantityController.text = p['quantity']?.toString() ?? '';
      _descArController.text = p['description'] is Map
          ? (p['description']['ar'] ?? '')
          : '';
      _descEnController.text = p['description'] is Map
          ? (p['description']['en'] ?? '')
          : '';
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
      if (p['sizes'] != null) {
        _sizes = (p['sizes'] as List)
            .map((e) => ProductSize.fromJson(e))
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
    _imageController.dispose();
    _newCategoryController.dispose();
    _sizeInputController.dispose();
    _sizeQtyController.dispose();
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
          const SnackBar(
            content: Text('تم رفع الصورة بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('فشل رفع الصورة'),
            backgroundColor: Colors.red,
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
          const SnackBar(
            content: Text('تم إضافة الصورة للمعرض'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('فشل رفع الصورة'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
        'quantity': int.tryParse(_quantityController.text) ?? 0,
        'sizes': _sizes.map((e) => e.toJson()).toList(),
        'description': {
          'ar': _descArController.text,
          'en': _descEnController.text,
        },
        'imageUrl': finalImageUrl,
        'category': categoryValue,
        'isSoldOut': _isSoldOut,
        'featured': _isFeatured,
        'images': allImages,
      });

      final response = await request.send();

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('تم حفظ المنتج بنجاح')));
        }
      } else {
        throw Exception('Failed to save');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('حدث خطأ')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product == null ? 'إضافة منتج' : 'تعديل منتج'),
        backgroundColor: AppColors.appBarBackground,
        foregroundColor: AppColors.appBarForeground,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameArController,
                decoration: const InputDecoration(
                  labelText: 'اسم المنتج (عربي)',
                ),
                validator: (v) => v!.isEmpty ? 'مطلوب' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _nameEnController,
                decoration: const InputDecoration(
                  labelText: 'اسم المنتج (إنجليزي)',
                ),
                validator: (v) => v!.isEmpty ? 'مطلوب' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: 'السعر'),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'مطلوب';
                  if (double.tryParse(v) == null) return 'أدخل رقم صحيح';
                  return null;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _oldPriceController,
                decoration: const InputDecoration(
                  labelText: 'السعر القديم (اختياري)',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _quantityController,
                decoration: const InputDecoration(labelText: 'الكمية المتوفرة'),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'مطلوب';
                  if (int.tryParse(v) == null) return 'أدخل رقم صحيح';
                  return null;
                },
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _sizeInputController,
                      decoration: const InputDecoration(
                        labelText: 'إضافة مقاس (Size)',
                        hintText: 'مثال: S, M, 42',
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 80,
                    child: TextFormField(
                      controller: _sizeQtyController,
                      decoration: const InputDecoration(labelText: 'الكمية'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.add_circle,
                      color: AppColors.primary,
                    ),
                    onPressed: () {
                      if (_sizeInputController.text.isNotEmpty) {
                        final qty = int.tryParse(_sizeQtyController.text) ?? 0;
                        setState(() {
                          _sizes.add(
                            ProductSize(
                              size: _sizeInputController.text.trim(),
                              quantity: qty,
                            ),
                          );
                          _sizeInputController.clear();
                          _sizeQtyController.clear();
                        });
                      }
                    },
                  ),
                ],
              ),
              if (_sizes.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Wrap(
                    spacing: 8,
                    children: _sizes
                        .map(
                          (s) => Chip(
                            label: Text('${s.size} (${s.quantity})'),
                            onDeleted: () {
                              setState(() {
                                _sizes.remove(s);
                              });
                            },
                          ),
                        )
                        .toList(),
                  ),
                ),
              const SizedBox(height: 10),

              // --- قسم اختيار الكاتيجوري ---
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment<bool>(
                      value: false,
                      label: Text('تصنيف موجود'),
                      icon: Icon(Icons.category),
                    ),
                    ButtonSegment<bool>(
                      value: true,
                      label: Text('تصنيف جديد'),
                      icon: Icon(Icons.add),
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
                  // ignore: deprecated_member_use
                  // التأكد من أن القيمة المختارة موجودة في القائمة لتجنب الكراش
                  initialValue:
                      _selectedCategory != null &&
                          _categories.any((c) => c['_id'] == _selectedCategory)
                      ? _selectedCategory
                      : null,
                  decoration: const InputDecoration(labelText: 'اختر التصنيف'),
                  items: _categories.map<DropdownMenuItem<String>>((c) {
                    final name = c['name'] is Map ? c['name']['ar'] : c['name'];
                    return DropdownMenuItem(
                      value: c['_id'],
                      child: Text(name ?? 'بدون اسم'),
                    );
                  }).toList(),
                  onChanged: (v) => setState(() => _selectedCategory = v),
                  validator: (v) =>
                      !_isNewCategory && v == null ? 'مطلوب' : null,
                )
              else
                TextFormField(
                  controller: _newCategoryController,
                  decoration: const InputDecoration(
                    labelText: 'اسم التصنيف الجديد',
                  ),
                  validator: (v) =>
                      _isNewCategory && v!.isEmpty ? 'مطلوب' : null,
                ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _imageController,
                decoration: InputDecoration(
                  labelText: 'رابط الصورة',
                  suffixIcon: _isImageUploading
                      ? const Padding(
                          padding: EdgeInsets.all(12.0),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : IconButton(
                          icon: const Icon(
                            Icons.image,
                            color: AppColors.primary,
                          ),
                          onPressed: _pickMainImage,
                        ),
                ),
                validator: (v) => v!.isEmpty ? 'مطلوب' : null,
              ),
              if (_imageController.text.isNotEmpty) ...[
                const SizedBox(height: 15),
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey.shade50,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(
                      imageUrl: _imageController.text,
                      fit: BoxFit.contain,
                      placeholder: (context, url) =>
                          const Center(child: CircularProgressIndicator()),
                      errorWidget: (context, url, error) => const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.broken_image,
                              color: Colors.grey,
                              size: 40,
                            ),
                            Text(
                              "رابط غير صالح",
                              style: TextStyle(color: Colors.grey),
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
                  const Text(
                    'صور إضافية (Gallery)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    onPressed: _isImageUploading ? null : _pickGalleryImage,
                    icon: const Icon(Icons.add_photo_alternate),
                    color: AppColors.primary,
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
                              border: Border.all(color: Colors.grey.shade300),
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
                                backgroundColor: Colors.red,
                                child: Icon(
                                  Icons.close,
                                  size: 16,
                                  color: Colors.white,
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
                decoration: const InputDecoration(labelText: 'الوصف (عربي)'),
                maxLines: 3,
              ),
              const SizedBox(height: 10),
              SwitchListTile(
                title: const Text('نفذت الكمية (Sold Out)'),
                value: _isSoldOut,
                onChanged: (val) => setState(() => _isSoldOut = val),
              ),
              SwitchListTile(
                title: const Text('منتج مميز (Featured)'),
                subtitle: const Text('يظهر في الأقسام المميزة'),
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
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('حفظ', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

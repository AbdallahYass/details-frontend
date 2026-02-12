import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:details_app/constants/app_colors.dart';
import 'package:details_app/providers/auth_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';

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
  final _descArController = TextEditingController();
  final _descEnController = TextEditingController();
  final _imageController = TextEditingController();
  String? _selectedCategory;
  List<dynamic> _categories = [];
  bool _isLoading = false;
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    _imageController.addListener(() => setState(() {}));
    _fetchCategories();
    if (widget.product != null) {
      final p = widget.product;
      _nameArController.text = p['name']['ar'];
      _nameEnController.text = p['name']['en'];
      _priceController.text = p['price'].toString();
      _descArController.text = p['description']['ar'] ?? '';
      _descEnController.text = p['description']['en'] ?? '';
      _imageController.text = p['imageUrl'];
      _selectedCategory = p['category'] is Map
          ? p['category']['_id']
          : p['category'];
    }
  }

  @override
  void dispose() {
    _nameArController.dispose();
    _nameEnController.dispose();
    _priceController.dispose();
    _descArController.dispose();
    _descEnController.dispose();
    _imageController.dispose();
    super.dispose();
  }

  Future<void> _fetchCategories() async {
    try {
      final res = await http.get(
        Uri.parse('https://api.details-store.com/api/categories'),
      );
      if (res.statusCode == 200) {
        setState(() {
          _categories = json.decode(res.body);
          if (_selectedCategory == null && _categories.isNotEmpty) {
            _selectedCategory = _categories[0]['_id'];
          }
        });
      }
    } catch (e) {
      debugPrint('Error fetching categories: $e');
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
        // نضع مسار الملف في الحقل مؤقتاً لتجاوز التحقق من الفراغ
        _imageController.text = pickedFile.path;
      });
    }
  }

  Future<String> _uploadImage(File image) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final uri = Uri.parse('https://api.details-store.com/api/upload');
    final request = http.MultipartRequest('POST', uri);
    request.headers['Authorization'] = 'Bearer ${auth.token}';
    request.files.add(await http.MultipartFile.fromPath('image', image.path));

    final response = await request.send();
    if (response.statusCode == 200) {
      final respStr = await response.stream.bytesToString();
      final data = json.decode(respStr);
      return data['imageUrl'];
    } else {
      throw Exception('فشل رفع الصورة');
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

      // إذا تم اختيار صورة جديدة من الهاتف، نقوم برفعها أولاً
      if (_selectedImage != null) {
        finalImageUrl = await _uploadImage(_selectedImage!);
      }

      final request = http.Request(method, Uri.parse(url));
      request.headers.addAll({
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${auth.token}',
      });
      request.body = json.encode({
        'name': {'ar': _nameArController.text, 'en': _nameEnController.text},
        'price': double.parse(_priceController.text),
        'description': {
          'ar': _descArController.text,
          'en': _descEnController.text,
        },
        'imageUrl': finalImageUrl,
        'category': _selectedCategory,
        'images': [finalImageUrl], // Using main image as first image in gallery
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
                validator: (v) => v!.isEmpty ? 'مطلوب' : null,
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                // ignore: deprecated_member_use
                value:
                    _selectedCategory, // value is correct for DropdownButtonFormField, initialValue is for TextFormField
                decoration: const InputDecoration(labelText: 'التصنيف'),
                items: _categories.map<DropdownMenuItem<String>>((c) {
                  final name = c['name'] is Map ? c['name']['ar'] : c['name'];
                  return DropdownMenuItem(value: c['_id'], child: Text(name));
                }).toList(),
                onChanged: (v) => setState(() => _selectedCategory = v),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _imageController,
                decoration: InputDecoration(
                  labelText: 'رابط الصورة',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.image, color: AppColors.primary),
                    onPressed: _pickImage,
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
                    child:
                        _selectedImage != null &&
                            _imageController.text.isNotEmpty
                        ? Image.file(_selectedImage!, fit: BoxFit.contain)
                        : CachedNetworkImage(
                            imageUrl: _imageController.text,
                            fit: BoxFit.contain,
                            placeholder: (context, url) => const Center(
                              child: CircularProgressIndicator(),
                            ),
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
              const SizedBox(height: 10),
              TextFormField(
                controller: _descArController,
                decoration: const InputDecoration(labelText: 'الوصف (عربي)'),
                maxLines: 3,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoading ? null : _saveProduct,
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

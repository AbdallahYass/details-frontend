import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:details_app/app_imports.dart';
import 'package:details_app/widgets/custom_loading_overlay.dart';
import 'package:details_app/providers/notification_provider.dart';
import 'package:details_app/screens/home/notifications_screen.dart';

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
  final _brandController = TextEditingController();
  final _dimensionsController = TextEditingController();
  final _imageController = TextEditingController();
  final _newCategoryController = TextEditingController(); // للكاتيجوري الجديد
  final _sizeInputController = TextEditingController();
  final _sizeQtyController = TextEditingController();
  final _colorNameArController = TextEditingController();
  final _colorNameEnController = TextEditingController();
  final _colorHexController = TextEditingController();
  String? _selectedCategory;
  List<dynamic> _categories = [];
  List<String> _galleryImages = []; // قائمة الصور الإضافية
  List<ProductSize> _sizes = [];
  bool _isLoading = false;
  bool _isImageUploading = false;
  bool _isNewCategory = false; // تحديد وضع الكاتيجوري
  bool _isSoldOut = false;
  bool _isFeatured = false;
  List<ProductColor> _colors = [];

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
      if (p['sizes'] != null) {
        _sizes = (p['sizes'] as List)
            .map((e) => ProductSize.fromJson(e))
            .toList();
      }
      if (p['colors'] != null) {
        _colors = (p['colors'] as List)
            .map((e) => ProductColor.fromJson(e))
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
    _sizeQtyController.dispose();
    _colorNameArController.dispose();
    _colorNameEnController.dispose();
    _colorHexController.dispose();
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
        'brand': _brandController.text.isNotEmpty
            ? _brandController.text
            : 'DETAILS',
        'dimensions': _dimensionsController.text,
        'imageUrl': finalImageUrl,
        'category': categoryValue,
        'isSoldOut': _isSoldOut,
        'featured': _isFeatured,
        'images': allImages,
        'colors': _colors.map((e) => e.toJson()).toList(),
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
      } else {
        throw Exception('Failed to save');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.translate('error_occurred'),
            ),
            backgroundColor: AppColors.error,
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
                  TextFormField(
                    controller: _quantityController,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(
                        context,
                      )!.translate('quantity_available'),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v == null || v.isEmpty) {
                        return AppLocalizations.of(
                          context,
                        )!.translate('required_field');
                      }
                      if (int.tryParse(v) == null) {
                        return AppLocalizations.of(
                          context,
                        )!.translate('enter_valid_number');
                      }
                      return null;
                    },
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
                      SizedBox(
                        width: 80,
                        child: TextFormField(
                          controller: _sizeQtyController,
                          decoration: InputDecoration(
                            labelText: AppLocalizations.of(
                              context,
                            )!.translate('quantity'),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.add_circle,
                          color: AppColors.adminEdit,
                        ),
                        onPressed: () {
                          if (_sizeInputController.text.isNotEmpty) {
                            final qty =
                                int.tryParse(_sizeQtyController.text) ?? 0;
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
                          controller: _colorNameArController,
                          decoration: InputDecoration(
                            labelText: AppLocalizations.of(
                              context,
                            )!.translate('color_name_ar'),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: _colorNameEnController,
                          decoration: InputDecoration(
                            labelText: AppLocalizations.of(
                              context,
                            )!.translate('color_name_en'),
                          ),
                        ),
                      ),
                    ],
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
                            prefixIcon: const Icon(Icons.color_lens),
                          ),
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
                                  nameAr: _colorNameArController.text.trim(),
                                  nameEn: _colorNameEnController.text.trim(),
                                  hex: _colorHexController.text.trim(),
                                ),
                              );
                              _colorNameArController.clear();
                              _colorNameEnController.clear();
                              _colorHexController.clear();
                            });
                          }
                        },
                      ),
                    ],
                  ),
                  if (_colors.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Wrap(
                        spacing: 8,
                        children: _colors.map((c) {
                          return Chip(
                            avatar: CircleAvatar(
                              backgroundColor: Color(
                                int.tryParse(c.hex.replaceFirst('#', '0xFF')) ??
                                    0xFF000000,
                              ),
                            ),
                            label: Text(c.getName(context)),
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
                      // ignore: deprecated_member_use
                      // التأكد من أن القيمة المختارة موجودة في القائمة لتجنب الكراش
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

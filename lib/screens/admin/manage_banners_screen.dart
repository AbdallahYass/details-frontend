import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:details_app/constants/app_colors.dart';
import 'package:details_app/providers/auth_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:details_app/screens/home/cloudinary_service.dart';
import 'package:details_app/widgets/custom_loading_overlay.dart';

class ManageBannersScreen extends StatefulWidget {
  const ManageBannersScreen({super.key});

  @override
  State<ManageBannersScreen> createState() => _ManageBannersScreenState();
}

class _ManageBannersScreenState extends State<ManageBannersScreen> {
  List<dynamic> _banners = [];
  List<dynamic> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchBanners();
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    try {
      final response = await http.get(
        Uri.parse('https://api.details-store.com/api/categories'),
      );
      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            _categories = json.decode(response.body);
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching categories: $e');
    }
  }

  Future<void> _fetchBanners() async {
    try {
      final response = await http.get(
        Uri.parse('https://api.details-store.com/api/banners'),
      );
      if (!mounted) return;
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _banners = data is List ? data : [];
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _addBanner(
    String titleAr,
    String titleEn,
    String imageUrl,
    String? categoryId,
  ) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    try {
      final response = await http.post(
        Uri.parse('https://api.details-store.com/api/banners'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${auth.token}',
        },
        body: json.encode({
          'title': {'ar': titleAr, 'en': titleEn},
          'imageUrl': imageUrl,
          'location': 'home', // افتراضياً للصفحة الرئيسية
          'isActive': true,
          if (categoryId != null) 'category': categoryId,
        }),
      );

      if (response.statusCode == 201) {
        _fetchBanners();
        if (mounted) Navigator.pop(context);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم إضافة الإعلان بنجاح')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('فشل إضافة الإعلان')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('فشل إضافة الإعلان')));
      }
    }
  }

  Future<void> _deleteBanner(String id) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    setState(() => _isLoading = true);
    try {
      await http.delete(
        Uri.parse('https://api.details-store.com/api/banners/$id'),
        headers: {'Authorization': 'Bearer ${auth.token}'},
      );
      setState(() {
        _banners.removeWhere((b) => b['_id'] == id);
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('تم حذف الإعلان بنجاح')));
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('فشل حذف الإعلان')));
      }
    }
  }

  void _showAddDialog() {
    final titleArController = TextEditingController();
    final titleEnController = TextEditingController();
    final imageController = TextEditingController();
    String? selectedCategory;

    showDialog(
      context: context,
      builder: (ctx) {
        bool isUploading = false;
        return StatefulBuilder(
          builder: (context, setState) {
            Future<void> pickImage() async {
              setState(() => isUploading = true);
              final url = await CloudinaryService().pickAndUploadImage();
              setState(() => isUploading = false);
              if (url != null) {
                imageController.text = url;
              }
            }

            return Stack(
              children: [
                AlertDialog(
                  title: const Text('إضافة إعلان جديد'),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: titleArController,
                          decoration: const InputDecoration(
                            labelText: 'العنوان (عربي)',
                          ),
                        ),
                        TextField(
                          controller: titleEnController,
                          decoration: const InputDecoration(
                            labelText: 'العنوان (إنجليزي)',
                          ),
                        ),
                        TextField(
                          controller: imageController,
                          decoration: InputDecoration(
                            labelText: 'رابط الصورة',
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.cloud_upload),
                              onPressed: isUploading ? null : pickImage,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (_categories.isNotEmpty)
                          DropdownButtonFormField<String>(
                            initialValue: selectedCategory,
                            decoration: const InputDecoration(
                              labelText: 'ربط بقسم (اختياري)',
                              border: OutlineInputBorder(),
                            ),
                            items: _categories.map<DropdownMenuItem<String>>((
                              c,
                            ) {
                              final name = c['name'] is Map
                                  ? c['name']['ar']
                                  : c['name'];
                              return DropdownMenuItem(
                                value: c['_id'],
                                child: Text(name ?? ''),
                              );
                            }).toList(),
                            onChanged: (v) =>
                                setState(() => selectedCategory = v),
                          ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: isUploading ? null : () => Navigator.pop(ctx),
                      child: const Text('إلغاء'),
                    ),
                    ElevatedButton(
                      onPressed: isUploading
                          ? null
                          : () => _addBanner(
                              titleArController.text,
                              titleEnController.text,
                              imageController.text,
                              selectedCategory,
                            ),
                      child: const Text('إضافة'),
                    ),
                  ],
                ),
                if (isUploading) const CustomLoadingOverlay(isOverlay: true),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة الإعلانات'),
        backgroundColor: AppColors.appBarBackground,
        foregroundColor: AppColors.appBarForeground,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _fetchBanners,
            child: _banners.isEmpty
                ? ListView(
                    children: const [
                      SizedBox(height: 200),
                      Center(child: Text('لا يوجد إعلانات حالياً')),
                    ],
                  )
                : ListView.builder(
                    itemCount: _banners.length,
                    itemBuilder: (ctx, i) {
                      final banner = _banners[i];
                      return Card(
                        margin: const EdgeInsets.all(10),
                        child: Column(
                          children: [
                            AspectRatio(
                              aspectRatio: 16 / 9,
                              child: CachedNetworkImage(
                                imageUrl: banner['imageUrl'] ?? '',
                                fit: BoxFit.cover,
                                placeholder: (context, url) =>
                                    Container(color: Colors.grey[200]),
                                errorWidget: (context, url, error) =>
                                    const Icon(Icons.error),
                              ),
                            ),
                            ListTile(
                              title: Text(
                                banner['title'] is Map
                                    ? (banner['title']['ar'] ?? 'إعلان')
                                    : 'إعلان',
                              ),
                              subtitle: Text(
                                'الموقع: ${banner['location'] ?? 'home'}',
                              ),
                              trailing: IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: AppColors.adminDelete,
                                ),
                                onPressed: () => _deleteBanner(banner['_id']),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          if (_isLoading) const CustomLoadingOverlay(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        backgroundColor: AppColors.adminAdd,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

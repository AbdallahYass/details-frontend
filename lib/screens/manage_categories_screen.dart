import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:details_app/constants/app_colors.dart';
import 'package:details_app/providers/auth_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ManageCategoriesScreen extends StatefulWidget {
  const ManageCategoriesScreen({super.key});

  @override
  State<ManageCategoriesScreen> createState() => _ManageCategoriesScreenState();
}

class _ManageCategoriesScreenState extends State<ManageCategoriesScreen> {
  List<dynamic> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    try {
      final response = await http.get(
        Uri.parse('https://api.details-store.com/api/categories'),
      );
      if (response.statusCode == 200) {
        setState(() {
          _categories = json.decode(response.body);
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addCategory(
    String nameAr,
    String nameEn,
    String imageUrl,
  ) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    try {
      final response = await http.post(
        Uri.parse('https://api.details-store.com/api/categories'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${auth.token}',
        },
        body: json.encode({
          'name': {'ar': nameAr, 'en': nameEn},
          'slug': nameEn.toLowerCase().replaceAll(' ', '-'),
          'imageUrl': imageUrl,
        }),
      );
      if (response.statusCode == 201) {
        _fetchCategories();
        if (mounted) Navigator.pop(context);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم إضافة التصنيف بنجاح')),
          );
        }
      }
    } catch (e) {
      debugPrint('Error adding category: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('فشل إضافة التصنيف')));
      }
    }
  }

  Future<void> _deleteCategory(String id) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    try {
      await http.delete(
        Uri.parse('https://api.details-store.com/api/categories/$id'),
        headers: {'Authorization': 'Bearer ${auth.token}'},
      );
      setState(() {
        _categories.removeWhere((cat) => cat['_id'] == id);
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('تم حذف التصنيف بنجاح')));
      }
    } catch (e) {
      debugPrint('Error deleting category: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('فشل حذف التصنيف')));
      }
    }
  }

  void _showAddDialog() {
    final nameArController = TextEditingController();
    final nameEnController = TextEditingController();
    final imageController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إضافة تصنيف جديد'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameArController,
              decoration: const InputDecoration(labelText: 'الاسم (عربي)'),
            ),
            TextField(
              controller: nameEnController,
              decoration: const InputDecoration(labelText: 'الاسم (إنجليزي)'),
            ),
            TextField(
              controller: imageController,
              decoration: const InputDecoration(labelText: 'رابط الصورة'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => _addCategory(
              nameArController.text,
              nameEnController.text,
              imageController.text,
            ),
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إدارة التصنيفات')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _categories.length,
              itemBuilder: (ctx, i) {
                final cat = _categories[i];
                final name = cat['name'] is Map
                    ? cat['name']['ar']
                    : cat['name'];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  child: ListTile(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: cat['imageUrl'],
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        errorWidget: (c, u, e) => const Icon(Icons.error),
                      ),
                    ),
                    title: Text(name ?? ''),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteCategory(cat['_id']),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

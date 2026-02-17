import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:details_app/constants/app_colors.dart';
import 'package:details_app/providers/auth_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ManageProductsScreen extends StatefulWidget {
  const ManageProductsScreen({super.key});

  @override
  State<ManageProductsScreen> createState() => _ManageProductsScreenState();
}

class _ManageProductsScreenState extends State<ManageProductsScreen> {
  List<dynamic> _products = [];
  bool _isLoading = true;
  String _searchQuery = '';
  List<dynamic> _filteredProducts = [];

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    try {
      final response = await http.get(
        Uri.parse('https://api.details-store.com/api/products'),
      );
      if (response.statusCode == 200) {
        setState(() {
          _products = json.decode(response.body);
          _filteredProducts = _products;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteProduct(String id) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    try {
      await http.delete(
        Uri.parse('https://api.details-store.com/api/products/$id'),
        headers: {'Authorization': 'Bearer ${auth.token}'},
      );
      setState(() {
        _products.removeWhere((p) => p['_id'] == id);
        _filterProducts(_searchQuery);
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('تم حذف المنتج بنجاح')));
      }
    } catch (e) {
      debugPrint('Error deleting product: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('فشل حذف المنتج')));
      }
    }
  }

  void _filterProducts(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredProducts = _products;
      } else {
        _filteredProducts = _products.where((product) {
          final nameAr = product['name'] is Map ? product['name']['ar'] : '';
          final nameEn = product['name'] is Map ? product['name']['en'] : '';
          return nameAr.contains(query) || nameEn.contains(query);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: TextField(
          decoration: const InputDecoration(
            hintText: 'بحث عن منتج...',
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.white70),
          ),
          style: const TextStyle(color: Colors.white),
          onChanged: _filterProducts,
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _filteredProducts.length,
              itemBuilder: (ctx, i) {
                final product = _filteredProducts[i];
                final name = product['name'] is Map
                    ? product['name']['ar']
                    : product['name'];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  child: ListTile(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: product['imageUrl'] ?? '',
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        errorWidget: (c, u, e) => const Icon(Icons.error),
                      ),
                    ),
                    title: Text(name ?? ''),
                    subtitle: Text('\$${product['price']}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => context.push(
                            '/admin/products/edit',
                            extra: product,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteProduct(product['_id']),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/admin/products/add'),
        backgroundColor: AppColors.black,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

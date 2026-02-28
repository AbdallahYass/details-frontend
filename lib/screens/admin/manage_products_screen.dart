// ignore_for_file: deprecated_member_use

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:details_app/constants/app_colors.dart';
import 'package:details_app/providers/auth_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:details_app/widgets/custom_loading_overlay.dart';
import 'package:details_app/providers/notification_provider.dart';
import 'package:details_app/screens/home/notifications_screen.dart';

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
    setState(() => _isLoading = true);
    try {
      await http.delete(
        Uri.parse('https://api.details-store.com/api/products/$id'),
        headers: {'Authorization': 'Bearer ${auth.token}'},
      );
      setState(() {
        _products.removeWhere((p) => p['_id'] == id);
        _filterProducts(_searchQuery);
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('تم حذف المنتج بنجاح')));
      }
    } catch (e) {
      debugPrint('Error deleting product: $e');
      setState(() => _isLoading = false);
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
        backgroundColor: AppColors.appBarBackground,
        foregroundColor: AppColors.appBarForeground,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        title: TextField(
          decoration: InputDecoration(
            hintText: 'بحث عن منتج...',
            border: InputBorder.none,
            hintStyle: TextStyle(
              color: AppColors.appBarForeground.withOpacity(0.7),
            ),
          ),
          style: const TextStyle(color: AppColors.appBarForeground),
          onChanged: _filterProducts,
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
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '${notifProvider.unreadCount}',
                          style: const TextStyle(
                            color: Colors.white,
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
      body: Stack(
        children: [
          ListView.builder(
            itemCount: _filteredProducts.length,
            itemBuilder: (ctx, i) {
              final product = _filteredProducts[i];
              final name = product['name'] is Map
                  ? product['name']['ar']
                  : product['name'];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
                        icon: const Icon(
                          Icons.edit,
                          color: AppColors.adminEdit,
                        ),
                        onPressed: () => context.push(
                          '/admin/products/edit',
                          extra: product,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete,
                          color: AppColors.adminDelete,
                        ),
                        onPressed: () => _deleteProduct(product['_id']),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          if (_isLoading) const CustomLoadingOverlay(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/admin/products/add'),
        backgroundColor: AppColors.adminAdd,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

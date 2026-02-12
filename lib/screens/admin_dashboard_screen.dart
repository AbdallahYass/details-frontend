import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:details_app/constants/app_colors.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة التحكم'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.store),
            tooltip: 'الذهاب للمتجر',
            onPressed: () => context.go('/'),
          ),
        ],
      ),
      body: GridView.count(
        padding: const EdgeInsets.all(20),
        crossAxisCount: 2,
        crossAxisSpacing: 15,
        mainAxisSpacing: 15,
        children: [
          _buildAdminCard(
            context,
            'المنتجات',
            Icons.shopping_bag,
            Colors.blue,
            '/admin/products',
          ),
          _buildAdminCard(
            context,
            'الطلبات',
            Icons.list_alt,
            Colors.orange,
            '/admin/orders',
          ),
          _buildAdminCard(
            context,
            'الكوبونات',
            Icons.local_offer,
            Colors.green,
            '/admin/coupons',
          ),
          _buildAdminCard(
            context,
            'الإعلانات',
            Icons.image,
            Colors.purple,
            '/admin/banners',
          ),
          _buildAdminCard(
            context,
            'التصنيفات',
            Icons.category,
            Colors.teal,
            '/admin/categories',
          ),
          _buildAdminCard(
            context,
            'المستخدمين',
            Icons.people,
            Colors.redAccent,
            '/admin/users',
          ),
        ],
      ),
    );
  }

  Widget _buildAdminCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    String route,
  ) {
    return InkWell(
      onTap: () => context.push(route),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 32, color: color),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

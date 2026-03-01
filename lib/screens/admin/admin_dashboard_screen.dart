// ignore_for_file: deprecated_member_use

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:details_app/constants/app_colors.dart';
import 'package:provider/provider.dart';
import 'package:details_app/providers/auth_provider.dart';
import 'package:http/http.dart' as http;
import 'package:details_app/l10n/app_localizations.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  Map<String, dynamic> _stats = {
    'productsCount': 0,
    'ordersCount': 0,
    'usersCount': 0,
    'totalSales': 0,
  };
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    try {
      final response = await http.get(
        Uri.parse('https://api.details-store.com/api/admin/stats'),
        headers: {'Authorization': 'Bearer ${auth.token}'},
      );
      if (response.statusCode == 200) {
        setState(() {
          _stats = json.decode(response.body);
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Error fetching stats: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.user;

    return Scaffold(
      backgroundColor: AppColors.adminBackground,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.translate('dashboard_title'),
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: true,
        backgroundColor: AppColors.appBarBackground,
        foregroundColor: AppColors.appBarForeground,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.store_rounded,
              color: AppColors.appBarForeground,
            ),
            tooltip: AppLocalizations.of(context)!.translate('go_to_store'),
            onPressed: () => context.go('/'),
          ),
        ],
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ترويسة ترحيبية
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 10, 24, 40),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: AppColors.white.withValues(
                          alpha: 0.24,
                        ),
                        child: Text(
                          user?.name[0].toUpperCase() ?? 'A',
                          style: const TextStyle(
                            color: AppColors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 24,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${AppLocalizations.of(context)!.translate('welcome_user')} ${user?.name ?? "Admin"} 👋',
                            style: const TextStyle(
                              color: AppColors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            AppLocalizations.of(
                              context,
                            )!.translate('dashboard_subtitle'),
                            style: TextStyle(
                              color: AppColors.white.withValues(alpha: 0.7),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // عرض الإحصائيات
                  if (_isLoading)
                    const Center(
                      child: CircularProgressIndicator(color: AppColors.white),
                    )
                  else
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem(
                          AppLocalizations.of(context)!.translate('sales'),
                          '${_stats['totalSales']} ${AppLocalizations.of(context)!.translate('currency')}',
                          Icons.monetization_on,
                        ),
                        _buildStatItem(
                          AppLocalizations.of(context)!.translate('orders'),
                          '${_stats['ordersCount']}',
                          Icons.shopping_cart,
                        ),
                        _buildStatItem(
                          AppLocalizations.of(context)!.translate('products'),
                          '${_stats['productsCount']}',
                          Icons.inventory,
                        ),
                        _buildStatItem(
                          AppLocalizations.of(context)!.translate('users'),
                          '${_stats['usersCount']}',
                          Icons.people,
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          // شبكة البطاقات
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            sliver: SliverGrid.count(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.0,
              children: [
                _buildAdminCard(
                  context,
                  AppLocalizations.of(context)!.translate('products'),
                  Icons.inventory_2_outlined,
                  AppColors.adminDashProducts,
                  '/admin/products',
                  AppLocalizations.of(context)!.translate('manage_inventory'),
                ),
                _buildAdminCard(
                  context,
                  AppLocalizations.of(context)!.translate('orders'),
                  Icons.shopping_cart_checkout_outlined,
                  AppColors.adminDashOrders,
                  '/admin/orders',
                  AppLocalizations.of(context)!.translate('track_orders'),
                ),
                _buildAdminCard(
                  context,
                  AppLocalizations.of(context)!.translate('coupons'),
                  Icons.discount_outlined,
                  AppColors.adminDashCoupons,
                  '/admin/coupons',
                  AppLocalizations.of(context)!.translate('discount_codes'),
                ),
                _buildAdminCard(
                  context,
                  AppLocalizations.of(context)!.translate('banners'),
                  Icons.campaign_outlined,
                  AppColors.adminDashBanners,
                  '/admin/banners',
                  AppLocalizations.of(context)!.translate('app_banners'),
                ),
                _buildAdminCard(
                  context,
                  AppLocalizations.of(context)!.translate('categories'),
                  Icons.category_outlined,
                  AppColors.adminDashCategories,
                  '/admin/categories',
                  AppLocalizations.of(context)!.translate('store_sections'),
                ),
                _buildAdminCard(
                  context,
                  AppLocalizations.of(context)!.translate('users'),
                  Icons.group_outlined,
                  AppColors.adminDashUsers,
                  '/admin/users',
                  AppLocalizations.of(context)!.translate('manage_customers'),
                ),
              ],
            ),
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
    String subtitle,
  ) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(24),
      elevation: 0,
      child: InkWell(
        onTap: () => context.push(route),
        borderRadius: BorderRadius.circular(24),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withValues(alpha: 0.03),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, size: 28, color: color),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: AppColors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.grey500,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.white.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.white, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: AppColors.white.withValues(alpha: 0.7),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

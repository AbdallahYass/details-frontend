import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:details_app/app_imports.dart';
import 'package:details_app/widgets/custom_loading_overlay.dart';
import 'package:details_app/providers/notification_provider.dart';
import 'package:details_app/screens/home/notifications_screen.dart';

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  List<dynamic> _orders = [];
  bool _isLoading = true;
  final List<String> _orderStatuses = [
    'قيد التجهيز',
    'تم الشحن',
    'تم التوصيل',
    'ملغي',
  ];

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    try {
      final response = await http.get(
        Uri.parse('https://api.details-store.com/api/admin/orders'),
        headers: {'Authorization': 'Bearer ${auth.token}'},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _orders = data is List ? data : [];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateStatus(String id, String newStatus) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);

    // تحديث محلي فوري لتحسين تجربة المستخدم
    setState(() {
      final index = _orders.indexWhere((o) => o['_id'] == id);
      if (index != -1) _orders[index]['status'] = newStatus;
    });

    try {
      await http.put(
        Uri.parse('https://api.details-store.com/api/admin/orders/$id/status'),
        headers: {
          'Authorization': 'Bearer ${auth.token}',
          'Content-Type': 'application/json',
        },
        body: json.encode({'status': newStatus}),
      );
      // لا داعي لإعادة تحميل الطلبات بالكامل إذا نجح الطلب
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.translate('order_status_updated'),
            ),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error updating status: $e');
      _fetchOrders(); // إعادة التحميل في حالة الخطأ فقط للتصحيح
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(
                context,
              )!.translate('order_status_update_failed'),
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 110,
        title: Image.asset('assets/images/logo2.png', height: 100),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.appBarForeground,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.white,
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
      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        height: 70,
        decoration: BoxDecoration(
          color: AppColors.homeNavBackground,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
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
      body: _isLoading
          ? const CustomLoadingOverlay(isOverlay: false)
          : RefreshIndicator(
              onRefresh: _fetchOrders,
              child: ListView.builder(
                itemCount: _orders.length,
                itemBuilder: (ctx, i) {
                  final order = _orders[i];
                  final orderId = order['_id'].toString();
                  final user = order['user'];
                  final items = order['products'] as List<dynamic>? ?? [];
                  final shipping = order['shippingAddress'];

                  return Card(
                    color: AppColors.adminSurface,
                    margin: const EdgeInsets.all(10),
                    child: ExpansionTile(
                      title: Text(
                        '${AppLocalizations.of(context)!.translate('order_number')}${orderId.length > 8 ? orderId.substring(0, 8) : orderId}',
                      ),
                      subtitle: Text(
                        '${order['amount']} - ${order['status']}',
                        style: TextStyle(
                          color: order['status'] == 'تم التوصيل'
                              ? AppColors
                                    .adminDashCoupons // أخضر
                              : AppColors.adminDashOrders, // برتقالي
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      children: [
                        ListTile(
                          leading: const Icon(
                            Icons.edit_attributes,
                            color: AppColors.adminEdit,
                          ),
                          title: Text(
                            AppLocalizations.of(
                              context,
                            )!.translate('change_status'),
                          ),
                          trailing: DropdownButton<String>(
                            value: _orderStatuses.contains(order['status'])
                                ? order['status']
                                : null,
                            items: _orderStatuses
                                .map(
                                  (s) => DropdownMenuItem(
                                    value: s,
                                    child: Text(s),
                                  ),
                                )
                                .toList(),
                            onChanged: (val) {
                              if (val != null) _updateStatus(orderId, val);
                            },
                          ),
                        ),
                        const Divider(),
                        if (user != null || shipping != null)
                          Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppLocalizations.of(
                                    context,
                                  )!.translate('customer_info'),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                if (user != null && user['name'] != null)
                                  Text(
                                    '👤 ${AppLocalizations.of(context)!.translate('name')} ${user['name']}',
                                  ),
                                if (shipping != null &&
                                    shipping['phone'] != null)
                                  Text('📞 الهاتف: ${shipping['phone']}'),
                                if (shipping != null)
                                  Text(
                                    '📍 ${AppLocalizations.of(context)!.translate('address')} ${shipping['city'] ?? ''} - ${shipping['street'] ?? ''}',
                                  ),
                              ],
                            ),
                          ),
                        if (items.isNotEmpty) ...[
                          const Divider(),
                          Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppLocalizations.of(
                                    context,
                                  )!.translate('products'),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                ...items.map((item) {
                                  final productName =
                                      item['title'] ??
                                      AppLocalizations.of(
                                        context,
                                      )!.translate('unknown_product');
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 4,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            '- $productName (x${item['quantity']})',
                                          ),
                                        ),
                                        Text(
                                          '${item['price']} ₪',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.adminDashProducts,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
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
          color: Colors.transparent,
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

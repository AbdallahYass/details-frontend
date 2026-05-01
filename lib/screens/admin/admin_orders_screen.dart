import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:details_app/app_imports.dart';
import 'package:details_app/providers/notification_provider.dart';
import 'package:details_app/screens/home/notifications_screen.dart';

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen>
    with SingleTickerProviderStateMixin {
  List<dynamic> _orders = [];
  String _getStatusTranslation(String status, AppLocalizations loc) {
    switch (status) {
      case 'قيد التجهيز':
        return loc.translate('status_processing');
      case 'تم الشحن':
        return loc.translate('status_shipped');
      case 'تم التوصيل':
        return loc.translate('status_delivered');
      case 'ملغي':
        return loc.translate('status_cancelled');
      default:
        return status;
    }
  }

  Color _parseColor(String? hex) {
    if (hex == null || hex.isEmpty) return Colors.transparent;
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return Colors.transparent;
    }
  }

  final List<String> _orderStatuses = [
    'قيد التجهيز',
    'تم الشحن',
    'تم التوصيل',
    'ملغي',
  ];

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _orderStatuses.length, vsync: this);
    _fetchOrders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
        });
      }
    } catch (e) {
      debugPrint('Error fetching admin orders: $e');
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
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.appBarForeground,
        scrolledUnderElevation: 0,
        surfaceTintColor: AppColors.white,
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
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: _orderStatuses.map((status) {
            return Tab(
              text: _getStatusTranslation(
                status,
                AppLocalizations.of(context)!,
              ),
            );
          }).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _orderStatuses.map((status) {
          final filteredOrders = _orders
              .where((order) => order['status'] == status)
              .toList();
          return filteredOrders.isEmpty
              ? Center(
                  child: Text(
                    AppLocalizations.of(context)!.translate('no_orders_found'),
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchOrders,
                  child: ListView.builder(
                    itemCount: filteredOrders.length,
                    itemBuilder: (ctx, i) {
                      final order = filteredOrders[i];
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
                          subtitle: Builder(
                            builder: (context) {
                              final loc = AppLocalizations.of(context)!;
                              return Text(
                                '${order['amount']} - ${_getStatusTranslation(order['status'], loc)}',
                                style: TextStyle(
                                  color: order['status'] == 'تم التوصيل'
                                      ? AppColors
                                            .adminDashCoupons // أخضر
                                      : AppColors.adminDashOrders, // برتقالي
                                  fontWeight: FontWeight.bold,
                                ),
                              );
                            },
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
                                items: _orderStatuses.map((s) {
                                  return DropdownMenuItem(
                                    value: s,
                                    child: Text(
                                      _getStatusTranslation(
                                        s,
                                        AppLocalizations.of(context)!,
                                      ),
                                    ),
                                  );
                                }).toList(),
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
                                      Text(
                                        '📞 ${AppLocalizations.of(context)!.translate('phone_label')}: ${shipping['phone']}',
                                      ),
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
                                          item['title']
                                              ?.toString()
                                              .split('(')
                                              .first
                                              .trim() ??
                                          AppLocalizations.of(
                                            context,
                                          )!.translate('unknown_product');

                                      final size = item['size']?.toString();
                                      final colorHex = item['color']
                                          ?.toString();
                                      final imageUrl = item['imageUrl']
                                          ?.toString();
                                      final price = item['price'];
                                      final qty = item['quantity'];

                                      return Container(
                                        margin: const EdgeInsets.symmetric(
                                          vertical: 8,
                                        ),
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          border: Border.all(
                                            color: Colors.grey.shade200,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(
                                                alpha: 0.02,
                                              ),
                                              blurRadius: 5,
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          children: [
                                            // صورة المنتج
                                            ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              child: CachedNetworkImage(
                                                imageUrl: imageUrl ?? '',
                                                width: 60,
                                                height: 60,
                                                fit: BoxFit.cover,
                                                placeholder: (context, url) =>
                                                    Container(
                                                      color:
                                                          Colors.grey.shade100,
                                                    ),
                                                errorWidget:
                                                    (
                                                      context,
                                                      url,
                                                      error,
                                                    ) => const Icon(
                                                      Icons
                                                          .image_not_supported_outlined,
                                                      size: 30,
                                                    ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            // تفاصيل الاسم والمقاس واللون
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    productName,
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 14,
                                                    ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                  const SizedBox(height: 6),
                                                  Row(
                                                    children: [
                                                      if (size != null &&
                                                          size.isNotEmpty) ...[
                                                        Container(
                                                          padding:
                                                              const EdgeInsets.symmetric(
                                                                horizontal: 8,
                                                                vertical: 2,
                                                              ),
                                                          decoration: BoxDecoration(
                                                            color: AppColors
                                                                .primary
                                                                .withValues(
                                                                  alpha: 0.05,
                                                                ),
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  4,
                                                                ),
                                                            border: Border.all(
                                                              color: AppColors
                                                                  .primary
                                                                  .withValues(
                                                                    alpha: 0.1,
                                                                  ),
                                                            ),
                                                          ),
                                                          child: Text(
                                                            size,
                                                            style:
                                                                const TextStyle(
                                                                  fontSize: 11,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  color: AppColors
                                                                      .primary,
                                                                ),
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                          width: 10,
                                                        ),
                                                      ],
                                                      if (colorHex != null &&
                                                          colorHex.isNotEmpty)
                                                        Container(
                                                          width: 18,
                                                          height: 18,
                                                          decoration:
                                                              BoxDecoration(
                                                                color:
                                                                    _parseColor(
                                                                      colorHex,
                                                                    ),
                                                                shape: BoxShape
                                                                    .circle,
                                                                border: Border.all(
                                                                  color: Colors
                                                                      .black12,
                                                                  width: 1,
                                                                ),
                                                              ),
                                                        ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                            // السعر والكمية
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.end,
                                              children: [
                                                Text(
                                                  '$price ${AppLocalizations.of(context)!.translate('currency')}',
                                                  style: const TextStyle(
                                                    color: AppColors.primary,
                                                    fontWeight: FontWeight.w900,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                                Text(
                                                  'x$qty',
                                                  style: const TextStyle(
                                                    color: Colors.grey,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
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
                );
        }).toList(),
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

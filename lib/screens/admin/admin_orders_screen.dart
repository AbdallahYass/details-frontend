// ignore_for_file: deprecated_member_use

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:details_app/app_imports.dart';
import 'package:details_app/providers/notification_provider.dart';
import 'package:details_app/screens/home/notifications_screen.dart';
import 'package:details_app/widgets/custom_loading_overlay.dart';

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen>
    with TickerProviderStateMixin {
  List<dynamic> _orders = [];
  bool _isLoading = false;
  late TabController _tabController;

  final List<String> _orderStatuses = [
    'قيد التجهيز',
    'تم الشحن',
    'تم التوصيل',
    'ملغي',
  ];

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

  Color _getStatusColor(String status) {
    switch (status) {
      case 'قيد التجهيز':
        return AppColors.warning;
      case 'تم الشحن':
        return AppColors.blue;
      case 'تم التوصيل':
        return AppColors.success;
      case 'ملغي':
        return AppColors.red;
      default:
        return AppColors.grey;
    }
  }

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

  Future<void> _fetchOrders() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    final auth = Provider.of<AuthProvider>(context, listen: false);
    try {
      final response = await http.get(
        Uri.parse('https://api.details-store.com/api/admin/orders'),
        headers: {'Authorization': 'Bearer ${auth.token}'},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          setState(() {
            _orders = data is List ? data : [];
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching admin orders: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateStatus(String id, String newStatus) async {
    final ordersProvider = Provider.of<OrdersProvider>(context, listen: false);

    // Optimistic UI update
    setState(() {
      final index = _orders.indexWhere((o) => o['_id'] == id);
      if (index != -1) _orders[index]['status'] = newStatus;
    });

    try {
      // Use central provider for status updates (PATCH request)
      await ordersProvider.updateOrderStatus(id, newStatus);

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
      body: Stack(
        children: [
          TabBarView(
            controller: _tabController,
            children: _orderStatuses.map((status) {
              final filteredOrders = _orders
                  .where((order) => order['status'] == status)
                  .toList()
                  .reversed
                  .toList(); // عرض الأحدث أولاً
              return filteredOrders.isEmpty && !_isLoading
                  ? Center(
                      child: Text(
                        AppLocalizations.of(
                          context,
                        )!.translate('no_orders_found'),
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
                          final items =
                              order['products'] as List<dynamic>? ?? [];
                          final shipping = order['shippingAddress'];
                          final createdAt = order['createdAt'] != null
                              ? DateFormat(
                                  'yyyy/MM/dd HH:mm',
                                ).format(DateTime.parse(order['createdAt']))
                              : '';

                          return Card(
                            color: Colors.white,
                            elevation: 0,
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(color: Colors.grey.shade200),
                            ),
                            child: ExpansionTile(
                              shape: const RoundedRectangleBorder(
                                side: BorderSide.none,
                              ),
                              title: Text(
                                '${AppLocalizations.of(context)!.translate('order_number')} ${orderId.substring(orderId.length - 6)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    createdAt,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      _buildStatusChip(order['status']),
                                      const SizedBox(width: 8),
                                      Text(
                                        '${order['amount']} ${AppLocalizations.of(context)!.translate('currency')}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w900,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                      if (order['withGiftBox'] == true)
                                        _buildAddon(
                                          Icons.card_giftcard,
                                          AppLocalizations.of(
                                            context,
                                          )!.translate('with_box'),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  color: Colors.grey.shade50,
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        AppLocalizations.of(
                                          context,
                                        )!.translate('change_status'),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                      DropdownButtonHideUnderline(
                                        child: DropdownButton<String>(
                                          value:
                                              _orderStatuses.contains(
                                                order['status'],
                                              )
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
                                            if (val != null) {
                                              _updateStatus(orderId, val);
                                            }
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                _buildCustomerInfo(user, shipping),
                                _buildOrderNotes(order['notes']),
                                _buildProductList(items),
                              ],
                            ),
                          );
                        },
                      ),
                    );
            }).toList(),
          ),
          if (_isLoading) const CustomLoadingOverlay(),
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
    );
  }

  Widget _buildStatusChip(String status) {
    final color = _getStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        _getStatusTranslation(status, AppLocalizations.of(context)!),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildCustomerInfo(dynamic user, dynamic shipping) {
    if (user == null && shipping == null) return const SizedBox.shrink();
    final loc = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            loc.translate('customer_info'),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          _buildInfoRow(
            Icons.person_outline,
            loc.translate('name'),
            user?['name'] ?? shipping?['name'] ?? '',
          ),
          _buildInfoRow(
            Icons.phone_outlined,
            loc.translate('phone_label'),
            shipping?['phone'] ?? '',
          ),
          _buildInfoRow(
            Icons.location_on_outlined,
            loc.translate('address'),
            '${shipping?['city'] ?? ''} - ${shipping?['street'] ?? ''}',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    if (value.isEmpty || value.contains('null')) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderNotes(dynamic notes) {
    if (notes == null || notes.toString().isEmpty) {
      return const SizedBox.shrink();
    }
    final loc = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.amber.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.amber.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '📝 ${loc.translate('order_notes')}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.brown,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              notes.toString(),
              style: const TextStyle(fontSize: 13, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductList(List<dynamic> items) {
    if (items.isEmpty) return const SizedBox.shrink();
    final loc = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                loc.translate('products'),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 5),
              ...items.map((item) => _buildProductItem(item)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProductItem(dynamic item) {
    final loc = AppLocalizations.of(context)!;
    final productName =
        item['title']?.toString().split('(').first.trim() ??
        loc.translate('unknown_product');
    final imageUrl = item['imageUrl']?.toString();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              if (imageUrl != null && imageUrl.isNotEmpty) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => Scaffold(
                      backgroundColor: Colors.black,
                      appBar: AppBar(
                        backgroundColor: Colors.black,
                        iconTheme: const IconThemeData(color: Colors.white),
                      ),
                      body: Center(
                        child: InteractiveViewer(
                          child: CachedNetworkImage(
                            imageUrl: imageUrl,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: imageUrl ?? '',
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                errorWidget: (context, url, error) =>
                    const Icon(Icons.image_not_supported_outlined, size: 30),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  productName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    if (item['size'] != null) _buildBadge(item['size']),
                    if (item['color'] != null) ...[
                      const SizedBox(width: 10),
                      Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: _parseColor(item['color']),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.black12),
                        ),
                      ),
                    ],
                  ],
                ),
                if (item['withBox'] == true)
                  _buildAddon(Icons.card_giftcard, loc.translate('with_box')),
                if (item['withOriginalBox'] == true)
                  _buildAddon(
                    Icons.inventory_2_outlined,
                    loc.translate('with_original_box'),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${item['price']} ${loc.translate('currency')}',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
              ),
              Text(
                'x${item['quantity']}',
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
  }

  Widget _buildBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildAddon(IconData icon, String label) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppColors.primary),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
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

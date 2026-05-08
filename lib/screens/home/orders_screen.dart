// ignore_for_file: deprecated_member_use

import 'package:details_app/app_imports.dart';
import 'package:details_app/widgets/custom_loading_overlay.dart';
import 'package:details_app/providers/notification_provider.dart';
import 'package:details_app/screens/home/notifications_screen.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // تأخير بسيط لضمان بناء الواجهة قبل جلب البيانات
    Future.delayed(Duration.zero, _fetchOrders);
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
    setState(() => _isLoading = true);
    await Provider.of<OrdersProvider>(context, listen: false).fetchOrders();
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _cancelOrder(String orderId) async {
    // حفظ المراجع قبل الفجوة الزمنية (Async Gap) لتجنب أخطاء BuildContext
    final ordersProvider = Provider.of<OrdersProvider>(context, listen: false);
    final localizations = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(localizations.translate('confirm_deletion')),
        content: Text(localizations.translate('confirm_cancel_body')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(localizations.translate('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              localizations.translate('delete'),
              style: const TextStyle(color: AppColors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    setState(() => _isLoading = true);
    try {
      // استخدام المرجع المحفوظ مسبقاً
      await ordersProvider.updateOrderStatus(orderId, 'ملغي');
      messenger.showSnackBar(
        SnackBar(
          content: Text(localizations.translate('order_status_updated')),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(localizations.translate('order_status_update_failed')),
          backgroundColor: AppColors.red,
        ),
      );
    }
    _fetchOrders();
  }

  @override
  Widget build(BuildContext context) {
    final orders = Provider.of<OrdersProvider>(context).orders;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 140,
          title: Image.asset('assets/images/logo2.png', height: 80),
          centerTitle: true,
          backgroundColor: AppColors.white,
          foregroundColor: AppColors.appBarForeground,
          scrolledUnderElevation: 0,
          surfaceTintColor: AppColors.transparent,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/');
              }
            },
          ),
          bottom: TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.grey,
            indicatorColor: AppColors.primary,
            tabs: [
              Tab(text: AppLocalizations.of(context)!.translate('ongoing')),
              Tab(text: AppLocalizations.of(context)!.translate('completed')),
              Tab(text: AppLocalizations.of(context)!.translate('cancelled')),
            ],
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
        body: Stack(
          children: [
            TabBarView(
              children: [
                _buildOrderList(
                  orders
                      .where(
                        (o) =>
                            o.status == 'قيد التجهيز' || o.status == 'تم الشحن',
                      )
                      .toList(),
                ),
                _buildOrderList(
                  orders.where((o) => o.status == 'تم التوصيل').toList(),
                ),
                _buildOrderList(
                  orders.where((o) => o.status == 'ملغي').toList(),
                ),
              ],
            ),
            if (_isLoading) const CustomLoadingOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderList(List<dynamic> filteredOrders) {
    if (filteredOrders.isEmpty && !_isLoading) {
      return Center(
        child: Text(
          AppLocalizations.of(context)!.translate('no_orders'),
          style: const TextStyle(fontSize: 18, color: AppColors.grey),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _fetchOrders,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filteredOrders.length,
        itemBuilder: (ctx, i) {
          final order = filteredOrders[i];
          final orderId = order.id.toString();

          return Card(
            color: Colors.white,
            elevation: 0,
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: ExpansionTile(
              shape: const RoundedRectangleBorder(side: BorderSide.none),
              title: Text(
                '${AppLocalizations.of(context)!.translate('order_number')} ${orderId.substring(orderId.length - 6)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat('yyyy/MM/dd HH:mm').format(order.dateTime),
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          _buildStatusChip(order.status),
                          const SizedBox(width: 8),
                          Text(
                            '${order.amount.toStringAsFixed(2)} ${AppLocalizations.of(context)!.translate('currency')}',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                      if (order.status == 'قيد التجهيز')
                        TextButton.icon(
                          onPressed: () => _cancelOrder(order.id),
                          icon: const Icon(
                            Icons.cancel,
                            size: 16,
                            color: AppColors.red,
                          ),
                          label: Text(
                            AppLocalizations.of(
                              context,
                            )!.translate('cancel_order'),
                            style: const TextStyle(
                              color: AppColors.red,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              children: [
                const Divider(),
                ...order.products.map<Widget>(
                  (item) => _buildProductItem(item),
                ),
                const SizedBox(height: 8),
              ],
            ),
          );
        },
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

  Widget _buildProductItem(dynamic item) {
    final loc = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              if (item.imageUrl != null) {
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
                            imageUrl: item.imageUrl!,
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
                imageUrl: item.imageUrl ?? '',
                width: 50,
                height: 50,
                fit: BoxFit.cover,
                errorWidget: (context, url, error) =>
                    const Icon(Icons.image_not_supported),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (item.size != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Text(
                          item.size!,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    if (item.color != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: _parseColor(item.color),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.black12, width: 0.5),
                        ),
                      ),
                    ],
                  ],
                ),
                if (item.withOriginalBox == true)
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
                '${(item.quantity * item.price).toStringAsFixed(2)} ${loc.translate('currency')}',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
              ),
              Text(
                'x${item.quantity}',
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAddon(IconData icon, String label) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(icon, size: 12, color: const Color(0xFF9E773A)),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: Color(0xFF9E773A),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
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
}

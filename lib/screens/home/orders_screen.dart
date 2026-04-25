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
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ExpansionTile(
              title: Text(
                '${AppLocalizations.of(context)!.translate('order_number')}${order.id.length > 8 ? order.id.substring(0, 8) : order.id}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat('dd/MM/yyyy HH:mm').format(order.dateTime),
                    style: const TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${order.amount.toStringAsFixed(2)} ${AppLocalizations.of(context)!.translate('currency')}',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(
                            order.status,
                          ).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _getStatusTranslation(
                            order.status,
                            AppLocalizations.of(context)!,
                          ),
                          style: TextStyle(
                            color: _getStatusColor(order.status),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
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
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              children: order.products
                  .map<Widget>(
                    (item) => Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.lightGrey.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
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
                                      Text(
                                        '${item.size}  ',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    if (item.color != null)
                                      Container(
                                        width: 12,
                                        height: 12,
                                        decoration: BoxDecoration(
                                          color: _parseColor(item.color),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.black12,
                                            width: 0.5,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${(item.quantity * item.price).toStringAsFixed(2)} ${AppLocalizations.of(context)!.translate('currency')}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                'x${item.quantity}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          );
        },
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

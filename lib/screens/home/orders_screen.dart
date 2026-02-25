import 'package:details_app/app_imports.dart';
import 'package:details_app/widgets/custom_loading_overlay.dart';

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

  Future<void> _fetchOrders() async {
    setState(() => _isLoading = true);
    await Provider.of<OrdersProvider>(context, listen: false).fetchOrders();
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final orders = Provider.of<OrdersProvider>(context).orders;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.translate('my_orders')),
        backgroundColor: AppColors.appBarBackground,
        foregroundColor: AppColors.appBarForeground,
      ),
      body: Stack(
        children: [
          orders.isEmpty && !_isLoading
              ? Center(
                  child: Text(
                    AppLocalizations.of(context)!.translate('no_orders'),
                    style: const TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: orders.length,
                  itemBuilder: (ctx, i) {
                    final order = orders[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ExpansionTile(
                        title: Text(
                          '${AppLocalizations.of(context)!.translate('order_number')}${order.id.substring(0, 8)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              DateFormat(
                                'dd/MM/yyyy HH:mm',
                              ).format(order.dateTime),
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
                                order.status,
                                style: TextStyle(
                                  color: _getStatusColor(order.status),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        children: order.products
                            .map(
                              (item) => ListTile(
                                title: Text(item.title),
                                subtitle: Text(
                                  '${item.quantity} x ${item.price} ${AppLocalizations.of(context)!.translate('currency')}',
                                ),
                                trailing: Text(
                                  '${(item.quantity * item.price).toStringAsFixed(2)} ${AppLocalizations.of(context)!.translate('currency')}',
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    );
                  },
                ),
          if (_isLoading) const CustomLoadingOverlay(),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'قيد التجهيز':
        return Colors.orange;
      case 'تم الشحن':
        return Colors.blue;
      case 'تم التوصيل':
        return Colors.green;
      case 'ملغي':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

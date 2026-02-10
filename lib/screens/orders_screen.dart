import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:details_app/providers/orders_provider.dart';
import 'package:details_app/constants/app_colors.dart';
import 'package:details_app/l10n/app_localizations.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:details_app/providers/auth_provider.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  @override
  void initState() {
    super.initState();
    // جلب الطلبات عند فتح الشاشة
    Future.microtask(() {
      if (mounted) {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        if (authProvider.isAuthenticated) {
          Provider.of<OrdersProvider>(context, listen: false).fetchOrders();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final ordersData = Provider.of<OrdersProvider>(context);

    // التحقق مما إذا كان المستخدم مسجلاً للدخول
    if (!authProvider.isAuthenticated) {
      return Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.translate('my_orders')),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.primary),
            onPressed: () => context.pop(),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outline, size: 80, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context)!.translate('please_login'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                AppLocalizations.of(context)!.translate('login_subtitle'),
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  await context.push('/login');
                  // بعد العودة من شاشة تسجيل الدخول، نتحقق ونحدث البيانات
                  if (!context.mounted) return;

                  final auth = Provider.of<AuthProvider>(
                    context,
                    listen: false,
                  );
                  if (auth.isAuthenticated) {
                    Provider.of<OrdersProvider>(
                      context,
                      listen: false,
                    ).fetchOrders();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  AppLocalizations.of(context)!.translate('login_button'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.translate('my_orders')),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => context.pop(),
        ),
      ),
      body: ordersData.orders.isEmpty
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : ListView.builder(
              itemCount: ordersData.orders.length,
              itemBuilder: (ctx, i) {
                final order = ordersData.orders[i];
                return Card(
                  margin: const EdgeInsets.all(10),
                  child: Column(
                    children: [
                      ListTile(
                        title: Text(
                          '#${order.id}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          DateFormat('dd/MM/yyyy hh:mm').format(order.dateTime),
                        ),
                        trailing: Text(
                          '\$${order.amount.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 15,
                          vertical: 4,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              order.status,
                              style: TextStyle(
                                color: order.status == 'تم التوصيل'
                                    ? Colors.green
                                    : Colors.orange,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Icon(Icons.expand_more),
                          ],
                        ),
                      ),
                      // عرض تفاصيل المنتجات بشكل مبسط
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 15,
                          vertical: 10,
                        ),
                        height: 60, // ارتفاع ثابت لعرض صور المنتجات
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: order.products
                              .map(
                                (prod) => Padding(
                                  padding: const EdgeInsets.only(right: 10),
                                  child: CircleAvatar(
                                    backgroundImage: CachedNetworkImageProvider(
                                      prod.imageUrl,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

import 'package:details_app/app_imports.dart';

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
          title: Image.asset('assets/images/logo1.png', height: 40),
          backgroundColor: AppColors.appBarBackground,
          foregroundColor: AppColors.appBarForeground,
          centerTitle: true,
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
          actions: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined),
              onPressed: () {},
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
              _navIcon(Icons.home_outlined, 0),
              _navIcon(Icons.search, 1),
              _navIcon(Icons.shopping_bag_outlined, 2),
              _navIcon(Icons.favorite_border, 3),
            ],
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.lock_outline,
                size: 80,
                color: AppColors.homeEmptyStateIcon,
              ),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context)!.translate('please_login'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.homeEmptyStateText,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                AppLocalizations.of(context)!.translate('login_subtitle'),
                style: const TextStyle(color: AppColors.homeEmptyStateText),
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
                  backgroundColor: AppColors.homeButtonPrimary,
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
                    color: AppColors.homeButtonText,
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
        title: Image.asset('assets/images/logo1.png', height: 40),
        backgroundColor: AppColors.appBarBackground,
        foregroundColor: AppColors.appBarForeground,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
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
            _navIcon(Icons.home_outlined, 0),
            _navIcon(Icons.search, 1),
            _navIcon(Icons.shopping_bag_outlined, 2),
            _navIcon(Icons.favorite_border, 3),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ordersData.orders.isEmpty
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : ListView.builder(
                    itemCount: ordersData.orders.length,
                    itemBuilder: (ctx, i) {
                      final order = ordersData.orders[i];
                      return Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.homeCardBackground,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: Column(
                          children: [
                            ListTile(
                              title: Text(
                                '#${order.id}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                DateFormat(
                                  'dd/MM/yyyy hh:mm',
                                ).format(order.dateTime),
                              ),
                              trailing: Text(
                                '${order.amount.toStringAsFixed(2)} ${AppLocalizations.of(context)!.translate('currency')}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.homeOrderPrice,
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
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Flexible(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            (order.status == 'تم التوصيل'
                                                    ? AppColors
                                                          .homeOrderStatusDelivered
                                                    : AppColors
                                                          .homeOrderStatusPending)
                                                .withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        order.status,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: order.status == 'تم التوصيل'
                                              ? AppColors
                                                    .homeOrderStatusDelivered
                                              : AppColors
                                                    .homeOrderStatusPending,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const Icon(
                                    Icons.expand_more,
                                    color: AppColors.homeOrderExpandIcon,
                                  ),
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
                                        padding: const EdgeInsets.only(
                                          right: 10,
                                        ),
                                        child: CircleAvatar(
                                          backgroundImage:
                                              CachedNetworkImageProvider(
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
          ),
        ],
      ),
    );
  }

  Widget _navIcon(IconData icon, int index) {
    return GestureDetector(
      onTap: () => _onNavTap(index),
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

  void _onNavTap(int index) {
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

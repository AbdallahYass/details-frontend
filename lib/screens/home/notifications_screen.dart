import 'package:details_app/app_imports.dart';
import 'package:details_app/widgets/custom_loading_overlay.dart';
import 'package:details_app/providers/notification_provider.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      Provider.of<NotificationProvider>(
        context,
        listen: false,
      ).fetchNotifications(context, authProvider: auth);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 110,
        title: Image.asset('assets/images/logo2.png', height: 100),
        backgroundColor: AppColors.appBarBackground,
        foregroundColor: AppColors.appBarForeground,
        scrolledUnderElevation: 0,
        surfaceTintColor: AppColors.transparent,
        centerTitle: true,
      ),
      body: Consumer2<NotificationProvider, AuthProvider>(
        builder: (context, notifProvider, authProvider, child) {
          if (notifProvider.isLoading && notifProvider.notifications.isEmpty) {
            return const CustomLoadingOverlay(isOverlay: false);
          }

          if (notifProvider.notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_off_outlined,
                    size: 80,
                    color: AppColors.grey300,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    AppLocalizations.of(context)!.translate('no_notifications'),
                    style: const TextStyle(color: AppColors.grey, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => notifProvider.fetchNotifications(
              context,
              authProvider: authProvider,
            ),
            color: AppColors.primary,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: notifProvider.notifications.length,
              itemBuilder: (context, index) {
                final notification = notifProvider.notifications[index];
                return Dismissible(
                  key: Key(notification.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    color: AppColors.red,
                    child: const Icon(Icons.delete, color: AppColors.white),
                  ),
                  onDismissed: (direction) {
                    notifProvider.deleteNotification(
                      notification.id,
                      authProvider,
                    );
                  },
                  child: Card(
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: notification.isRead
                            ? AppColors.transparent
                            : AppColors.primary.withValues(alpha: 0.5),
                        width: 1,
                      ),
                    ),
                    color: notification.isRead
                        ? AppColors.white
                        : AppColors.primary.withValues(alpha: 0.05),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      leading: CircleAvatar(
                        backgroundColor: notification.isRead
                            ? AppColors.grey200
                            : AppColors.primary.withValues(alpha: 0.1),
                        child: Icon(
                          _getNotificationIcon(notification.type),
                          color: notification.isRead
                              ? AppColors.grey
                              : AppColors.primary,
                        ),
                      ),
                      title: Text(
                        notification.title,
                        style: TextStyle(
                          fontWeight: notification.isRead
                              ? FontWeight.normal
                              : FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 6),
                          Text(
                            notification.body,
                            style: TextStyle(
                              color: AppColors.grey700,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            DateFormat(
                              'dd/MM/yyyy hh:mm a',
                            ).format(notification.createdAt),
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.grey500,
                            ),
                          ),
                        ],
                      ),
                      onTap: () {
                        notifProvider.markAsRead(notification.id, authProvider);
                      },
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'order':
        return Icons.local_shipping_outlined;
      case 'promo':
        return Icons.local_offer_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }
}

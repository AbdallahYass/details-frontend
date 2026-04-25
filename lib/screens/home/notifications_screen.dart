import 'package:details_app/app_imports.dart';
import 'package:details_app/providers/notification_provider.dart';
import 'package:details_app/models/notification_model.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final auth = Provider.of<AuthProvider>(context, listen: false);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(loc.translate('nav_notifications')),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/images/bg.png', fit: BoxFit.cover),
          ),
          Consumer<NotificationProvider>(
            builder: (context, provider, child) {
              if (provider.notifications.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.notifications_none_outlined,
                        size: 80,
                        color: AppColors.grey.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        loc.translate('no_notifications'),
                        style: const TextStyle(
                          fontSize: 18,
                          color: AppColors.grey,
                        ),
                      ),
                    ],
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: provider.notifications.length,
                itemBuilder: (context, index) {
                  final notif = provider.notifications[index];
                  return _buildNotificationCard(context, notif, provider, auth);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(
    BuildContext context,
    NotificationModel notif,
    NotificationProvider provider,
    AuthProvider auth,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      color: notif.isRead ? Colors.white.withValues(alpha: 0.8) : Colors.white,
      elevation: notif.isRead ? 0 : 2,
      child: ListTile(
        onTap: () => provider.markAsRead(notif.id, auth),
        leading: CircleAvatar(
          backgroundColor: _getNotifColor(notif.type).withValues(alpha: 0.1),
          child: Icon(
            _getNotifIcon(notif.type),
            color: _getNotifColor(notif.type),
          ),
        ),
        title: Text(
          notif.title,
          style: TextStyle(
            fontWeight: notif.isRead ? FontWeight.normal : FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notif.body),
            const SizedBox(height: 4),
            Text(
              DateFormat('dd/MM/yyyy HH:mm').format(notif.createdAt),
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ),
        trailing: notif.isRead
            ? null
            : const CircleAvatar(radius: 4, backgroundColor: AppColors.primary),
      ),
    );
  }

  IconData _getNotifIcon(String type) {
    if (type == 'order') return Icons.shopping_bag_outlined;
    if (type == 'promo') return Icons.local_offer_outlined;
    return Icons.notifications_outlined;
  }

  Color _getNotifColor(String type) {
    if (type == 'order') return Colors.blue;
    if (type == 'promo') return Colors.orange;
    return AppColors.primary;
  }
}

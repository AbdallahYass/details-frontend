import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:details_app/constants/app_colors.dart';
import 'package:details_app/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:details_app/providers/auth_provider.dart';
import 'package:details_app/widgets/custom_app_bar.dart'; // Correct the import
import 'package:details_app/providers/settings_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class MainScreen extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainScreen({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: navigationShell.currentIndex == 0 ? null : const CustomAppBar(),
      drawer: _buildDrawer(context),
      body: navigationShell,
      bottomNavigationBar: Container(
        height: 70,
        decoration: BoxDecoration(
          color: AppColors.homeNavBackground,
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowColor,
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _navIcon(
              context,
              Icons.home_outlined,
              // نستخدم nav_shop مؤقتاً أو يمكنك إضافة nav_home في ملفات الترجمة
              AppLocalizations.of(context)!.translate('nav_shop'),
              0,
            ),
            _navIcon(
              context,
              Icons.search,
              AppLocalizations.of(context)!.translate('nav_search'),
              1,
            ),
            _navIcon(
              context,
              Icons.shopping_bag_outlined,
              AppLocalizations.of(context)!.translate('nav_cart'),
              2,
            ),
            _navIcon(
              context,
              Icons.favorite_border,
              AppLocalizations.of(context)!.translate('nav_wishlist'),
              3,
            ),
            _navIcon(
              context,
              Icons.person_outline,
              AppLocalizations.of(context)!.translate('nav_account'),
              4,
            ),
          ],
        ),
      ),
    );
  }

  Widget _navIcon(
    BuildContext context,
    IconData icon,
    String label,
    int index,
  ) {
    final isSelected = navigationShell.currentIndex == index;
    final color = isSelected
        ? AppColors.homeNavActive
        : AppColors.homeNavInactive;

    return GestureDetector(
      onTap: () => _onTap(context, index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: color, fontSize: 10)),
        ],
      ),
    );
  }

  void _onTap(BuildContext context, int index) {
    // عند الضغط على تبويب الحساب، نتحقق من تسجيل الدخول
    if (index == 4) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      if (!auth.isAuthenticated) {
        context.push('/login');
        return;
      }
    }

    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  Widget _buildDrawer(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final settings = Provider.of<SettingsProvider>(context);

    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: AppColors.homeDrawerHeader),
            accountName: Text(
              auth.isAuthenticated ? (auth.user?.name ?? 'User') : 'Guest',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            accountEmail: Text(
              auth.isAuthenticated
                  ? (auth.user?.email ?? '')
                  : 'Welcome to Details',
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: AppColors.homeDrawerAvatarBg,
              child: Text(
                auth.isAuthenticated
                    ? (auth.user?.name[0].toUpperCase() ?? 'U')
                    : 'G',
                style: const TextStyle(
                  fontSize: 24,
                  color: AppColors.homeDrawerAvatarText,
                ),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(
              Icons.language,
              color: AppColors.homeDrawerIcon,
            ),
            title: Text(AppLocalizations.of(context)!.translate('language')),
            trailing: DropdownButton<Locale>(
              value: settings.locale,
              underline: const SizedBox(),
              icon: const Icon(
                Icons.arrow_drop_down,
                color: AppColors.homeDrawerIcon,
              ),
              onChanged: (Locale? newLocale) {
                if (newLocale != null) {
                  settings.setLocale(newLocale);
                  Navigator.pop(context); // إغلاق القائمة
                }
              },
              items: const [
                DropdownMenuItem(
                  value: Locale('ar', ''),
                  child: Text('العربية'),
                ),
                DropdownMenuItem(
                  value: Locale('en', ''),
                  child: Text('English'),
                ),
              ],
            ),
          ),
          const Divider(),
          ListTile(
            leading: const FaIcon(
              FontAwesomeIcons.whatsapp,
              color: AppColors.whatsapp,
              size: 24,
            ),
            title: const Text('WhatsApp'),
            onTap: () async {
              Navigator.pop(context);
              final Uri url = Uri.parse('https://wa.me/972598723438');
              if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
                debugPrint('Could not launch $url');
              }
            },
          ),
          ListTile(
            leading: const Icon(
              Icons.info_outline,
              color: AppColors.homeDrawerIcon,
            ),
            title: Text(
              AppLocalizations.of(context)!.translate('footer_about_title'),
            ),
            onTap: () {
              Navigator.pop(context);
              context.push('/about');
            },
          ),
          // رابط لوحة التحكم (يظهر فقط للأدمن)
          if (auth.isAuthenticated && (auth.user?.isAdmin ?? false))
            ListTile(
              leading: const Icon(
                Icons.dashboard_customize,
                color: AppColors.homeDrawerIcon,
              ),
              title: const Text('لوحة التحكم'),
              onTap: () {
                Navigator.pop(context);
                context.push('/admin');
              },
            ),
          const Spacer(),
          const Divider(),
          if (auth.isAuthenticated)
            ListTile(
              leading: const Icon(
                Icons.logout,
                color: AppColors.homeDrawerLogout,
              ),
              title: Text(
                AppLocalizations.of(context)!.translate('logout'),
                style: const TextStyle(
                  color: AppColors.homeDrawerLogout,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                auth.logout();
                context.go('/');
              },
            )
          else
            const SizedBox(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

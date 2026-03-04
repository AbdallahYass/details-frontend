import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:details_app/providers/auth_provider.dart';
import 'package:details_app/providers/settings_provider.dart';
import 'package:details_app/l10n/app_localizations.dart';
import 'package:details_app/constants/app_colors.dart';
import 'package:details_app/screens/home/contact_us_screen.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final settings = Provider.of<SettingsProvider>(context);

    return Drawer(
      backgroundColor: AppColors.white,
      child: Column(
        children: [
          // Custom Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 60, 20, 30),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: AppColors.white,
                    shape: BoxShape.circle,
                  ),
                  child: CircleAvatar(
                    radius: 35,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    child: Text(
                      auth.isAuthenticated
                          ? (auth.user?.name[0].toUpperCase() ?? 'U')
                          : 'G',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                Text(
                  auth.isAuthenticated
                      ? (auth.user?.name ?? 'User')
                      : AppLocalizations.of(
                          context,
                        )!.translate('welcome_guest'),
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (auth.isAuthenticated)
                  Text(
                    auth.user?.email ?? '',
                    style: TextStyle(
                      color: AppColors.white.withValues(alpha: 0.7),
                      fontSize: 13,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              children: [
                if (!auth.isAuthenticated) ...[
                  _drawerTile(
                    context,
                    icon: Icons.login,
                    title: AppLocalizations.of(
                      context,
                    )!.translate('login_button'),
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/login');
                    },
                  ),
                  _drawerTile(
                    context,
                    icon: Icons.person_add_outlined,
                    title: AppLocalizations.of(
                      context,
                    )!.translate('create_account_link'),
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/register');
                    },
                  ),
                  const Divider(height: 30),
                ] else ...[
                  _drawerTile(
                    context,
                    icon: Icons.person_outline,
                    title: AppLocalizations.of(
                      context,
                    )!.translate('profile_title'),
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/profile');
                    },
                  ),
                  _drawerTile(
                    context,
                    icon: Icons.shopping_bag_outlined,
                    title: AppLocalizations.of(context)!.translate('my_orders'),
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/orders');
                    },
                  ),
                  const Divider(height: 30),
                ],

                // Settings Section
                _drawerTile(
                  context,
                  icon: Icons.language,
                  title: AppLocalizations.of(context)!.translate('language'),
                  trailing: DropdownButton<Locale>(
                    value: settings.locale,
                    underline: const SizedBox(),
                    icon: const Icon(
                      Icons.arrow_drop_down,
                      color: AppColors.primary,
                    ),
                    onChanged: (Locale? newLocale) {
                      if (newLocale != null) {
                        settings.setLocale(newLocale);
                        Navigator.pop(context);
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

                // Support Section
                _drawerTile(
                  context,
                  icon: FontAwesomeIcons.whatsapp,
                  title: 'WhatsApp',
                  onTap: () async {
                    Navigator.pop(context);
                    final Uri url = Uri.parse('https://wa.me/972598723438');
                    if (!await launchUrl(
                      url,
                      mode: LaunchMode.externalApplication,
                    )) {
                      debugPrint('Could not launch $url');
                    }
                  },
                ),
                _drawerTile(
                  context,
                  icon: Icons.contact_support_outlined,
                  title: AppLocalizations.of(context)!.translate('contact_us'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const ContactUsScreen(),
                      ),
                    );
                  },
                ),
                _drawerTile(
                  context,
                  icon: Icons.info_outline,
                  title: AppLocalizations.of(
                    context,
                  )!.translate('footer_about_title'),
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/about');
                  },
                ),

                if (auth.isAuthenticated && (auth.user?.isAdmin ?? false)) ...[
                  const Divider(height: 30),
                  _drawerTile(
                    context,
                    icon: Icons.dashboard_customize,
                    title: AppLocalizations.of(
                      context,
                    )!.translate('admin_panel'),
                    color: AppColors.primary,
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/admin');
                    },
                  ),
                ],

                if (auth.isAuthenticated) ...[
                  const Divider(height: 30),
                  _drawerTile(
                    context,
                    icon: Icons.logout,
                    title: AppLocalizations.of(context)!.translate('logout'),
                    color: AppColors.red,
                    onTap: () {
                      Navigator.pop(context);
                      auth.logout();
                      context.go('/');
                    },
                  ),
                ],
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _drawerTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    VoidCallback? onTap,
    Widget? trailing,
    Color? color,
  }) {
    final themeColor = color ?? AppColors.primary;
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: themeColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: themeColor, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: color ?? AppColors.black87,
          fontSize: 14,
        ),
      ),
      trailing:
          trailing ??
          const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.grey),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
    );
  }
}

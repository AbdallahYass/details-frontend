import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:details_app/providers/auth_provider.dart';
import 'package:details_app/providers/language_provider.dart';
import 'package:details_app/l10n/app_localizations.dart';
import 'package:details_app/constants/app_colors.dart';
import 'package:details_app/screens/home/contact_us_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final languageProvider = Provider.of<LanguageProvider>(context);
    final loc = AppLocalizations.of(context)!;

    Future<void> confirmDeleteAccount() async {
      final loc = AppLocalizations.of(context)!;
      final showConfirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(loc.translate('delete_account_confirm_title')),
          content: Text(loc.translate('delete_account_confirm_message')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(loc.translate('cancel')),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: TextButton.styleFrom(foregroundColor: AppColors.red),
              child: Text(loc.translate('delete')),
            ),
          ],
        ),
      );

      if (showConfirm == true) {
        final success = await auth.deleteAccount();
        if (success && context.mounted) {
          context.go('/');
        } else if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                auth.errorMessage ?? loc.translate('error_occurred'),
              ),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }

    return Drawer(
      backgroundColor: Colors.transparent,
      child: Stack(
        children: [
          // الخلفية الأساسية
          Positioned.fill(child: Container(color: AppColors.background)),
          // صورة الخلفية بنمط شفاف
          Positioned.fill(
            child: Opacity(
              opacity: 0.5,
              child: Image.asset(
                'assets/images/bg.png',
                fit: BoxFit.cover,
                gaplessPlayback: true,
              ),
            ),
          ),

          Column(
            children: [
              // Custom Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 60, 20, 30),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primary,
                      AppColors.primary.withValues(alpha: 0.9),
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 15,
                      offset: const Offset(0, 10),
                    ),
                  ],
                  border: Border(
                    bottom: BorderSide(
                      color: AppColors.secondary.withValues(alpha: 0.5),
                      width: 1,
                    ),
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.secondary,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.secondary.withValues(alpha: 0.3),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 35,
                        backgroundColor: AppColors.background,
                        backgroundImage:
                            (auth.isAuthenticated &&
                                auth.user?.avatar != null &&
                                auth.user!.avatar!.isNotEmpty)
                            ? CachedNetworkImageProvider(auth.user!.avatar!)
                            : null,
                        child:
                            (auth.isAuthenticated &&
                                auth.user?.avatar != null &&
                                auth.user!.avatar!.isNotEmpty)
                            ? null
                            : Text(
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
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    if (auth.isAuthenticated)
                      Padding(
                        padding: const EdgeInsets.only(top: 5),
                        child: Text(
                          auth.user?.email ?? '',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 13,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  children: [
                    if (!auth.isAuthenticated) ...[
                      _buildSectionHeader(
                        context,
                        loc.translate('nav_account'),
                      ),
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
                    ] else ...[
                      _buildSectionHeader(
                        context,
                        loc.translate('my_activity'),
                      ),
                      _drawerTile(
                        context,
                        icon: Icons.person_outline,
                        title: AppLocalizations.of(
                          context,
                        )!.translate('edit_profile'),
                        onTap: () {
                          Navigator.pop(context);
                          context.push('/edit-profile');
                        },
                      ),
                      _drawerTile(
                        context,
                        icon: Icons.shopping_bag_outlined,
                        title: AppLocalizations.of(
                          context,
                        )!.translate('my_orders'),
                        onTap: () {
                          Navigator.pop(context);
                          context.push('/orders');
                        },
                      ),
                      _drawerTile(
                        context,
                        icon: Icons.location_on_outlined,
                        title: AppLocalizations.of(
                          context,
                        )!.translate('saved_addresses'),
                        onTap: () {
                          Navigator.pop(context);
                          context.push(
                            '/addresses',
                          ); // المسار الخاص بصفحة العناوين
                        },
                      ),
                    ],

                    // Settings Section
                    const SizedBox(height: 15),
                    _buildSectionHeader(context, loc.translate('language')),
                    _drawerTile(
                      context,
                      icon: Icons.language,
                      title: AppLocalizations.of(
                        context,
                      )!.translate('language'),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.secondary.withValues(alpha: 0.3),
                          ),
                        ),
                        child: DropdownButton<String>(
                          value: languageProvider.appLocale.languageCode,
                          underline: const SizedBox(),
                          icon: const Icon(
                            Icons.arrow_drop_down,
                            color: AppColors.primary,
                          ),
                          dropdownColor: AppColors.background,
                          onChanged: (String? newLang) {
                            if (newLang != null) {
                              languageProvider.changeLanguage(newLang);
                              Navigator.pop(context);
                            }
                          },
                          items: const [
                            DropdownMenuItem(
                              value: 'ar',
                              child: Text(
                                'العربية',
                                style: TextStyle(fontSize: 14),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'en',
                              child: Text(
                                'English',
                                style: TextStyle(fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Support Section
                    const SizedBox(height: 15),
                    _buildSectionHeader(context, loc.translate('contact_us')),
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
                      title: AppLocalizations.of(
                        context,
                      )!.translate('contact_us'),
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

                    if (auth.isAuthenticated &&
                        (auth.user?.isAdmin ?? false)) ...[
                      const SizedBox(height: 15),
                      _buildSectionHeader(
                        context,
                        loc.translate('admin_panel'),
                      ),
                      _drawerTile(
                        context,
                        icon: Icons.dashboard_customize,
                        title: AppLocalizations.of(
                          context,
                        )!.translate('admin_panel'),
                        color: AppColors.primary,
                        isHighlight: true,
                        onTap: () {
                          Navigator.pop(context);
                          context.push('/admin');
                        },
                      ),
                    ],

                    if (auth.isAuthenticated) ...[
                      const SizedBox(height: 15),
                      _buildSectionHeader(
                        context,
                        loc.translate('account_settings'),
                      ),
                      _drawerTile(
                        context,
                        icon: Icons.notifications_active_outlined,
                        title: AppLocalizations.of(
                          context,
                        )!.translate('receive_promotions'),
                        trailing: Transform.scale(
                          scale: 0.8,
                          child: Switch(
                            value: auth.user?.receiveNotifications ?? true,
                            activeThumbColor: AppColors.primary,
                            onChanged: (bool newValue) async {
                              await auth.updateProfile(
                                name: auth.user!.name,
                                phone: auth.user!.phone,
                                receiveNotifications: newValue,
                              );
                            },
                          ),
                        ),
                        onTap: () async {
                          final currentVal =
                              auth.user?.receiveNotifications ?? true;
                          await auth.updateProfile(
                            name: auth.user!.name,
                            phone: auth.user!.phone,
                            receiveNotifications: !currentVal,
                          );
                        },
                      ),
                      _drawerTile(
                        context,
                        icon: Icons.delete_forever,
                        title: AppLocalizations.of(
                          context,
                        )!.translate('delete_account'),
                        color: AppColors.red,
                        onTap: () {
                          Navigator.pop(context); // إغلاق القائمة أولاً
                          confirmDeleteAccount();
                        },
                      ),
                      const SizedBox(height: 15),
                      _buildSectionHeader(
                        context,
                        loc.translate('session_management'),
                      ),
                      _drawerTile(
                        context,
                        icon: Icons.logout,
                        title: AppLocalizations.of(
                          context,
                        )!.translate('logout'),
                        color: AppColors.red,
                        onTap: () async {
                          Navigator.pop(context);
                          await auth.logout();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  AppLocalizations.of(
                                    context,
                                  )!.translate('logged_out_successfully'),
                                ),
                                backgroundColor: AppColors.accent,
                              ),
                            );
                            context.go('/');
                          }
                        },
                      ),
                    ],
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12.0, left: 4, right: 4),
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: AppColors.primary,
          ),
        ),
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
    bool isHighlight = false,
  }) {
    final themeColor = color ?? AppColors.primary;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isHighlight
            ? AppColors.secondary.withValues(alpha: 0.1)
            : Colors.white.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isHighlight
              ? AppColors.secondary.withValues(alpha: 0.5)
              : Colors.transparent,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: themeColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: themeColor, size: 20),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: themeColor,
            fontSize: 14,
          ),
        ),
        trailing:
            trailing ??
            Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: themeColor.withValues(alpha: 0.5),
            ),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      ),
    );
  }
}

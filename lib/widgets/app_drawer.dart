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
      backgroundColor: Colors.transparent,
      child: Stack(
        children: [
          // الخلفية الأساسية
          Positioned.fill(child: Container(color: const Color(0xFFFDFBF7))),
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
                      const Color(0xFF452512),
                      const Color(0xFF452512).withValues(alpha: 0.9),
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
                      color: const Color(0xFFD4AF37).withValues(alpha: 0.5),
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
                          color: const Color(0xFFD4AF37),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFFD4AF37,
                            ).withValues(alpha: 0.3),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 35,
                        backgroundColor: const Color(0xFFFDFBF7),
                        child: Text(
                          auth.isAuthenticated
                              ? (auth.user?.name[0].toUpperCase() ?? 'U')
                              : 'G',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF452512),
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
                      _buildDivider(),
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
                        title: AppLocalizations.of(
                          context,
                        )!.translate('my_orders'),
                        onTap: () {
                          Navigator.pop(context);
                          context.push('/orders');
                        },
                      ),
                      _buildDivider(),
                    ],

                    // Settings Section
                    _drawerTile(
                      context,
                      icon: Icons.language,
                      title: AppLocalizations.of(
                        context,
                      )!.translate('language'),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD4AF37).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(
                              0xFFD4AF37,
                            ).withValues(alpha: 0.3),
                          ),
                        ),
                        child: DropdownButton<Locale>(
                          value: settings.locale,
                          underline: const SizedBox(),
                          icon: const Icon(
                            Icons.arrow_drop_down,
                            color: Color(0xFF452512),
                          ),
                          dropdownColor: const Color(0xFFFDFBF7),
                          onChanged: (Locale? newLocale) {
                            if (newLocale != null) {
                              settings.setLocale(newLocale);
                              Navigator.pop(context);
                            }
                          },
                          items: const [
                            DropdownMenuItem(
                              value: Locale('ar', ''),
                              child: Text(
                                'العربية',
                                style: TextStyle(fontSize: 14),
                              ),
                            ),
                            DropdownMenuItem(
                              value: Locale('en', ''),
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
                      _buildDivider(),
                      _drawerTile(
                        context,
                        icon: Icons.dashboard_customize,
                        title: AppLocalizations.of(
                          context,
                        )!.translate('admin_panel'),
                        color: const Color(0xFF452512),
                        isHighlight: true,
                        onTap: () {
                          Navigator.pop(context);
                          context.push('/admin');
                        },
                      ),
                    ],

                    if (auth.isAuthenticated) ...[
                      _buildDivider(),
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
                                backgroundColor: const Color(0xFF9E773A),
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

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Divider(
        color: const Color(0xFFD4AF37).withValues(alpha: 0.2),
        thickness: 1,
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
    final themeColor = color ?? const Color(0xFF452512);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isHighlight
            ? const Color(0xFFD4AF37).withValues(alpha: 0.1)
            : Colors.white.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isHighlight
              ? const Color(0xFFD4AF37).withValues(alpha: 0.5)
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

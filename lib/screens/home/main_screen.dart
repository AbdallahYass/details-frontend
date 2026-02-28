import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:details_app/app_imports.dart';
import 'package:details_app/screens/home/contact_us_screen.dart';
import 'package:details_app/providers/notification_provider.dart';
import 'package:details_app/screens/home/notifications_screen.dart';

class MainScreen extends StatefulWidget {
  final StatefulNavigationShell navigationShell;

  const MainScreen({super.key, required this.navigationShell});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  bool _isBottomBarVisible = true;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        extendBody: true,
        appBar: _buildAppBar(context),
        drawer: _buildDrawer(context),
        body: NotificationListener<UserScrollNotification>(
          onNotification: (notification) {
            if (notification.direction == ScrollDirection.reverse &&
                notification.metrics.axis == Axis.vertical) {
              if (_isBottomBarVisible) {
                setState(() => _isBottomBarVisible = false);
              }
            } else if (notification.direction == ScrollDirection.forward &&
                notification.metrics.axis == Axis.vertical) {
              if (!_isBottomBarVisible) {
                setState(() => _isBottomBarVisible = true);
              }
            }
            return false;
          },
          child: widget.navigationShell,
        ),
        bottomNavigationBar: AnimatedOpacity(
          duration: const Duration(milliseconds: 300),
          opacity: _isBottomBarVisible ? 1.0 : 0.0,
          curve: Curves.easeInOut,
          child: IgnorePointer(
            ignoring: !_isBottomBarVisible,
            child: Container(
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      toolbarHeight: 80,
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      centerTitle: true,
      leading: Builder(
        builder: (context) {
          return IconButton(
            icon: const Icon(Icons.menu, size: 28),
            onPressed: () => Scaffold.of(context).openDrawer(),
          );
        },
      ),
      title: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Image.asset(
          'assets/images/logo2.png',
          height: 50,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return const Icon(Icons.broken_image, size: 30, color: Colors.red);
          },
        ),
      ),
      actions: [
        Consumer<NotificationProvider>(
          builder: (context, notifProvider, child) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined, size: 28),
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
                      right: 5,
                      top: 12,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '${notifProvider.unreadCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _navIcon(
    BuildContext context,
    IconData icon,
    String label,
    int index,
  ) {
    final isSelected = widget.navigationShell.currentIndex == index;

    return GestureDetector(
      onTap: () => _onTap(context, index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: isSelected
            ? const EdgeInsets.symmetric(horizontal: 12, vertical: 8)
            : const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primary : AppColors.homeNavInactive,
              size: 24,
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _onTap(BuildContext context, int index) {
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  Widget _buildDrawer(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final settings = Provider.of<SettingsProvider>(context);

    return Drawer(
      backgroundColor: Colors.white,
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
                    color: Colors.white,
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
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (auth.isAuthenticated)
                  Text(
                    auth.user?.email ?? '',
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
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
          color: color ?? Colors.black87,
          fontSize: 14,
        ),
      ),
      trailing:
          trailing ??
          const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
    );
  }
}

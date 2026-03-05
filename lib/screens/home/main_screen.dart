import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:details_app/app_imports.dart';
import 'package:details_app/providers/notification_provider.dart';
import 'package:details_app/screens/home/notifications_screen.dart';
import 'package:details_app/widgets/app_drawer.dart';
import 'dart:ui';

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
    return Scaffold(
      backgroundColor: const Color(0xFFFDFBF7),
      extendBody: true,
      extendBodyBehindAppBar: true, // السماح للمحتوى بالظهور خلف البار
      appBar: _buildAppBar(context),
      drawer: const AppDrawer(),
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
                  color: AppColors.black.withValues(alpha: 0.1),
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
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      toolbarHeight: 110, // زيادة الارتفاع ليتناسب مع اللوجو الكبير
      backgroundColor: Colors.transparent, // شفاف
      foregroundColor: AppColors.black,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      shadowColor: AppColors.transparent,
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            color: const Color(0xFFFDFBF7).withValues(alpha: 0.8),
          ),
        ),
      ),
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: AppColors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      centerTitle: true,
      leading: Builder(
        builder: (context) {
          return IconButton(
            icon: const Icon(
              Icons.menu,
              size: 30,
              color: AppColors.primary,
            ), // الـ 3 شحطات بلون البراند
            onPressed: () => Scaffold.of(context).openDrawer(),
          );
        },
      ),
      title: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Image.asset(
          'assets/images/logo2.png', // اللوجو
          height: 100,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return const Icon(Icons.store, size: 30, color: AppColors.black);
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
                    icon: const Icon(
                      Icons.notifications_outlined,
                      size: 28,
                      color: AppColors.primary,
                    ),
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
                          color: AppColors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '${notifProvider.unreadCount}',
                          style: const TextStyle(
                            color: AppColors.white,
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
              : AppColors.transparent,
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
}

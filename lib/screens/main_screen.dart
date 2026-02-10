import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:details_app/constants/app_colors.dart';
import 'package:details_app/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:details_app/providers/auth_provider.dart';
import 'package:details_app/widgets/custom_app_bar.dart';

class MainScreen extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainScreen({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(),
      body: navigationShell,
      bottomNavigationBar: Container(
        height: 70,
        decoration: BoxDecoration(
          color: AppColors.white,
          border: Border(top: BorderSide(color: Colors.grey[100]!)),
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
    final color = isSelected ? AppColors.primary : Colors.black;

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
}

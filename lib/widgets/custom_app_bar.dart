import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:details_app/constants/app_colors.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    // التحقق من المسار الحالي لتحديد زر الرجوع
    final String location = GoRouterState.of(context).uri.path;
    final bool isRoot = [
      '/',
      '/search',
      '/cart',
      '/wishlist',
      '/profile',
    ].contains(location);
    final bool canPop = Navigator.of(context).canPop() || !isRoot;

    return AppBar(
      backgroundColor: AppColors.background,
      elevation: 0.5,
      centerTitle: true,
      leading: canPop
          ? IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.primary),
              onPressed: () => context.pop(),
            )
          : IconButton(
              icon: const Icon(Icons.menu, color: AppColors.primary),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
      title: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => context.go('/'),
        child: Image.asset(
          'assets/images/logo.png',
          height: 35,
          errorBuilder: (c, _, __) => const Text(
            "DETAILS",
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(
            Icons.notifications_outlined,
            color: AppColors.primary,
          ),
          onPressed: () {},
        ),
        const SizedBox(width: 15),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

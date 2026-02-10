import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:details_app/constants/app_colors.dart';
import 'package:details_app/providers/cart_provider.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    // التحقق مما إذا كان يمكن الرجوع للصفحة السابقة
    final bool canPop = Navigator.of(context).canPop();

    return AppBar(
      backgroundColor: AppColors.background,
      elevation: 0.5,
      centerTitle: true,
      // إذا كان هناك صفحة سابقة، اعرض زر الرجوع، وإلا اعرض زر القائمة
      leading: canPop
          ? IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.primary),
              onPressed: () => context.pop(),
            )
          : const Icon(Icons.menu, color: AppColors.primary),
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
          icon: const Icon(Icons.search, color: AppColors.primary),
          onPressed: () => context.push('/search'),
        ),
        const SizedBox(width: 15),
        Consumer<CartProvider>(
          builder: (context, cart, child) => Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(
                  Icons.shopping_cart_outlined,
                  color: AppColors.primary,
                ),
                onPressed: () => context.push('/cart'),
              ),
              if (cart.itemCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '${cart.itemCount}',
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 15),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

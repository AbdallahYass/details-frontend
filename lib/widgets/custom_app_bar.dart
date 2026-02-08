import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:details_app/constants/app_colors.dart';
import 'package:details_app/widgets/language_button.dart';

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
          errorBuilder: (c, e, s) => const Text(
            "DETAILS",
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
      actions: const [
        LanguageButton(),
        SizedBox(width: 5),
        Icon(Icons.search, color: AppColors.primary),
        SizedBox(width: 15),
        Icon(Icons.shopping_cart_outlined, color: AppColors.primary),
        SizedBox(width: 15),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

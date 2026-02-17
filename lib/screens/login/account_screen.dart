import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:details_app/providers/auth_provider.dart';
import 'package:details_app/constants/app_colors.dart';
import 'package:details_app/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.user;

    if (!auth.isAuthenticated) {
      return Scaffold(
        body: Center(
          child: ElevatedButton(
            onPressed: () => context.push('/login'),
            child: Text(
              AppLocalizations.of(context)?.translate('login_button') ??
                  'Login',
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: AppColors.primary,
            child: Text(
              user?.name[0].toUpperCase() ?? 'U',
              style: const TextStyle(fontSize: 40, color: AppColors.white),
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: Text(
              user?.name ?? '',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
          Center(
            child: Text(
              user?.email ?? '',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(height: 40),
          ListTile(
            leading: const Icon(Icons.list_alt),
            title: Text(
              AppLocalizations.of(context)?.translate('my_orders') ??
                  'My Orders',
            ),
            onTap: () => context.push('/orders'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: AppColors.error),
            title: Text(
              AppLocalizations.of(context)?.translate('logout') ?? 'Logout',
              style: const TextStyle(color: AppColors.error),
            ),
            onTap: () {
              auth.logout();
              context.go('/');
            },
          ),
        ],
      ),
    );
  }
}

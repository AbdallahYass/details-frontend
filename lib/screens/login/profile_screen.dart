import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:details_app/providers/auth_provider.dart';
import 'package:details_app/constants/app_colors.dart';
import 'package:details_app/l10n/app_localizations.dart';
import 'package:details_app/widgets/custom_loading_overlay.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'package:cached_network_image/cached_network_image.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin {
  bool _isLoading = false;

  // Animation Controllers
  late AnimationController _rotationController;
  late AnimationController _entranceController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    // تحريك الخلفية ببطء
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    // أنيميشن دخول العناصر
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _entranceController,
            curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
          ),
        );

    _entranceController.forward();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _entranceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFFDFBF7),
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: AppColors.primary),
            onPressed: () => context.pop(),
          ),
          title: Text(
            AppLocalizations.of(context)!.translate('profile_title'),
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.edit, color: AppColors.primary),
              onPressed: () => context.push('/edit-profile'),
            ),
          ],
        ),
        body: Stack(
          children: [
            Container(
              width: double.infinity,
              height: double.infinity,
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/bg.png'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            // --- خلفية متحركة ---
            Positioned(
              top: -120,
              right: -120,
              child: AnimatedBuilder(
                animation: _rotationController,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _rotationController.value * 2 * math.pi,
                    child: child,
                  );
                },
                child: Container(
                  width: 400,
                  height: 400,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFD4AF37).withValues(alpha: 0.4),
                      width: 2,
                    ),
                    gradient: SweepGradient(
                      colors: [
                        const Color(0xFFD4AF37).withValues(alpha: 0.2),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -180,
              left: -180,
              child: AnimatedBuilder(
                animation: _rotationController,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: -_rotationController.value * 2 * math.pi,
                    child: child,
                  );
                },
                child: Container(
                  width: 500,
                  height: 500,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      width: 40,
                    ),
                  ),
                ),
              ),
            ),

            SafeArea(
              child: user == null
                  ? Center(
                      child: Text(
                        AppLocalizations.of(context)!.translate('please_login'),
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(24.0),
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: SlideTransition(
                          position: _slideAnimation,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const SizedBox(height: 20),
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(0xFF9E773A),
                                    width: 2,
                                  ),
                                ),
                                child: CircleAvatar(
                                  radius: 50,
                                  backgroundColor: AppColors.lightGrey,
                                  backgroundImage:
                                      (user.avatar != null &&
                                          user.avatar!.isNotEmpty)
                                      ? CachedNetworkImageProvider(user.avatar!)
                                      : null,
                                  child:
                                      (user.avatar == null ||
                                          user.avatar!.isEmpty)
                                      ? const Icon(
                                          Icons.person,
                                          size: 50,
                                          color: AppColors.primary,
                                        )
                                      : null,
                                ),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                user.name,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                user.email,
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              if (user.phone.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  user.phone,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 30),

                              // --- قسم نشاطي التجاري ---
                              _buildSectionHeader(
                                context,
                                AppLocalizations.of(
                                  context,
                                )!.translate('my_activity'),
                              ),
                              _buildMenuCard(
                                icon: Icons.shopping_bag_outlined,
                                title: AppLocalizations.of(
                                  context,
                                )!.translate('my_orders'),
                                onTap: () => context.push('/orders'),
                              ),
                              const SizedBox(height: 15),
                              _buildMenuCard(
                                icon: Icons.favorite_border,
                                title: AppLocalizations.of(
                                  context,
                                )!.translate('nav_wishlist'),
                                onTap: () => context.push('/wishlist'),
                              ),
                              const SizedBox(height: 15),
                              _buildMenuCard(
                                icon: Icons.location_on_outlined,
                                title: AppLocalizations.of(
                                  context,
                                )!.translate('saved_addresses'),
                                onTap: () => context.push('/addresses'),
                              ),

                              const SizedBox(height: 25),

                              // --- قسم الإعدادات ---
                              _buildSectionHeader(
                                context,
                                AppLocalizations.of(
                                  context,
                                )!.translate('account_settings'),
                              ),
                              _buildMenuCard(
                                icon: Icons.person_outline,
                                title: AppLocalizations.of(
                                  context,
                                )!.translate('edit_profile'),
                                onTap: () => context.push('/edit-profile'),
                              ),
                              const SizedBox(height: 15),
                              _buildMenuCard(
                                icon: Icons.info_outline,
                                title: AppLocalizations.of(
                                  context,
                                )!.translate('about_title'),
                                onTap: () => context.push('/about'),
                              ),
                              const SizedBox(height: 25),
                              // --- إعدادات الإشعارات ---
                              _buildSectionHeader(
                                context,
                                AppLocalizations.of(
                                  context,
                                )!.translate('notification_settings'),
                              ),
                              _buildNotificationToggle(context, user),
                              const SizedBox(height: 25),

                              // --- حذف الحساب ---
                              _buildSectionHeader(
                                context,
                                AppLocalizations.of(
                                  context,
                                )!.translate('account_management'),
                              ),
                              _buildMenuCard(
                                icon: Icons.delete_forever,
                                title: AppLocalizations.of(
                                  context,
                                )!.translate('delete_account'),
                                isDestructive: true,
                                onTap: () => _confirmDeleteAccount(context),
                              ),
                              const SizedBox(height: 25),

                              // --- تسجيل الخروج ---
                              _buildSectionHeader(
                                context,
                                AppLocalizations.of(
                                  context,
                                )!.translate('session_management'),
                              ),

                              // --- تسجيل الخروج ---
                              _buildMenuCard(
                                icon: Icons.logout,
                                title: AppLocalizations.of(
                                  context,
                                )!.translate('logout'),
                                isDestructive: true,
                                onTap: () async {
                                  setState(() => _isLoading = true);
                                  await context.read<AuthProvider>().logout();
                                  if (mounted) {
                                    setState(() => _isLoading = false);
                                  }
                                  if (context.mounted) context.go('/');
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
            ),
            if (_isLoading) const CustomLoadingOverlay(),
          ],
        ),
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
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDeleteAccount(BuildContext context) async {
    final loc = AppLocalizations.of(context)!;
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);

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
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(loc.translate('delete')),
          ),
        ],
      ),
    );

    if (showConfirm == true && mounted) {
      setState(() => _isLoading = true);

      final success = await auth.deleteAccount();
      if (mounted) {
        setState(() => _isLoading = false);
        if (success) {
          router.go('/');
        } else {
          messenger.showSnackBar(
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
  }

  Widget _buildNotificationToggle(BuildContext context, User user) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: const Color(0xFFB89560).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: SwitchListTile(
        title: Text(
          AppLocalizations.of(context)!.translate('receive_promotions'),
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        value: user.receiveNotifications ?? true, // افتراضياً true
        onChanged: (bool newValue) async {
          setState(() => _isLoading = true);
          final scaffoldMessenger = ScaffoldMessenger.of(context);
          final loc = AppLocalizations.of(context)!;

          final success = await authProvider.updateProfile(
            name: user.name,
            phone: user.phone,
            email: user.email,
            avatar: user.avatar,
            receiveNotifications: newValue,
          );

          if (mounted) {
            setState(() => _isLoading = false);
            if (success) {
              scaffoldMessenger.showSnackBar(
                SnackBar(
                  content: Text(loc.translate('update_success')),
                  backgroundColor: AppColors.success,
                ),
              );
            } else {
              scaffoldMessenger.showSnackBar(
                SnackBar(
                  content: Text(
                    authProvider.errorMessage ??
                        loc.translate('error_occurred'),
                  ),
                  backgroundColor: AppColors.error,
                ),
              );
            }
          }
        },
        activeThumbColor: AppColors.primary,
        inactiveTrackColor: AppColors.lightGrey,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildMenuCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: const Color(0xFFB89560).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isDestructive ? AppColors.error : const Color(0xFF9E773A),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isDestructive ? AppColors.error : AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: AppColors.grey,
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

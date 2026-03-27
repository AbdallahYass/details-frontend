import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:details_app/constants/app_colors.dart';
import 'package:details_app/l10n/app_localizations.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:details_app/providers/auth_provider.dart';
import 'package:details_app/providers/wishlist_provider.dart';
import 'package:details_app/widgets/custom_loading_overlay.dart';

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (!authProvider.isAuthenticated) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.lock_outline,
                size: 80,
                color: AppColors.homeEmptyStateIcon,
              ),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context)!.translate('please_login'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.homeEmptyStateText,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                AppLocalizations.of(context)!.translate('login_subtitle'),
                style: const TextStyle(color: AppColors.homeEmptyStateText),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.push('/login'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.homeButtonPrimary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  AppLocalizations.of(context)!.translate('login_button'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.homeButtonText,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      extendBodyBehindAppBar: true,
      body: Consumer<WishlistProvider>(
        builder: (context, wishlistProvider, child) {
          final wishlist = wishlistProvider.wishlist;
          return Stack(
            children: [
              Positioned.fill(
                child: Image.asset(
                  'assets/images/bg.png',
                  fit: BoxFit.cover,
                  gaplessPlayback: true,
                  cacheWidth: 1080,
                  filterQuality: FilterQuality.none,
                ),
              ),
              CustomScrollView(
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.only(top: 120, bottom: 20),
                    sliver: wishlist.isEmpty
                        ? SliverFillRemaining(
                            hasScrollBody: false,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(
                                      alpha: 0.05,
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.all(24),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(
                                        alpha: 0.1,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.favorite_border,
                                      size: 64,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                Text(
                                  AppLocalizations.of(
                                    context,
                                  )!.translate('empty_wishlist'),
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  AppLocalizations.of(
                                    context,
                                  )!.translate('app_slogan'),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: AppColors.textSecondary,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 32),
                                ElevatedButton(
                                  onPressed: () => context.go('/'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.accent,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 32,
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    elevation: 8,
                                    shadowColor: AppColors.accent.withValues(
                                      alpha: 0.5,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.storefront_outlined,
                                        color: AppColors.white,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        AppLocalizations.of(
                                          context,
                                        )!.translate('start_shopping'),
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          )
                        : SliverList(
                            delegate: SliverChildBuilderDelegate((
                              context,
                              index,
                            ) {
                              final product = wishlist[index];
                              return Card(
                                color: AppColors.homeCardBackground,
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.all(10),
                                  leading: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: CachedNetworkImage(
                                      imageUrl: product.images.isNotEmpty
                                          ? product.images[0]
                                          : '',
                                      placeholder: (context, url) => Container(
                                        color: AppColors.imagePlaceholder,
                                      ),
                                      width: 60,
                                      height: 60,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  title: Text(
                                    product.getName(context),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Text(
                                    "\$${product.price}",
                                    style: const TextStyle(
                                      color: AppColors.homeProductPrice,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(
                                      Icons.favorite,
                                      color: AppColors.homeWishlistIcon,
                                    ),
                                    onPressed: () async {
                                      setState(() => _isLoading = true);
                                      final added = await wishlistProvider
                                          .toggleWishlist(product);
                                      if (mounted) {
                                        setState(() => _isLoading = false);
                                        if (!context.mounted) return;
                                        ScaffoldMessenger.of(
                                          context,
                                        ).hideCurrentSnackBar();
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              added
                                                  ? AppLocalizations.of(
                                                      context,
                                                    )!.translate(
                                                      'added_to_wishlist',
                                                    )
                                                  : AppLocalizations.of(
                                                      context,
                                                    )!.translate(
                                                      'removed_from_wishlist',
                                                    ),
                                            ),
                                            backgroundColor: added
                                                ? AppColors.primary
                                                : AppColors.red,
                                            behavior: SnackBarBehavior.floating,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            duration: const Duration(
                                              seconds: 1,
                                            ),
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                  onTap: () {
                                    context.push(
                                      '/product/${product.id}',
                                      extra: product,
                                    );
                                  },
                                ),
                              );
                            }, childCount: wishlist.length),
                          ),
                  ),
                ],
              ),
              if (_isLoading) const CustomLoadingOverlay(),
            ],
          );
        },
      ),
    );
  }
}

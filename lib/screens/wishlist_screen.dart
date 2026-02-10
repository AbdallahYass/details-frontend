import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:details_app/providers/wishlist_provider.dart';
import 'package:details_app/constants/app_colors.dart';
import 'package:details_app/l10n/app_localizations.dart';
import 'package:details_app/widgets/custom_app_bar.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:details_app/providers/auth_provider.dart';

class WishlistScreen extends StatelessWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final wishlistProvider = Provider.of<WishlistProvider>(context);
    final wishlist = wishlistProvider.wishlist;

    if (!authProvider.isAuthenticated) {
      return Scaffold(
        appBar: const CustomAppBar(),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outline, size: 80, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context)!.translate('please_login'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                AppLocalizations.of(context)!.translate('login_subtitle'),
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.push('/login'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
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
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: const CustomAppBar(),
      body: wishlist.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.favorite_border,
                    size: 80,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    AppLocalizations.of(context)!.translate('empty_wishlist'),
                    style: const TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: wishlist.length,
              itemBuilder: (context, index) {
                final product = wishlist[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
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
                        placeholder: (context, url) =>
                            Container(color: Colors.grey[200]),
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                      ),
                    ),
                    title: Text(
                      product.getName(context),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      "\$${product.price}",
                      style: const TextStyle(
                        color: AppColors.gold,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.favorite, color: AppColors.red),
                      onPressed: () {
                        wishlistProvider.toggleWishlist(product).then((added) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).hideCurrentSnackBar();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                added
                                    ? AppLocalizations.of(
                                        context,
                                      )!.translate('added_to_wishlist')
                                    : AppLocalizations.of(
                                        context,
                                      )!.translate('removed_from_wishlist'),
                              ),
                              backgroundColor: added
                                  ? AppColors.primary
                                  : AppColors.red,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        });
                      },
                    ),
                    onTap: () {
                      context.push('/product/${product.id}', extra: product);
                    },
                  ),
                );
              },
            ),
    );
  }
}

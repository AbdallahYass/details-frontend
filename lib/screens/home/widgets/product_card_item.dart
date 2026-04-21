import 'package:details_app/app_imports.dart';

class ProductCardItem extends StatelessWidget {
  final Product product;
  final bool isHot;
  final bool heroEnabled;

  const ProductCardItem({
    super.key,
    required this.product,
    this.isHot = false,
    this.heroEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Selector<WishlistProvider, bool>(
      selector: (context, wishlistProvider) =>
          wishlistProvider.isInWishlist(product.id),
      builder: (context, isFav, child) {
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFFFDFBF7),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: GestureDetector(
            onTap: () {
              // Preload image before navigation
              precacheImage(
                CachedNetworkImageProvider(product.imageUrl),
                context,
              );
              context.push('/product/${product.id}', extra: product);
            },
            behavior: HitTestBehavior.opaque,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(12),
                          ),
                          child: HeroMode(
                            enabled: heroEnabled,
                            child: Hero(
                              tag: product.id,
                              child: AnimatedProductImage(product: product),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (product.isSoldOut)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.black.withValues(alpha: 0.7),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  AppLocalizations.of(
                                    context,
                                  )!.translate('sold_out'),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              )
                            else if (isHot)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.red.withValues(alpha: 0.8),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.local_fire_department,
                                      size: 10,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 2),
                                    Text(
                                      AppLocalizations.of(
                                        context,
                                      )!.translate('hot'),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            if (!product.isSoldOut &&
                                product.oldPrice != null &&
                                product.oldPrice! > product.price)
                              Container(
                                margin: EdgeInsets.only(top: isHot ? 4.0 : 0.0),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.success,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '-${((product.oldPrice! - product.price) / product.oldPrice! * 100).round()}%',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: () async {
                            final messenger = ScaffoldMessenger.of(context);
                            final auth = Provider.of<AuthProvider>(
                              context,
                              listen: false,
                            );
                            if (!auth.isAuthenticated) {
                              context.push('/login');
                              return;
                            }
                            final wishlistProvider =
                                Provider.of<WishlistProvider>(
                                  context,
                                  listen: false,
                                );
                            bool added = await wishlistProvider.toggleWishlist(
                              product,
                            );
                            if (!context.mounted) return;
                            messenger.hideCurrentSnackBar();
                            messenger.showSnackBar(
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
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.9),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isFav ? Icons.favorite : Icons.favorite_border,
                              size: 16,
                              color: isFav ? AppColors.red : AppColors.grey,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        product.getName(context),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF452512),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            "${product.price.toStringAsFixed(2)} ${AppLocalizations.of(context)!.translate('currency')}",
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                          ),
                          if (product.oldPrice != null &&
                              product.oldPrice! > product.price) ...[
                            const SizedBox(width: 4),
                            Text(
                              product.oldPrice!.toStringAsFixed(2),
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.grey,
                                decoration: TextDecoration.lineThrough,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),
                      _buildShareButton(context),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildShareButton(BuildContext context) {
    return SizedBox(
      height: 30,
      width: double.infinity,
      child: OutlinedButton(
        onPressed: () async {
          try {
            final currency = AppLocalizations.of(
              context,
            )!.translate('currency');
            final text =
                '🌟 *Check out this amazing product!* 🌟\n\n'
                '🛍️ *${product.getName(context)}*\n'
                '💰 Price: *${product.price} $currency*\n\n'
                '🔗 Link: https://details-store.com/product/${product.id}\n\n'
                '_Sent from Details Store App_';

            if (kIsWeb) {
              await SharePlus.instance.share(ShareParams(text: text));
            } else {
              final file = await DefaultCacheManager().getSingleFile(
                product.imageUrl,
              );
              await SharePlus.instance.share(
                ShareParams(files: [XFile(file.path)], text: text),
              );
            }
          } catch (e) {
            debugPrint('Error sharing: $e');
          }
        },
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          side: BorderSide(color: AppColors.primary.withValues(alpha: 0.2)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.share, size: 14, color: AppColors.primary),
            const SizedBox(width: 4),
            Text(
              AppLocalizations.of(context)!.translate('share_title'),
              style: const TextStyle(fontSize: 10, color: AppColors.primary),
            ),
          ],
        ),
      ),
    );
  }
}

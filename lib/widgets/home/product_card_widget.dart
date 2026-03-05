import 'package:details_app/app_imports.dart';
import 'dart:ui';

class ProductCardWidget extends StatelessWidget {
  final Product product;
  final bool isHot;

  const ProductCardWidget({
    super.key,
    required this.product,
    required this.isHot,
  });

  @override
  Widget build(BuildContext context) {
    return Selector<WishlistProvider, bool>(
      selector: (context, wishlistProvider) =>
          wishlistProvider.isInWishlist(product.id),
      builder: (context, isFav, child) {
        return GestureDetector(
          onTap: () => context.push('/product/${product.id}', extra: product),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                // 1. أرجعنا الـ ClipRRect ليغلف الـ Stack بالكامل
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  // 2. الـ Stack هنا بدون StackFit.expand عشان ما يجبر الصورة على أبعاد وهمية تكسر الـ Animation
                  child: Stack(
                    children: [
                      // 3. الصورة تأخذ حجمها بمرونة كما في كودك الأصلي
                      Hero(
                        tag: product.id,
                        child: AnimatedProductImage(product: product),
                      ),

                      // زر المفضلة الزجاجي العائم الفخم
                      Positioned(
                        top: 10,
                        right: 10,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
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
                                bool added =
                                    await Provider.of<WishlistProvider>(
                                      context,
                                      listen: false,
                                    ).toggleWishlist(product);
                                if (!context.mounted) return;
                                messenger.hideCurrentSnackBar();
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      added
                                          ? 'Added to wishlist'
                                          : 'Removed from wishlist',
                                    ),
                                    duration: const Duration(seconds: 1),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                color: Colors.white.withValues(alpha: 0.3),
                                child: Icon(
                                  isFav
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  size: 18,
                                  color: isFav
                                      ? Colors.redAccent
                                      : Colors.black87,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // شارات الـ Sold Out والـ Hot
                      if (product.isSoldOut)
                        Positioned(
                          top: 10,
                          left: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey[800],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'SOLD OUT',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        )
                      else if (isHot)
                        Positioned(
                          top: 10,
                          left: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black87,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'HOT',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // اسم المنتج
              Text(
                product.getName(context),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              // سعر المنتج
              Text(
                "${product.price.toStringAsFixed(2)} ${AppLocalizations.of(context)!.translate('currency')}",
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFFD4AF37),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

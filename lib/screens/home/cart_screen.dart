import 'package:details_app/app_imports.dart';
import 'package:details_app/widgets/custom_loading_overlay.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> with TickerProviderStateMixin {
  final TextEditingController _couponController = TextEditingController();
  bool _isLoading = false;
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _couponController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFBF7),
      extendBodyBehindAppBar: true,
      body: Consumer<CartProvider>(
        builder: (context, cart, child) {
          final cartItems = cart.items.values.toList();

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
              Column(
                children: [
                  Expanded(
                    child: CustomScrollView(
                      physics: const BouncingScrollPhysics(
                        parent: AlwaysScrollableScrollPhysics(),
                      ),
                      slivers: [
                        SliverPadding(
                          padding: const EdgeInsets.only(top: 120, bottom: 20),
                          sliver: cartItems.isEmpty
                              ? SliverFillRemaining(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.shopping_cart_outlined,
                                        size: 80,
                                        color: Colors.grey.withValues(
                                          alpha: 0.5,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        AppLocalizations.of(
                                          context,
                                        )!.translate('cart_empty'),
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF452512),
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
                                    return _CartItemWidget(
                                      cartItem: cartItems[index],
                                      cart: cart,
                                    );
                                  }, childCount: cartItems.length),
                                ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          offset: const Offset(0, -4),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: SafeArea(
                      top: false,
                      bottom: false,
                      child: Column(
                        children: [
                          // Coupon Section
                          Container(
                            margin: const EdgeInsets.only(bottom: 20),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFDFBF7),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(
                                  0xFFB89560,
                                ).withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.local_offer_outlined,
                                  color: Color(0xFF9E773A),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: TextField(
                                    controller: _couponController,
                                    decoration: InputDecoration(
                                      hintText: AppLocalizations.of(
                                        context,
                                      )!.translate('enter_coupon_code'),
                                      border: InputBorder.none,
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () async {
                                    if (_couponController.text.isNotEmpty) {
                                      setState(() => _isLoading = true);
                                      final success = await cart.applyCoupon(
                                        _couponController.text,
                                      );
                                      setState(() => _isLoading = false);
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              success
                                                  ? AppLocalizations.of(
                                                      context,
                                                    )!.translate(
                                                      'coupon_applied',
                                                    )
                                                  : AppLocalizations.of(
                                                      context,
                                                    )!.translate(
                                                      'coupon_invalid',
                                                    ),
                                            ),
                                            backgroundColor: success
                                                ? Colors.green
                                                : Colors.red,
                                          ),
                                        );
                                      }
                                    }
                                  },
                                  child: Text(
                                    AppLocalizations.of(
                                      context,
                                    )!.translate('apply'),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF9E773A),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                AppLocalizations.of(
                                  context,
                                )!.translate('total'),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${cart.totalAmount.toStringAsFixed(2)} ${AppLocalizations.of(context)!.translate('currency')}',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: cart.totalAmount <= 0
                                  ? null
                                  : () {
                                      context.push('/checkout');
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF9E773A),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                AppLocalizations.of(
                                  context,
                                )!.translate('checkout'),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
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

class _CartItemWidget extends StatelessWidget {
  final CartItem cartItem;
  final CartProvider cart;

  const _CartItemWidget({required this.cartItem, required this.cart});

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(cartItem.id),
      background: const _DeleteBackground(),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) {
        cart.removeItem(cartItem.id);
      },
      child: _CartItemCard(cartItem: cartItem, cart: cart),
    );
  }
}

class _DeleteBackground extends StatelessWidget {
  const _DeleteBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 20),
      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Icon(Icons.delete, color: Colors.white, size: 40),
    );
  }
}

class _CartItemCard extends StatelessWidget {
  final CartItem cartItem;
  final CartProvider cart;

  const _CartItemCard({required this.cartItem, required this.cart});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0.5,
      color: AppColors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: cartItem.imageUrl,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cartItem.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${AppLocalizations.of(context)!.translate('total')}: ${(cartItem.price * cartItem.quantity).toStringAsFixed(2)} ${AppLocalizations.of(context)!.translate('currency')}',
                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ],
              ),
            ),
            Column(
              children: [
                InkWell(
                  onTap: () => cart.addItem(
                    cartItem.productId,
                    cartItem.price,
                    cartItem.title,
                    cartItem.imageUrl,
                    size: cartItem.size,
                  ),
                  child: const Icon(Icons.add_circle, color: AppColors.primary),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    '${cartItem.quantity}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                InkWell(
                  onTap: () {
                    if (cartItem.quantity > 1) {
                      cart.removeSingleItem(cartItem.id);
                    }
                  },
                  child: Icon(Icons.remove_circle, color: Colors.grey[400]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

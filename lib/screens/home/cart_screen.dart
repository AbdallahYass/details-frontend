import 'package:details_app/app_imports.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  bool _isValidating = false;

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
              CustomScrollView(
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.only(top: 120, bottom: 20),
                    sliver: cartItems.isEmpty
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
                                      Icons.shopping_bag_outlined,
                                      size: 64,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  AppLocalizations.of(
                                    context,
                                  )!.translate('cart_empty'),
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(height: 15),
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
                              return _CartItemWidget(
                                cartItem: cartItems[index],
                                cart: cart,
                              );
                            }, childCount: cartItems.length),
                          ),
                  ),
                  if (cartItems.isNotEmpty)
                    SliverToBoxAdapter(
                      child: _CheckoutSection(
                        cart: cart,
                        isValidating: _isValidating,
                        onCheckout: () => _handleCheckout(cart),
                      ),
                    ),
                ],
              ),
              if (_isValidating)
                Container(
                  color: Colors.black26,
                  child: const Center(child: CircularProgressIndicator()),
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _handleCheckout(CartProvider cart) async {
    setState(() => _isValidating = true);

    final adjustedItems = await cart.validateInventoryBeforeCheckout();

    if (!mounted) return;
    setState(() => _isValidating = false);

    if (adjustedItems.isNotEmpty) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(AppLocalizations.of(context)!.translate('notice')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppLocalizations.of(context)!.translate('stock_changed')),
              const SizedBox(height: 12),
              ...adjustedItems.map((item) {
                String label = item;
                if (item.contains('(out_of_stock)')) {
                  final title = item.split('(').first.trim();
                  label =
                      '$title (${AppLocalizations.of(context)!.translate('out_of_stock')})';
                } else if (item.contains('(quantity_updated)')) {
                  final title = item.split('(').first.trim();
                  label =
                      '$title (${AppLocalizations.of(context)!.translate('quantity_updated')})';
                }
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text('• $label', style: const TextStyle(fontSize: 14)),
                );
              }),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(AppLocalizations.of(context)!.translate('ok')),
            ),
          ],
        ),
      );
    } else if (cart.items.isNotEmpty) {
      context.push('/checkout');
    }
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
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text(
                AppLocalizations.of(context)!.translate('confirm_deletion'),
              ),
              content: Text(
                AppLocalizations.of(
                  context,
                )!.translate('delete_user_confirmation'),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(
                    AppLocalizations.of(context)!.translate('cancel'),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text(
                    AppLocalizations.of(context)!.translate('delete'),
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ],
            );
          },
        );
      },
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
    final double extraCharges = (cartItem.withOriginalBox ? 10 : 0);
    final double itemTotalPrice =
        (cartItem.price + extraCharges) * cartItem.quantity;

    return Card(
      elevation: 0,
      color: AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.grey.shade100),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // صورة المنتج
            InkWell(
              onTap: () => context.push('/product/${cartItem.productId}'),
              borderRadius: BorderRadius.circular(12),
              child: Hero(
                tag: 'cart-${cartItem.id}',
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: cartItem.imageUrl,
                    width: 85,
                    height: 85,
                    fit: BoxFit.cover,
                    placeholder: (context, url) =>
                        Container(color: Colors.grey.shade50),
                    errorWidget: (context, url, error) =>
                        const Icon(Icons.image_not_supported_outlined),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // تفاصيل المنتج
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cartItem.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  if (cartItem.size != null || cartItem.color != null)
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        if (cartItem.size != null)
                          _buildMiniChip(
                            '${AppLocalizations.of(context)!.translate('size')}: ${cartItem.size}',
                          ),
                        if (cartItem.color != null)
                          _buildMiniChip(
                            '${AppLocalizations.of(context)!.translate('colors')}: ${cartItem.color}',
                          ),
                      ],
                    ),
                  const SizedBox(height: 8),
                  Text(
                    '${itemTotalPrice.toStringAsFixed(2)} ${AppLocalizations.of(context)!.translate('currency')}',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  // خيارات الإضافات
                  Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    children: [
                      if (cartItem.allowOriginalBox) ...[
                        _buildOptionToggle(
                          context: context,
                          label: 'علبة أصلية (+10)',
                          isSelected: cartItem.withOriginalBox,
                          onTap: () => cart.toggleOriginalBox(cartItem.id),
                          icon: Icons.inventory_2_outlined,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            // التحكم بالكمية
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: Column(
                children: [
                  InkWell(
                    onTap: () {
                      final success = cart.updateItemQuantity(
                        cartItem.id,
                        cartItem.quantity + 1,
                      );
                      if (!success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              AppLocalizations.of(
                                context,
                              )!.translate('max_quantity_reached'),
                            ),
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppColors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.add,
                        color: AppColors.primary,
                        size: 18,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      '${cartItem.quantity}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () async {
                      if (cartItem.quantity > 1) {
                        cart.removeSingleItem(cartItem.id);
                      } else {
                        final confirm = await _showDeleteDialog(context);
                        if (confirm == true) {
                          cart.removeItem(cartItem.id);
                        }
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppColors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.remove,
                        color: Colors.grey[400],
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 10, color: Colors.grey),
      ),
    );
  }

  Widget _buildOptionToggle({
    required BuildContext context,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required IconData icon,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.1)
              : Colors.transparent,
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey.shade200,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? Icons.check_circle : icon,
              size: 14,
              color: isSelected ? AppColors.primary : Colors.grey,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: isSelected ? AppColors.primary : Colors.grey,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool?> _showDeleteDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            AppLocalizations.of(context)!.translate('confirm_deletion'),
          ),
          content: Text(
            AppLocalizations.of(context)!.translate('delete_user_confirmation'),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(AppLocalizations.of(context)!.translate('cancel')),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                AppLocalizations.of(context)!.translate('delete'),
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _CheckoutSection extends StatelessWidget {
  final CartProvider cart;
  final bool isValidating;
  final VoidCallback onCheckout;

  const _CheckoutSection({
    required this.cart,
    required this.isValidating,
    required this.onCheckout,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
        ).copyWith(top: 10, bottom: 120),
        child: Column(
          children: [
            // Subtotal (Products Total)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppLocalizations.of(context)!.translate('total'),
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
                Text(
                  '${(cart.subtotal - cart.discountAmount).toStringAsFixed(2)} ${AppLocalizations.of(context)!.translate('currency')}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),

            // Gift Box Total
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: cart.withGiftBox
                    ? const Color(0xFF9E773A).withValues(alpha: 0.05)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: cart.withGiftBox
                      ? const Color(0xFF9E773A).withValues(alpha: 0.2)
                      : Colors.transparent,
                ),
              ),
              child: SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                title: Text(
                  AppLocalizations.of(context)!.translate('with_box'),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF9E773A),
                  ),
                ),
                subtitle: Text(
                  '+5.00 ${AppLocalizations.of(context)!.translate('currency')}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                secondary: const Icon(
                  Icons.card_giftcard,
                  color: Color(0xFF9E773A),
                ),
                value: cart.withGiftBox,
                activeThumbColor: const Color(0xFF9E773A),
                onChanged: (_) => cart.toggleGiftBox(),
              ),
            ),
            if (cart.giftTotal > 0) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${cart.giftTotal.toStringAsFixed(2)} ${AppLocalizations.of(context)!.translate('currency')}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF9E773A),
                    ),
                  ),
                ],
              ),
            ],

            // Original Box Total
            if (cart.originalBoxTotal > 0) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppLocalizations.of(context)!.translate('original_box_fee'),
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  Text(
                    '${cart.originalBoxTotal.toStringAsFixed(2)} ${AppLocalizations.of(context)!.translate('currency')}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 20), // Separator before final total
            // Final Total
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppLocalizations.of(context)!.translate('final_total'),
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
                onPressed: cart.totalAmount <= 0 || isValidating
                    ? null
                    : onCheckout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF9E773A),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  AppLocalizations.of(context)!.translate('checkout'),
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
    );
  }
}

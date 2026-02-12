import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:details_app/providers/cart_provider.dart';
import 'package:details_app/constants/app_colors.dart';
import 'package:details_app/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final TextEditingController _couponController = TextEditingController();

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    final cartItems = cart.items.values.toList();

    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 20),
              physics: const BouncingScrollPhysics(),
              itemCount: cart.items.length,
              itemBuilder: (context, index) {
                return _CartItemWidget(cartItem: cartItems[index], cart: cart);
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  offset: const Offset(0, -4),
                  blurRadius: 10,
                ),
              ],
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // Coupon Section
                  Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.local_offer_outlined,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _couponController,
                            decoration: const InputDecoration(
                              hintText: 'Enter Coupon Code',
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            if (_couponController.text.isNotEmpty) {
                              final success = await cart.applyCoupon(
                                _couponController.text,
                              );
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      success
                                          ? 'تم تطبيق الخصم بنجاح'
                                          : 'كود الخصم غير صالح',
                                    ),
                                    backgroundColor: success
                                        ? Colors.green
                                        : Colors.red,
                                  ),
                                );
                              }
                            }
                          },
                          child: const Text(
                            'APPLY',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.translate('total'),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '\$${cart.totalAmount.toStringAsFixed(2)}',
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
                        backgroundColor: AppColors.primary,
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
          ),
        ],
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
                    '${AppLocalizations.of(context)!.translate('total')}: \$${(cartItem.price * cartItem.quantity).toStringAsFixed(2)}',
                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ],
              ),
            ),
            Column(
              children: [
                InkWell(
                  onTap: () => cart.addItem(
                    cartItem.id,
                    cartItem.price,
                    cartItem.title,
                    cartItem.imageUrl,
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

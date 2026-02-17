// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:details_app/constants/app_colors.dart';
import 'package:details_app/l10n/app_localizations.dart';
import 'package:details_app/providers/cart_provider.dart';
import 'package:details_app/providers/auth_provider.dart';
import 'package:details_app/providers/orders_provider.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cityController = TextEditingController();
  final _streetController = TextEditingController();
  final _phoneController = TextEditingController();
  String _paymentMethod = 'cod'; // cash on delivery
  bool _isLoading = false;

  @override
  void dispose() {
    _cityController.dispose();
    _streetController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submitOrder() async {
    FocusScope.of(context).unfocus();

    // 1. التحقق من تسجيل الدخول
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (!auth.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.translate('please_login'),
          ),
          action: SnackBarAction(
            label: AppLocalizations.of(context)!.translate('login_button'),
            onPressed: () => context.push('/login'),
          ),
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    final cart = Provider.of<CartProvider>(context, listen: false);
    if (cart.items.isEmpty) return;

    setState(() => _isLoading = true);

    // تجهيز البيانات حسب Schema الباك اند
    final orderPayload = {
      'products': cart.items.values
          .map(
            (cp) => {
              'id': cp.productId, // نرسل ID المنتج الأصلي
              'title': cp.size != null
                  ? '${cp.title} (${cp.size})'
                  : cp.title, // دمج المقاس مع الاسم
              'size': cp.size, // إضافة المقاس كحقل منفصل
              'quantity': cp.quantity,
              'price': cp.price,
              'imageUrl': cp.imageUrl,
            },
          )
          .toList(),
      'subtotal': cart.subtotal,
      'discountAmount': cart.discountAmount,
      'couponCode': cart.couponCode,
      'amount': cart.totalAmount,
      'shippingAddress': {
        'city': _cityController.text,
        'street': _streetController.text,
        'phone': _phoneController.text,
      },
      'payment_method': _paymentMethod,
    };

    try {
      final success = await Provider.of<OrdersProvider>(
        context,
        listen: false,
      ).addOrder(orderPayload);

      if (mounted) {
        setState(() => _isLoading = false);
        if (success) {
          cart.clear();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)!.translate('order_success'),
              ),
              backgroundColor: AppColors.success,
            ),
          );
          context.go('/orders');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)!.translate('order_failed'),
              ),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.translate('error_occurred'),
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    final total = cart.totalAmount;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.translate('checkout')),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => context.pop(),
        ),
      ),
      body: cart.items.isEmpty
          ? Center(
              child: Text(
                AppLocalizations.of(context)!.translate('cart_empty'),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.translate('shipping_info'),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(
                      controller: _cityController,
                      label: AppLocalizations.of(context)!.translate('city'),
                      icon: Icons.location_city,
                      validator: (value) {
                        if (value == null || value.trim().length < 2) {
                          return 'يرجى إدخال اسم مدينة صحيح';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 15),
                    _buildTextField(
                      controller: _streetController,
                      label: AppLocalizations.of(context)!.translate('street'),
                      icon: Icons.map,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return AppLocalizations.of(
                            context,
                          )!.translate('required_field');
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 15),
                    _buildTextField(
                      controller: _phoneController,
                      label: AppLocalizations.of(context)!.translate('phone'),
                      icon: Icons.phone,
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return AppLocalizations.of(
                            context,
                          )!.translate('required_field');
                        }
                        if (value.length < 9) {
                          return 'يرجى إدخال رقم هاتف صحيح';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 30),
                    Text(
                      AppLocalizations.of(context)!.translate('payment_method'),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        Expanded(
                          child: _buildPaymentOption(
                            value: 'cod',
                            label: AppLocalizations.of(
                              context,
                            )!.translate('cash_on_delivery'),
                            icon: Icons.money,
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: _buildPaymentOption(
                            value: 'card',
                            label: AppLocalizations.of(
                              context,
                            )!.translate('credit_card'),
                            icon: Icons.credit_card,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.lightGrey),
                      ),
                      child: Row(
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
                            '\$${total.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.secondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submitOrder,
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: AppColors.white,
                              )
                            : Text(
                                AppLocalizations.of(
                                  context,
                                )!.translate('confirm_order'),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.primary),
        filled: true,
        fillColor: AppColors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.arrowInactive),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.arrowInactive),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
      validator: validator,
    );
  }

  Widget _buildPaymentOption({
    required String value,
    required String label,
    required IconData icon,
  }) {
    final isSelected = _paymentMethod == value;
    return GestureDetector(
      onTap: () => setState(() => _paymentMethod = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(0.05)
              : AppColors.white,
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.arrowInactive,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primary : AppColors.grey,
              size: 30,
            ),
            const SizedBox(height: 10),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

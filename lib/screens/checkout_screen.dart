// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:details_app/constants/app_colors.dart';
import 'package:details_app/l10n/app_localizations.dart';
import 'package:details_app/providers/cart_provider.dart';
import 'package:details_app/providers/orders_provider.dart';
import 'package:details_app/widgets/custom_app_bar.dart';

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
    if (!_formKey.currentState!.validate()) return;

    final cart = Provider.of<CartProvider>(context, listen: false);
    if (cart.items.isEmpty) return;

    setState(() => _isLoading = true);

    final orderData = {
      'city': _cityController.text,
      'street': _streetController.text,
      'phone': _phoneController.text,
      'payment_method': _paymentMethod,
    };

    try {
      final success = await Provider.of<OrdersProvider>(
        context,
        listen: false,
      ).addOrder(cart.items.values.toList(), cart.totalAmount, orderData);

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
      appBar: const CustomAppBar(),
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
                        if (value == null || value.trim().length < 3) {
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
                        if (value.length < 10 ||
                            !RegExp(r'^[0-9]+$').hasMatch(value)) {
                          return 'يرجى إدخال رقم هاتف صحيح (10 أرقام)';
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
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.lightGrey),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          ListTile(
                            title: Text(
                              AppLocalizations.of(
                                context,
                              )!.translate('cash_on_delivery'),
                            ),
                            leading: Radio<String>(
                              value: 'cod',
                              groupValue: _paymentMethod,
                              onChanged: (value) =>
                                  setState(() => _paymentMethod = value!),
                            ),
                            trailing: const Icon(
                              Icons.money,
                              color: AppColors.primary,
                            ),
                            onTap: () => setState(() => _paymentMethod = 'cod'),
                          ),
                          const Divider(height: 1),
                          ListTile(
                            title: Text(
                              AppLocalizations.of(
                                context,
                              )!.translate('credit_card'),
                            ),
                            leading: Radio<String>(
                              value: 'card',
                              groupValue: _paymentMethod,
                              onChanged: (value) =>
                                  setState(() => _paymentMethod = value!),
                            ),
                            trailing: const Icon(
                              Icons.credit_card,
                              color: AppColors.primary,
                            ),
                            onTap: () =>
                                setState(() => _paymentMethod = 'card'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.cardBackground,
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
                                color: Colors.white,
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
      ),
      validator: validator,
    );
  }
}

import 'package:details_app/app_imports.dart';
import 'package:details_app/widgets/custom_loading_overlay.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'package:details_app/providers/addresses_provider.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _cityController = TextEditingController();
  final _streetController = TextEditingController();
  final _phoneController = TextEditingController();
  final _couponController = TextEditingController();
  String _paymentMethod = 'cod'; // cash on delivery
  bool _isLoading = false;
  late AnimationController _rotationController;

  bool _saveAddress = false;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
    _loadSavedData();
  }

  Future<void> _loadSavedData() async {
    // جلب رقم الهاتف من حساب المستخدم إن وجد
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.user != null && auth.user!.phone.isNotEmpty) {
      _phoneController.text = auth.user!.phone;
    }

    if (auth.token != null) {
      await Provider.of<AddressesProvider>(
        context,
        listen: false,
      ).fetchAddresses(auth.token!);
    }
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _cityController.dispose();
    _streetController.dispose();
    _phoneController.dispose();
    _couponController.dispose();
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

    // Capture context-sensitive objects before async operations
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final localizations = AppLocalizations.of(context)!;
    final router = GoRouter.of(context);
    final addressesProvider = Provider.of<AddressesProvider>(
      context,
      listen: false,
    );
    final ordersProvider = Provider.of<OrdersProvider>(context, listen: false);

    final cart = Provider.of<CartProvider>(context, listen: false);
    if (cart.items.isEmpty) return;

    if (_saveAddress) {
      await addressesProvider.addAddress(
        auth.token!,
        _cityController.text.trim(),
        _streetController.text.trim(),
        _phoneController.text.trim(),
      );
    }

    if (!mounted) return;

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
      final success = await ordersProvider.addOrder(orderPayload);

      if (!mounted) return;

      setState(() => _isLoading = false);
      if (success) {
        cart.clear();
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(localizations.translate('order_success')),
            backgroundColor: AppColors.success,
          ),
        );
        router.go('/orders');
      } else {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(localizations.translate('order_failed')),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(localizations.translate('error_occurred')),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    final total = cart.totalAmount;

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
          toolbarHeight: 110,
          title: Image.asset('assets/images/logo2.png', height: 100),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: AppColors.primary),
            onPressed: () => context.pop(),
          ),
          actions: [
            IconButton(
              icon: const Icon(
                Icons.notifications_outlined,
                color: AppColors.primary,
              ),
              onPressed: () {},
            ),
          ],
        ),
        bottomNavigationBar: Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          height: 70,
          decoration: BoxDecoration(
            color: AppColors.homeNavBackground,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _navIcon(
                Icons.home_outlined,
                AppLocalizations.of(context)!.translate('nav_shop'),
                0,
              ),
              _navIcon(
                Icons.search,
                AppLocalizations.of(context)!.translate('nav_search'),
                1,
              ),
              _navIcon(
                Icons.shopping_bag_outlined,
                AppLocalizations.of(context)!.translate('nav_cart'),
                2,
              ),
              _navIcon(
                Icons.favorite_border,
                AppLocalizations.of(context)!.translate('nav_wishlist'),
                3,
              ),
            ],
          ),
        ),
        body: Stack(
          children: [
            Positioned.fill(
              child: Image.asset('assets/images/bg.png', fit: BoxFit.cover),
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

            cart.items.isEmpty
                ? Center(
                    child: Text(
                      AppLocalizations.of(context)!.translate('cart_empty'),
                    ),
                  )
                : SafeArea(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildSectionTitle(context, 'shipping_info'),
                                TextButton(
                                  onPressed: () async {
                                    // الانتقال لصفحة العناوين وانتظار العودة
                                    await context.push('/addresses');
                                    // تحديث قائمة العناوين فور العودة
                                    _loadSavedData();
                                  },
                                  child: Text(
                                    AppLocalizations.of(
                                      context,
                                    )!.translate('saved_addresses'),
                                    style: const TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 15),
                            Consumer<AddressesProvider>(
                              builder: (context, provider, child) {
                                if (provider.addresses.isEmpty) {
                                  return const SizedBox.shrink();
                                }
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(
                                      height: 45,
                                      child: ListView.builder(
                                        scrollDirection: Axis.horizontal,
                                        itemCount: provider.addresses.length,
                                        itemBuilder: (context, index) {
                                          final address =
                                              provider.addresses[index];
                                          return Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 4.0,
                                            ),
                                            child: ActionChip(
                                              label: Text(
                                                '${address.city} - ${address.street}',
                                                style: const TextStyle(
                                                  color: AppColors.primary,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                ),
                                              ),
                                              backgroundColor: const Color(
                                                0xFFFDFBF7,
                                              ),
                                              side: BorderSide(
                                                color: const Color(
                                                  0xFFB89560,
                                                ).withValues(alpha: 0.5),
                                              ),
                                              onPressed: () {
                                                setState(() {
                                                  _cityController.text =
                                                      address.city;
                                                  _streetController.text =
                                                      address.street;
                                                  if (address
                                                      .phone
                                                      .isNotEmpty) {
                                                    _phoneController.text =
                                                        address.phone;
                                                  }
                                                  _saveAddress = false;
                                                });
                                              },
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    const SizedBox(height: 15),
                                  ],
                                );
                              },
                            ),
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: AppColors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.shadowColor,
                                    blurRadius: 10,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  _buildTextField(
                                    controller: _cityController,
                                    label: AppLocalizations.of(
                                      context,
                                    )!.translate('city'),
                                    icon: Icons.location_city,
                                    validator: (value) {
                                      if (value == null ||
                                          value.trim().length < 2) {
                                        return AppLocalizations.of(
                                          context,
                                        )!.translate('enter_valid_city');
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 15),
                                  _buildTextField(
                                    controller: _streetController,
                                    label: AppLocalizations.of(
                                      context,
                                    )!.translate('street'),
                                    icon: Icons.map,
                                    validator: (value) {
                                      if (value == null ||
                                          value.trim().isEmpty) {
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
                                    label: AppLocalizations.of(
                                      context,
                                    )!.translate('phone'),
                                    icon: Icons.phone,
                                    keyboardType: TextInputType.phone,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return AppLocalizations.of(
                                          context,
                                        )!.translate('required_field');
                                      }
                                      if (value.length < 9) {
                                        return AppLocalizations.of(
                                          context,
                                        )!.translate('enter_valid_phone');
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 15),
                                  Row(
                                    children: [
                                      SizedBox(
                                        height: 24,
                                        width: 24,
                                        child: Checkbox(
                                          value: _saveAddress,
                                          onChanged: (val) => setState(
                                            () => _saveAddress = val ?? false,
                                          ),
                                          activeColor: AppColors.primary,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          AppLocalizations.of(
                                            context,
                                          )!.translate(
                                            'save_address_for_later',
                                          ),
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 30),
                            _buildSectionTitle(context, 'payment_method'),
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
                            // Coupon Section
                            Container(
                              margin: const EdgeInsets.only(bottom: 20),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFDFBF7),
                                borderRadius: BorderRadius.circular(16),
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
                                    onPressed: _isLoading
                                        ? null
                                        : () async {
                                            if (_couponController
                                                .text
                                                .isEmpty) {
                                              return;
                                            }

                                            FocusScope.of(context).unfocus();
                                            setState(() => _isLoading = true);
                                            final localizations =
                                                AppLocalizations.of(context)!;
                                            final scaffoldMessenger =
                                                ScaffoldMessenger.of(context);
                                            final success = await cart
                                                .applyCoupon(
                                                  _couponController.text,
                                                );

                                            if (!mounted) return;

                                            setState(() => _isLoading = false);

                                            if (success) {
                                              _couponController.clear();
                                            }
                                            scaffoldMessenger.showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  success
                                                      ? localizations.translate(
                                                          'coupon_applied',
                                                        )
                                                      : localizations.translate(
                                                          'coupon_invalid',
                                                        ),
                                                ),
                                                backgroundColor: success
                                                    ? Colors.green
                                                    : Colors.red,
                                                behavior:
                                                    SnackBarBehavior.floating,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                              ),
                                            );
                                          },
                                    child: Text(
                                      AppLocalizations.of(
                                        context,
                                      )!.translate('apply'),
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: _isLoading
                                            ? Colors.grey
                                            : const Color(0xFF9E773A),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.shadowColor,
                                    blurRadius: 10,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    AppLocalizations.of(
                                      context,
                                    )!.translate('total'),
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    '${total.toStringAsFixed(2)} ${AppLocalizations.of(context)!.translate('currency')}',
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 30),
                            SizedBox(
                              width: double.infinity,
                              height: 55,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _submitOrder,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF9E773A),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 5,
                                  shadowColor: AppColors.primary.withValues(
                                    alpha: 0.3,
                                  ),
                                ),
                                child: Text(
                                  AppLocalizations.of(
                                    context,
                                  )!.translate('confirm_order'),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
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

  Widget _buildSectionTitle(BuildContext context, String key) {
    return Text(
      AppLocalizations.of(context)!.translate(key),
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppColors.primary,
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
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 20,
        ),
        border: InputBorder.none,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFB89560), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF9E773A), width: 2),
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
          color: isSelected ? AppColors.white : AppColors.white,
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.transparent,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            if (!isSelected)
              BoxShadow(
                color: AppColors.shadowColor,
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
          ],
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

  Widget _navIcon(IconData icon, String label, int index) {
    // نعتبر الصفحة الحالية هي السلة (Checkout تابع للسلة)
    final isSelected = index == 2;

    return GestureDetector(
      onTap: () => _onNavTap(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: isSelected
            ? const EdgeInsets.symmetric(horizontal: 12, vertical: 8)
            : const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primary : AppColors.homeNavInactive,
              size: 24,
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _onNavTap(int index) {
    switch (index) {
      case 0:
        context.go('/');
        break;
      case 1:
        context.go('/search');
        break;
      case 2:
        context.go('/cart');
        break;
      case 3:
        context.go('/wishlist');
        break;
    }
  }
}

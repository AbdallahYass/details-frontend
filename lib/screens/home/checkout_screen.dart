import 'package:details_app/app_imports.dart';
import 'package:details_app/widgets/custom_loading_overlay.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'package:details_app/providers/addresses_provider.dart';
import 'package:details_app/providers/notification_provider.dart';
import 'package:details_app/models/address_model.dart'; // 🌟 إضافة الاستيراد المفقود
import 'package:details_app/screens/home/notifications_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _streetController = TextEditingController();
  final _phoneController = TextEditingController();
  final _couponController = TextEditingController();
  String _paymentMethod = 'cod'; // cash on delivery
  bool _isLoading = false;
  late AnimationController _rotationController;

  bool _saveAddress = false;
  String? _selectedCity;
  double _deliveryFee = 0.0;
  bool _isDelivery = true; // true: توصيل, false: استلام من المحل

  // قاموس بأسماء المدن وأسعار التوصيل الخاصة بكل منطقة
  final Map<String, double> _cityFees = {
    // الضفة الغربية (15 شيكل)
    'رام الله': 15.0,
    'البيرة': 15.0,
    'بيتونيا': 15.0,
    'بيرزيت': 15.0,
    'روابي': 15.0,
    'قرى رام الله': 15.0,
    'نابلس': 15.0, 'حوارة': 15.0, 'قرى نابلس': 15.0,
    'الخليل': 15.0,
    'حلحول': 15.0,
    'دورا': 15.0,
    'يطا': 15.0,
    'الظاهرية': 15.0,
    'قرى الخليل': 15.0,
    'جنين': 15.0, 'يعبد': 15.0, 'قباطية': 15.0, 'قرى جنين': 15.0,
    'طولكرم': 15.0, 'عنبتا': 15.0, 'قرى طولكرم': 15.0,
    'قلقيلية': 15.0, 'عزون': 15.0, 'قرى قلقيلية': 15.0,
    'سلفيت': 15.0, 'بديا': 15.0, 'قرى سلفيت': 15.0,
    'طوباس': 15.0, 'طمون': 15.0, 'قرى طوباس': 15.0,
    'أريحا': 15.0, 'العوجا': 15.0, 'قرى أريحا والأغوار': 15.0,
    'بيت لحم': 15.0, 'بيت جالا': 15.0, 'بيت ساحور': 15.0, 'قرى بيت لحم': 15.0,
    'ضواحي القدس (الرام، العيزرية، أبو ديس)': 15.0,

    // القدس (20 شيكل)
    'القدس (داخل الجدار)': 20.0,
    'القدس': 20.0,

    // الداخل المحتل (30 شيكل)
    'الناصرة': 30.0, 'حيفا': 30.0, 'يافا': 30.0, 'عكا': 30.0, 'اللد': 30.0,
    'الرملة': 30.0,
    'بئر السبع': 30.0,
    'صفد': 30.0,
    'طبريا': 30.0,
    'أم الفحم': 30.0,
    'رهط': 30.0,
    'باقة الغربية': 30.0,
    'الطيبة': 30.0,
    'الطيرة': 30.0,
    'شفاعمرو': 30.0,
    'سخنين': 30.0,
    'كفر قاسم': 30.0,
    'قلنسوة': 30.0,
    'عرابة': 30.0,
    'المغار': 30.0,
    'كفر قرع': 30.0,
    'طمرة': 30.0,
    'دالية الكرمل': 30.0,
    'كفر ياسيف': 30.0,
    'جت': 30.0,
    'قرى ومدن الداخل المحتل الأخرى': 30.0,
  };

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
    // تأخير استدعاء البيانات حتى يكتمل بناء الواجهة لتجنب انهيار الشاشة
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadSavedData();
    });
  }

  Future<void> _loadSavedData() async {
    // جلب رقم الهاتف من حساب المستخدم إن وجد
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.user != null && auth.user!.phone.isNotEmpty) {
      _phoneController.text = auth.user!.phone;
    }

    if (auth.isAuthenticated) {
      await Provider.of<AddressesProvider>(
        context,
        listen: false,
      ).fetchAddresses();
    }
  }

  @override
  void dispose() {
    _rotationController.dispose();
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

    if (_saveAddress && _isDelivery) {
      await addressesProvider.addAddress(
        AddressModel(
          id: '', // سيتم توليده في الباك إند
          name: auth.user?.name ?? '',
          city: _selectedCity ?? '',
          street: _streetController.text.trim(),
          phone: _phoneController.text.trim(),
          isDefault: false,
        ),
      );
    }

    if (!mounted) return;

    // منع إرسال الطلب إذا كان الدفع بالبطاقة (حتى يتم ربط بوابة الدفع)
    if (_paymentMethod == 'card') {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(localizations.translate('payment_soon')),
          backgroundColor: AppColors.accent,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    // تجهيز البيانات حسب Schema الباك اند
    final orderPayload = {
      'products': cart.items.values
          .map(
            (cp) => {
              'id': cp.productId, // نرسل ID المنتج الأصلي
              'title': [
                cp.title,
                if (cp.size != null) '(${cp.size})',
                if (cp.color != null) '(${cp.color})',
              ].join(' '),
              'size': cp.size, // إضافة المقاس كحقل منفصل
              'color': cp.color, // إرسال اللون للباك اند
              'quantity': cp.quantity,
              'price': cp.price,
              'imageUrl': cp.imageUrl,
            },
          )
          .toList(),
      'subtotal': cart.subtotal,
      'discountAmount': cart.discountAmount,
      'couponCode': cart.couponCode,
      'deliveryFee': _deliveryFee, // إضافة سعر التوصيل كحقل منفصل
      'amount': cart.totalAmount + _deliveryFee, // المجموع النهائي شامل التوصيل
      'shippingAddress': {
        'city': _isDelivery
            ? (_selectedCity ?? '')
            : localizations.translate('pickup_from_store'),
        'street': _isDelivery
            ? _streetController.text
            : localizations.translate('main_branch'),
        'phone': _phoneController.text,
      },
      'payment_method': _paymentMethod,
    };

    try {
      final success = await ordersProvider.addOrder(orderPayload);

      if (!mounted) return;

      setState(() => _isLoading = false);
      if (success) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(localizations.translate('order_success')),
            backgroundColor: AppColors.success,
          ),
        );
        router.go('/orders');
        // تأخير تنظيف السلة قليلاً لمنع وميض شاشة "السلة فارغة" قبل الانتقال
        Future.delayed(const Duration(milliseconds: 500), () => cart.clear());
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
            Consumer<NotificationProvider>(
              builder: (context, notifProvider, child) {
                return Stack(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.notifications_outlined,
                        color: AppColors.primary,
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const NotificationsScreen(),
                          ),
                        );
                      },
                    ),
                    if (notifProvider.unreadCount > 0)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: AppColors.red,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            '${notifProvider.unreadCount}',
                            style: const TextStyle(
                              color: AppColors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                );
              },
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
              child: Image.asset(
                'assets/images/bg.png',
                fit: BoxFit.cover,
                gaplessPlayback: true,
                cacheWidth: 1080,
                filterQuality: FilterQuality.none,
              ),
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
                            _buildSectionTitle(context, 'delivery_method'),
                            const SizedBox(height: 15),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildDeliveryOption(
                                    value: true,
                                    label: AppLocalizations.of(
                                      context,
                                    )!.translate('delivery'),
                                    icon: Icons.local_shipping_outlined,
                                  ),
                                ),
                                const SizedBox(width: 15),
                                Expanded(
                                  child: _buildDeliveryOption(
                                    value: false,
                                    label: AppLocalizations.of(
                                      context,
                                    )!.translate('pickup'),
                                    icon: Icons.storefront_outlined,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 30),
                            if (_isDelivery) ...[
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  _buildSectionTitle(context, 'shipping_info'),
                                  TextButton(
                                    onPressed: () async {
                                      // الانتقال لصفحة العناوين وانتظار العودة
                                      await context.push('/addresses');
                                      if (!mounted) return;
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                              padding:
                                                  const EdgeInsets.symmetric(
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
                                                    if (_cityFees.containsKey(
                                                      address.city,
                                                    )) {
                                                      _selectedCity =
                                                          address.city;
                                                      _deliveryFee =
                                                          _cityFees[address
                                                              .city]!;
                                                    } else {
                                                      _selectedCity = null;
                                                      _deliveryFee = 0.0;
                                                    }
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
                            ] else ...[
                              _buildSectionTitle(context, 'shipping_info'),
                              const SizedBox(height: 15),
                            ],
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
                                  if (_isDelivery) ...[
                                    _buildCityDropdown(),
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
                                  ],
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
                                  if (_isDelivery) ...[
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
                                    '${AppLocalizations.of(context)!.translate('total')} (${AppLocalizations.of(context)!.translate('products')})',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    '${total.toStringAsFixed(2)} ${AppLocalizations.of(context)!.translate('currency')}',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  AppLocalizations.of(
                                    context,
                                  )!.translate('delivery_fee'),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                Text(
                                  '${_deliveryFee.toStringAsFixed(2)} ${AppLocalizations.of(context)!.translate('currency')}',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 25, thickness: 1),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  AppLocalizations.of(
                                    context,
                                  )!.translate('final_total'),
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                Text(
                                  '${(total + _deliveryFee).toStringAsFixed(2)} ${AppLocalizations.of(context)!.translate('currency')}',
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
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

  Widget _buildCityDropdown() {
    final loc = AppLocalizations.of(context)!;
    List<DropdownMenuItem<String>> items = [];

    // الضفة الغربية
    items.add(
      DropdownMenuItem(
        value: 'header_wb',
        enabled: false,
        child: Text(
          loc.translate('west_bank_header'),
          style: const TextStyle(
            color: Colors.grey,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
    for (var city in [
      'رام الله',
      'البيرة',
      'بيتونيا',
      'بيرزيت',
      'روابي',
      'قرى رام الله',
      'نابلس',
      'حوارة',
      'قرى نابلس',
      'الخليل',
      'حلحول',
      'دورا',
      'يطا',
      'الظاهرية',
      'قرى الخليل',
      'جنين',
      'يعبد',
      'قباطية',
      'قرى جنين',
      'طولكرم',
      'عنبتا',
      'قرى طولكرم',
      'قلقيلية',
      'عزون',
      'قرى قلقيلية',
      'سلفيت',
      'بديا',
      'قرى سلفيت',
      'طوباس',
      'طمون',
      'قرى طوباس',
      'أريحا',
      'العوجا',
      'قرى أريحا والأغوار',
      'بيت لحم',
      'بيت جالا',
      'بيت ساحور',
      'قرى بيت لحم',
      'ضواحي القدس (الرام، العيزرية، أبو ديس)',
    ]) {
      items.add(
        DropdownMenuItem(
          value: city,
          child: Text(
            _getCityTranslation(city, loc),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      );
    }

    // القدس
    items.add(
      DropdownMenuItem(
        value: 'header_j',
        enabled: false,
        child: Text(
          loc.translate('jerusalem_header'),
          style: const TextStyle(
            color: Colors.grey,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
    for (var city in ['القدس (داخل الجدار)', 'القدس']) {
      items.add(
        DropdownMenuItem(
          value: city,
          child: Text(
            _getCityTranslation(city, loc),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      );
    }

    // الداخل المحتل
    items.add(
      DropdownMenuItem(
        value: 'header_48',
        enabled: false,
        child: Text(
          loc.translate('inside_shipping_header'),
          style: const TextStyle(
            color: Colors.grey,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
    for (var city in [
      'الناصرة',
      'حيفا',
      'يافا',
      'عكا',
      'اللد',
      'الرملة',
      'بئر السبع',
      'صفد',
      'طبريا',
      'أم الفحم',
      'رهط',
      'باقة الغربية',
      'الطيبة',
      'الطيرة',
      'شفاعمرو',
      'سخنين',
      'كفر قاسم',
      'قلنسوة',
      'عرابة',
      'المغار',
      'كفر قرع',
      'طمرة',
      'دالية الكرمل',
      'كفر ياسيف',
      'جت',
      'قرى ومدن الداخل المحتل الأخرى',
    ]) {
      items.add(
        DropdownMenuItem(
          value: city,
          child: Text(
            _getCityTranslation(city, loc),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      );
    }

    return DropdownButtonFormField<String>(
      initialValue: _selectedCity,
      icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.primary),
      decoration: InputDecoration(
        labelText: loc.translate('city'),
        prefixIcon: const Icon(Icons.location_city, color: AppColors.primary),
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
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
      ),
      items: items,
      onChanged: (String? newValue) {
        if (newValue != null && !newValue.startsWith('header_')) {
          setState(() {
            _selectedCity = newValue;
            _deliveryFee = _cityFees[newValue] ?? 0.0;
          });
        }
      },
      validator: (value) {
        if (value == null || value.isEmpty || value.startsWith('header_')) {
          return loc.translate('required_field');
        }
        return null;
      },
    );
  }

  String _getCityTranslation(String city, AppLocalizations loc) {
    final Map<String, String> cityKeys = {
      'رام الله': 'ramallah',
      'نابلس': 'nablus',
      'الخليل': 'hebron',
      'القدس': 'jerusalem',
      'حيفا': 'haifa',
    };
    if (cityKeys.containsKey(city)) {
      return loc.translate(cityKeys[city]!);
    }
    return city; // Fallback
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

  Widget _buildDeliveryOption({
    required bool value,
    required String label,
    required IconData icon,
  }) {
    final isSelected = _isDelivery == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _isDelivery = value;
          if (!_isDelivery) {
            _deliveryFee = 0.0;
          } else {
            _deliveryFee = _cityFees[_selectedCity] ?? 0.0;
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
        decoration: BoxDecoration(
          color: AppColors.white,
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
          mainAxisSize: MainAxisSize.min,
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
          // تحديد الحجم ليكون على قدر العناصر فقط لمنع التمدد اللانهائي
          mainAxisSize: MainAxisSize.min,
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

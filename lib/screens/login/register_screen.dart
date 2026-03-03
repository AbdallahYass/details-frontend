import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:details_app/constants/app_colors.dart';
import 'package:details_app/providers/auth_provider.dart';
import 'package:details_app/l10n/app_localizations.dart';
import 'package:details_app/widgets/custom_loading_overlay.dart';
import 'dart:math' as math;

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // Animation Controllers
  late AnimationController _rotationController;
  late AnimationController _entranceController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    // تحريك الخلفية ببطء
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    // أنيميشن دخول العناصر
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _entranceController,
            curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
          ),
        );

    _entranceController.forward();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _entranceController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // 1. إرسال الرمز أولاً
      final success = await authProvider.requestRegisterOtp(
        _nameController.text.trim(),
        _emailController.text.trim(),
        _passwordController.text,
        _phoneController.text.trim(),
      );

      if (mounted) {
        setState(() => _isLoading = false);
        if (success) {
          // 2. التوجيه لشاشة التحقق مع تمرير البيانات
          context.push(
            '/verify-otp',
            extra: {
              'name': _nameController.text.trim(),
              'email': _emailController.text.trim(),
              'phone': _phoneController.text.trim(),
              'password': _passwordController.text,
            },
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                authProvider.errorMessage ??
                    AppLocalizations.of(context)!.translate('error_occurred'),
              ),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: const Color(0xFFFDFBF7),
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

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // الشعار والنصوص
                          Center(
                            child: Container(
                              padding: const EdgeInsets.all(15),
                              child: Image.asset(
                                'assets/images/logo.png',
                                height: 180,
                                width: 180,
                                errorBuilder: (c, _, __) => const Icon(
                                  Icons.account_circle,
                                  size: 200,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 5),
                          Column(
                            children: [
                              Text(
                                'DETAILS',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w300,
                                  color: AppColors.textPrimary,
                                  letterSpacing: 10.0,
                                  height: 1.2,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 30,
                                    height: 1,
                                    color: const Color(0xFFD4AF37),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                    ),
                                    child: Text(
                                      'STORE',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFFD4AF37),
                                        letterSpacing: 3.0,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    width: 30,
                                    height: 1,
                                    color: const Color(0xFFD4AF37),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 30),

                          // حقل الاسم
                          _buildElegantTextField(
                            controller: _nameController,
                            label: AppLocalizations.of(
                              context,
                            )!.translate('name_label'),
                            icon: Icons.person_outline,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return AppLocalizations.of(
                                  context,
                                )!.translate('enter_name');
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // حقل البريد الإلكتروني
                          _buildElegantTextField(
                            controller: _emailController,
                            label: AppLocalizations.of(
                              context,
                            )!.translate('email_label'),
                            icon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return AppLocalizations.of(
                                  context,
                                )!.translate('enter_email');
                              }
                              if (!value.contains('@')) {
                                return AppLocalizations.of(
                                  context,
                                )!.translate('valid_email');
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // حقل الهاتف
                          _buildElegantTextField(
                            controller: _phoneController,
                            label: AppLocalizations.of(
                              context,
                            )!.translate('phone_label'),
                            icon: Icons.phone_android,
                            keyboardType: TextInputType.phone,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return AppLocalizations.of(
                                  context,
                                )!.translate('enter_phone');
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // حقل كلمة المرور
                          _buildElegantTextField(
                            controller: _passwordController,
                            label: AppLocalizations.of(
                              context,
                            )!.translate('password_label'),
                            icon: Icons.lock_outline,
                            obscureText: _obscurePassword,
                            isPassword: true,
                            onTogglePassword: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                            validator: (value) {
                              if (value == null || value.length < 6) {
                                return AppLocalizations.of(
                                  context,
                                )!.translate('short_password');
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // حقل تأكيد كلمة المرور
                          _buildElegantTextField(
                            controller: _confirmPasswordController,
                            label: AppLocalizations.of(
                              context,
                            )!.translate('confirm_password_label'),
                            icon: Icons.lock_outline,
                            obscureText: _obscureConfirmPassword,
                            isPassword: true,
                            onTogglePassword: () {
                              setState(() {
                                _obscureConfirmPassword =
                                    !_obscureConfirmPassword;
                              });
                            },
                            validator: (value) {
                              if (value != _passwordController.text) {
                                return AppLocalizations.of(
                                  context,
                                )!.translate('passwords_not_match');
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 30),

                          // زر التسجيل
                          Container(
                            width: double.infinity,
                            height: 55,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFF9E773A,
                                  ).withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handleRegister,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF9E773A),
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: Text(
                                AppLocalizations.of(
                                  context,
                                )!.translate('register_button'),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 30),

                          // فاصل "أو سجل عبر"
                          Row(
                            children: [
                              Expanded(
                                child: Divider(
                                  color: const Color(
                                    0xFFD4AF37,
                                  ).withValues(alpha: 0.5),
                                  thickness: 1,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 15,
                                ),
                                child: Text(
                                  'أو سجل عبر: / Or Sign Up',
                                  style: const TextStyle(
                                    color: Color(0xFFD4AF37),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Divider(
                                  color: const Color(
                                    0xFFD4AF37,
                                  ).withValues(alpha: 0.5),
                                  thickness: 1,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 25),

                          // أزرار السوشيال ميديا
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildSocialButton(
                                child: const Text(
                                  'G',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF9E773A),
                                  ),
                                ),
                                onPressed: () {},
                              ),
                              const SizedBox(width: 20),
                              _buildSocialButton(
                                child: const Icon(
                                  Icons.apple,
                                  size: 32,
                                  color: Colors.black,
                                ),
                                onPressed: () {},
                              ),
                              const SizedBox(width: 20),
                              _buildSocialButton(
                                child: const Text(
                                  'f',
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF9E773A),
                                  ),
                                ),
                                onPressed: () {},
                              ),
                            ],
                          ),

                          const SizedBox(height: 30),

                          // رابط تسجيل الدخول
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                AppLocalizations.of(
                                  context,
                                )!.translate('have_account'),
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              TextButton(
                                onPressed: () => context.pop(),
                                child: Text(
                                  AppLocalizations.of(
                                    context,
                                  )!.translate('login_link'),
                                  style: const TextStyle(
                                    color: Color(0xFFD4AF37),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (_isLoading) const CustomLoadingOverlay(),
        ],
      ),
    );
  }

  Widget _buildElegantTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    bool isPassword = false,
    VoidCallback? onTogglePassword,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFB89560), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        validator: validator,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Color(0xFF666666), fontSize: 14),
          prefixIcon: Icon(icon, color: const Color(0xFFB89560)),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    obscureText
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: const Color(0xFFB89560),
                  ),
                  onPressed: onTogglePassword,
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 18,
          ),
        ),
      ),
    );
  }

  Widget _buildSocialButton({
    required Widget child,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.white,
          border: Border.all(color: const Color(0xFFB89560), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(child: child),
      ),
    );
  }
}

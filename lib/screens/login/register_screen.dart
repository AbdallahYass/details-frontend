// ignore_for_file: use_build_context_synchronously

import 'package:details_app/app_imports.dart';
import 'package:details_app/widgets/custom_loading_overlay.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'package:google_sign_in/google_sign_in.dart';
import 'web_auth_stub.dart'
    if (dart.library.js_interop) 'package:google_sign_in_web/web_only.dart'
    as web;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

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
  bool _isWebReady = !kIsWeb;

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: kIsWeb
        ? '131777577750-dlj9t8sgpc09a6tnvoh119dt7lc0b4uh.apps.googleusercontent.com'
        : null,
    serverClientId: !kIsWeb
        ? '131777577750-dlj9t8sgpc09a6tnvoh119dt7lc0b4uh.apps.googleusercontent.com'
        : null,
  );

  late AnimationController _rotationController;
  late AnimationController _entranceController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

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

    // الاستماع لعملية تسجيل الدخول (مطلوب جداً للويب)
    _googleSignIn.onCurrentUserChanged.listen((
      GoogleSignInAccount? account,
    ) async {
      if (account != null) {
        await _handleGoogleBackendAuth(account);
      }
    });

    if (kIsWeb) {
      _initWebSafe();
    }
  }

  Future<void> _initWebSafe() async {
    try {
      await _googleSignIn.signInSilently();
    } catch (e) {
      debugPrint("Silent Sign In Error: $e");
    } finally {
      if (mounted) setState(() => _isWebReady = true);
    }
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

  String _translate(String key) {
    return AppLocalizations.of(context)?.translate(key) ?? key;
  }

  Future<void> _handleGoogleBackendAuth(GoogleSignInAccount googleUser) async {
    setState(() => _isLoading = true);
    try {
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      if (googleAuth.idToken == null) {
        await _googleSignIn.disconnect();
        return;
      }

      final response = await http.post(
        Uri.parse('https://api.details-store.com/api/auth/google'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'idToken': googleAuth.idToken}),
      );

      // فحص إذا كان الرد ليس ناجحاً قبل محاولة فك الشفرة (decode)
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final token = data['token'];
        final userData = data['user'];

        if (token != null && userData != null) {
          final authProvider = Provider.of<AuthProvider>(
            context,
            listen: false,
          );
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('token', token);
          await prefs.setString('userData', json.encode(userData));
          await authProvider.tryAutoLogin();
          if (mounted) context.go('/');
        }
      }
      // التعامل مع الحساب المحذوف بهدوء
      else if (response.statusCode == 404) {
        await _googleSignIn.disconnect();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("هذا الحساب غير مسجل، يرجى إنشاء حساب جديد."),
              backgroundColor: Color(0xFF9E773A),
            ),
          );
        }
      } else {
        // في حال وجود خطأ آخر، لا نحاول عمل decode إذا كان الـ body فارغاً
        await _googleSignIn.disconnect();
        String message = "فشل تسجيل الدخول";
        try {
          final errorData = json.decode(response.body);
          message = errorData['message'] ?? message;
        } catch (_) {}
        throw message;
      }
    } catch (error) {
      debugPrint("❌ Login Error: $error");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("خطأ: $error"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // دالة تشغيل تسجيل جوجل للموبايل
  Future<void> _loginWithGoogleMobile() async {
    try {
      await _googleSignIn.signOut();
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser != null) {
        await _handleGoogleBackendAuth(googleUser);
      }
    } catch (error) {
      debugPrint("Google Sign In Mobile Error: $error");
    }
  }

  // تسجيل يدوي (النموذج التقليدي)
  Future<void> _handleRegister() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.requestRegisterOtp(
        _nameController.text.trim(),
        _emailController.text.trim(),
        _passwordController.text,
        _phoneController.text.trim(),
      );

      if (mounted) {
        setState(() => _isLoading = false);
        if (success) {
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
                authProvider.errorMessage ?? _translate('error_occurred'),
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
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        extendBodyBehindAppBar: true,
        backgroundColor: const Color(0xFFFDFBF7),
        body: Stack(
          children: [
            Positioned.fill(
              child: Image.asset('assets/images/bg.png', fit: BoxFit.cover),
            ),
            _buildAnimatedBackground(),
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
                            _buildHeader(),
                            const SizedBox(height: 30),
                            _buildElegantTextField(
                              controller: _nameController,
                              label: _translate('name_label'),
                              icon: Icons.person_outline,
                              validator: (v) =>
                                  v!.isEmpty ? _translate('enter_name') : null,
                            ),
                            const SizedBox(height: 16),
                            _buildElegantTextField(
                              controller: _emailController,
                              label: _translate('email_label'),
                              icon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                              validator: (v) => !v!.contains('@')
                                  ? _translate('valid_email')
                                  : null,
                            ),
                            const SizedBox(height: 16),
                            _buildElegantTextField(
                              controller: _phoneController,
                              label: _translate('phone_label'),
                              icon: Icons.phone_android,
                              keyboardType: TextInputType.phone,
                              validator: (v) =>
                                  v!.isEmpty ? _translate('enter_phone') : null,
                            ),
                            const SizedBox(height: 16),
                            _buildElegantTextField(
                              controller: _passwordController,
                              label: _translate('password_label'),
                              icon: Icons.lock_outline,
                              obscureText: _obscurePassword,
                              isPassword: true,
                              onTogglePassword: () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                              validator: (v) => v!.length < 6
                                  ? _translate('short_password')
                                  : null,
                            ),
                            const SizedBox(height: 16),
                            _buildElegantTextField(
                              controller: _confirmPasswordController,
                              label: _translate('confirm_password_label'),
                              icon: Icons.lock_outline,
                              obscureText: _obscureConfirmPassword,
                              isPassword: true,
                              onTogglePassword: () => setState(
                                () => _obscureConfirmPassword =
                                    !_obscureConfirmPassword,
                              ),
                              validator: (v) => v != _passwordController.text
                                  ? _translate('passwords_not_match')
                                  : null,
                            ),
                            const SizedBox(height: 30),
                            _buildRegisterButton(),
                            const SizedBox(height: 25),
                            _buildSocialSection(),
                            const SizedBox(height: 30),
                            _buildLoginLink(),
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
      ),
    );
  }

  // --- نفس تصميم شاشة الدخول ---
  Widget _buildSocialSection() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            kIsWeb
                ? SizedBox(
                    height: 40,
                    child: _isWebReady
                        ? web.renderButton()
                        : const CircularProgressIndicator(
                            color: Color(0xFFD4AF37),
                          ),
                  )
                : _buildSocialButton(
                    child: const Text(
                      'G',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF9E773A),
                      ),
                    ),
                    onPressed: _loginWithGoogleMobile, // الدخول المباشر
                  ),
            const SizedBox(width: 20),
          ],
        ),
      ],
    );
  }

  // (بقية دوال الـ UI مثل _buildHeader و _buildRegisterButton تبقى كما هي في الكود السابق)
  Widget _buildHeader() {
    return Column(
      children: [
        Image.asset('assets/images/logo.png', height: 120, width: 120),
        const SizedBox(height: 10),
        Text(
          'DETAILS',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w300,
            color: AppColors.textPrimary,
            letterSpacing: 8.0,
          ),
        ),
        Text(
          'STORE',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: const Color(0xFFD4AF37),
            letterSpacing: 3.0,
          ),
        ),
      ],
    );
  }

  Widget _buildRegisterButton() {
    return Container(
      width: double.infinity,
      height: 55,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF9E773A).withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleRegister,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF9E773A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Text(
          _translate('register_button'),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildLoginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          _translate('have_account'),
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        TextButton(
          onPressed: () => context.pop(),
          child: Text(
            _translate('login_link'),
            style: const TextStyle(
              color: Color(0xFFD4AF37),
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAnimatedBackground() {
    return Stack(
      children: [
        Positioned(
          top: -120,
          right: -120,
          child: AnimatedBuilder(
            animation: _rotationController,
            builder: (context, child) => Transform.rotate(
              angle: _rotationController.value * 2 * math.pi,
              child: child,
            ),
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFD4AF37).withValues(alpha: 0.4),
                  width: 2,
                ),
              ),
            ),
          ),
        ),
      ],
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
        ),
        child: Center(child: child),
      ),
    );
  }
}

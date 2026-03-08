// ignore_for_file: use_build_context_synchronously

import 'package:details_app/app_imports.dart';
import 'forgot_password_screen.dart';
import 'package:details_app/widgets/custom_loading_overlay.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _rememberMe = false;

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
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.login(
        _emailController.text.trim(),
        _passwordController.text,
        rememberMe: _rememberMe,
      );

      if (mounted) {
        setState(() => _isLoading = false);
        if (success) {
          if (authProvider.user?.isAdmin == true) {
            context.go('/admin');
          } else {
            context.go('/');
          }
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

  Future<void> _loginWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      debugPrint("🚀 بدأت عملية تسجيل الدخول...");
      final GoogleSignIn googleSignIn = GoogleSignIn(
        serverClientId:
            '131777577750-dlj9t8sgpc09a6tnvoh119dt7lc0b4uh.apps.googleusercontent.com',
        scopes: [
          'email',
          'https://www.googleapis.com/auth/userinfo.profile',
          'openid',
        ],
      );

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        debugPrint("❌ الخطأ: المستخدم لم يفتح النافذة أو أغلقها.");
        return;
      }

      debugPrint("✅ تم اختيار الحساب: ${googleUser.email}");
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      debugPrint(
        "🔑 idToken: ${googleAuth.idToken != null ? 'موجود' : 'فارغ (Null)'}",
      );
      debugPrint(
        "🔑 accessToken: ${googleAuth.accessToken != null ? 'موجود' : 'فارغ (Null)'}",
      );

      if (googleAuth.idToken == null) {
        throw "idToken طلع Null! المشكلة في إعدادات SHA-1 أو الـ Support Email في فايربيس.";
      }

      // 4. إرسال التوكن للباك إند الخاص بك (Node.js)
      final response = await http.post(
        Uri.parse('https://api.details-store.com/api/auth/google'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'idToken': googleAuth.idToken}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final token = data['token'];

        if (token != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('token', token);
          if (mounted) context.go('/');
        }
      } else {
        throw "خطأ من السيرفر (Node.js): ${response.body}";
      }
    } catch (error) {
      debugPrint("Google Login Error: $error");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("خطأ في متجر ديتيلز: $error"),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
              child: Image.asset(
                'assets/images/bg.png',
                fit: BoxFit.cover,
                gaplessPlayback: true,
                cacheWidth: 1080,
              ),
            ),
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
                            SlideTransition(
                              position: _slideAnimation,
                              child: FadeTransition(
                                opacity: _fadeAnimation,
                                child: Column(
                                  children: [
                                    const Text(
                                      'DETAILS',
                                      style: TextStyle(
                                        fontSize: 32,
                                        fontWeight: FontWeight.w300,
                                        color: AppColors.textPrimary,
                                        letterSpacing: 12.0,
                                        height: 1.2,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          width: 40,
                                          height: 1,
                                          color: const Color(0xFFD4AF37),
                                        ),
                                        const Padding(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 12,
                                          ),
                                          child: Text(
                                            'STORE',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFFD4AF37),
                                              letterSpacing: 4.0,
                                            ),
                                          ),
                                        ),
                                        Container(
                                          width: 40,
                                          height: 1,
                                          color: const Color(0xFFD4AF37),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
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
                                if (value == null || value.isEmpty) {
                                  return AppLocalizations.of(
                                    context,
                                  )!.translate('enter_password');
                                }
                                if (value.length < 6) {
                                  return AppLocalizations.of(
                                    context,
                                  )!.translate('short_password');
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Checkbox(
                                  value: _rememberMe,
                                  activeColor: const Color(0xFF9E773A),
                                  checkColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  side: const BorderSide(
                                    color: Color(0xFF9E773A),
                                    width: 1.5,
                                  ),
                                  onChanged: (value) {
                                    setState(() {
                                      _rememberMe = value ?? false;
                                    });
                                  },
                                ),
                                Text(
                                  AppLocalizations.of(
                                    context,
                                  )!.translate('remember_me'),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF9E773A),
                                    fontSize: 14,
                                  ),
                                ),
                                const Spacer(),
                                TextButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const ForgotPasswordScreen(),
                                      ),
                                    );
                                  },
                                  child: Text(
                                    AppLocalizations.of(
                                      context,
                                    )!.translate('forgot_password'),
                                    style: const TextStyle(
                                      color: Color(0xFF9E773A),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
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
                                onPressed: _isLoading ? null : _handleLogin,
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
                                  )!.translate('login_button'),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 15),
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
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 15),
                                  child: Text(
                                    'أو سجل عبر: / Or Sign In',
                                    style: TextStyle(
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
                            const SizedBox(height: 15),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // تم ربط زر جوجل هنا 👇
                                _buildSocialButton(
                                  child: const Text(
                                    'G',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF9E773A),
                                    ),
                                  ),
                                  onPressed: _loginWithGoogle,
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
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  AppLocalizations.of(
                                    context,
                                  )!.translate('no_account'),
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    context.push('/register');
                                  },
                                  child: Text(
                                    AppLocalizations.of(
                                      context,
                                    )!.translate('create_account_link'),
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

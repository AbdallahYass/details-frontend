import 'package:details_app/app_imports.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    // تأثير الظهور التدريجي
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.8, curve: Curves.easeIn),
      ),
    );

    // تأثير التكبير المرن للشعار (نبض خفيف)
    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    // تأثير الانزلاق للنصوص السفلية
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.3, 1.0, curve: Curves.easeOutQuart),
          ),
        );

    _controller.forward();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    // انتظار انتهاء الأنيميشن أو وقت محدد
    await Future.delayed(const Duration(seconds: 4));
    if (!mounted) return;

    final auth = Provider.of<AuthProvider>(context, listen: false);

    // التحقق من حالة تسجيل الدخول والتوجيه
    if (auth.token != null && auth.token.toString().isNotEmpty) {
      context.go('/');
    } else {
      // التوجيه لصفحة تسجيل الدخول (تأكد من أن المسار /login معرف لديك في الراوتر)
      try {
        context.go('/login');
      } catch (e) {
        context.go('/');
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFFFFFF), // أبيض نقي
              Color(0xFFF5F3EB), // بيج دافئ جداً (Creamy Paper)
            ],
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // خلفية جمالية (توهج ذهبي خافت في الأعلى)
            Positioned(
              top: -150,
              right: -150,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Container(
                  width: 400,
                  height: 400,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFFD4AF37).withValues(alpha: 0.1), // ذهبي
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // دائرة سفلية بلون البراند
            Positioned(
              bottom: -100,
              left: -100,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withValues(alpha: 0.03),
                  ),
                ),
              ),
            ),

            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // الشعار بتصميم نظيف وظل ناعم جداً
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Container(
                        padding: const EdgeInsets.all(25),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.white,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.black.withValues(alpha: 0.05),
                              blurRadius: 40,
                              spreadRadius: 0,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Image.asset(
                          'assets/images/logo2.png',
                          height: 130,
                          width: 130,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 50),

                  // النصوص بتصميم فاخر (تباعد أحرف كبير)
                  SlideTransition(
                    position: _slideAnimation,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Column(
                        children: [
                          Text(
                            'DETAILS',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w300, // خط رفيع
                              color: AppColors.textPrimary,
                              letterSpacing: 8.0, // تباعد كبير للأناقة
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'STORE',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFFD4AF37), // لون ذهبي
                              letterSpacing: 4.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // مؤشر التحميل في الأسفل
            Positioned(
              bottom: 60,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Color(0xFFD4AF37), // ذهبي
                    strokeWidth: 1.5,
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

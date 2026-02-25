import 'package:details_app/app_imports.dart';
import 'package:video_player/video_player.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _isNavigated = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      _controller = VideoPlayerController.asset(
        'assets/videos/splash_video.mp4',
      );

      // 1. مهلة زمنية للتهيئة (إذا كان النت أو الجهاز بطيئاً)
      await _controller.initialize().timeout(const Duration(seconds: 4));

      await _controller.setVolume(0.0); // ضروري جداً للأيفون
      await _controller.setLooping(false);

      if (mounted) {
        setState(() => _isInitialized = true);

        // 2. محاولة تشغيل الفيديو
        await _controller.play();

        // 3. الحل الذكي لوضع توفير الطاقة:
        // ننتظر ثانية واحدة ونفحص.. هل الفيديو شغال فعلاً؟
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted && !_controller.value.isPlaying) {
            // إذا لم يبدأ الفيديو (غالباً بسبب Low Power Mode في الأيفون)
            debugPrint(
              "Autoplay blocked: Low Power Mode detected or Safari restriction.",
            );
            _navigateToNextScreen(); // ننتقل فوراً بدل التعليق
          }
        });

        _controller.addListener(_videoListener);
      }
    } catch (e) {
      // في حال حدوث أي خطأ (مثل عدم دعم الصيغة أو تأخر التحميل)
      _navigateToNextScreen();
    }
  }

  void _videoListener() {
    if (!mounted) return;

    // التحقق من انتهاء الفيديو أو حدوث خطأ
    if (_controller.value.hasError) {
      debugPrint("Video Error: ${_controller.value.errorDescription}");
      _navigateToNextScreen();
    }

    // إذا وصل الفيديو للنهاية
    if (_controller.value.position >= _controller.value.duration) {
      _navigateToNextScreen();
    }
  }

  void _navigateToNextScreen() {
    if (!mounted || _isNavigated) return;
    _isNavigated = true;

    // إيقاف المستمع قبل الانتقال
    _controller.removeListener(_videoListener);

    // الانتقال للصفحة الرئيسية
    context.go('/');
  }

  @override
  void dispose() {
    // إلغاء المستمع والتخلص من المتحكم بشكل آمن
    _controller.removeListener(_videoListener);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // لون خلفية التطبيق
      body: Stack(
        alignment: Alignment.center,
        children: [
          // 1. صورة اللوجو (تظهر دائماً كخلفية احتياطية)
          // إذا لم يعمل الفيديو، ستكون هذه الصورة هي الظاهرة للمستخدم
          Center(
            child: Image.asset(
              'assets/icons/logo2.png', // مسار اللوجو تبعك
              width: 200, // تحكم في حجم اللوجو بما يناسبك
              fit: BoxFit.contain,
            ),
          ),

          // 2. الفيديو (يظهر فوق الصورة إذا اشتغل)
          if (_isInitialized)
            SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.contain,
                child: SizedBox(
                  width: _controller.value.size.width,
                  height: _controller.value.size.height,
                  child: VideoPlayer(_controller),
                ),
              ),
            ),

          // 3. مؤشر التحميل (يظهر فقط حتى يتم تهيئة الفيديو)
          if (!_isInitialized)
            const Positioned(
              bottom: 50,
              child: CircularProgressIndicator(color: AppColors.primary),
            ),

          // 4. زر التخطي
          Positioned(
            top: MediaQuery.of(context).padding.top + 20,
            right: 20,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _navigateToNextScreen,
                borderRadius: BorderRadius.circular(30),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text(
                        'Skip',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(width: 6),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: Colors.white,
                        size: 12,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

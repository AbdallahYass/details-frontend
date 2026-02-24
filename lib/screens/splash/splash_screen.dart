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
      // استخدم لون خلفية الفيديو (أبيض مثلاً) عشان لو الشاشة أعرض من الفيديو ما تلاحظ فرق
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          if (_isInitialized)
            SizedBox.expand(
              // يخلي المساحة كامل الشاشة
              child: FittedBox(
                fit: BoxFit.contain, // الحل هنا: يعرض الفيديو كامل بدون أي قص
                child: SizedBox(
                  width: _controller.value.size.width,
                  height: _controller.value.size.height,
                  child: VideoPlayer(_controller),
                ),
              ),
            )
          else
            const Center(child: CircularProgressIndicator()),

          // زر التخطي
          Positioned(
            top: 40,
            right: 20,
            child: TextButton(
              onPressed: _navigateToNextScreen,
              child: const Text('Skip', style: TextStyle(color: Colors.grey)),
            ),
          ),
        ],
      ),
    );
  }
}

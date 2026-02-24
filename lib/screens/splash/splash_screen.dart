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
        // إضافة هذه الإعدادات خصيصاً لـ Safari والويب
        videoPlayerOptions: VideoPlayerOptions(
          allowBackgroundPlayback: false,
          mixWithOthers: true,
        ),
      );

      await _controller.initialize();

      // إعدادات ضرورية جداً للايفون
      await _controller.setVolume(0.0); // كتم الصوت إجباري للـ Autoplay
      await _controller.setLooping(false);

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });

        // في الويب و Safari، يفضل البدء بالتشغيل فوراً بعد الـ Initialize
        await _controller.play();

        _controller.addListener(_videoListener);
      }
    } catch (e) {
      debugPrint('Error: $e');
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
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // عرض الفيديو لملء كامل الشاشة
          if (_isInitialized)
            SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover, // يضمن ملء الشاشة بالكامل مثل خلفية الموبايل
                child: SizedBox(
                  width: _controller.value.size.width,
                  height: _controller.value.size.height,
                  child: VideoPlayer(_controller),
                ),
              ),
            )
          else
            const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),

          // زر التخطي (Skip)
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            right: 20,
            child: TextButton(
              onPressed: _navigateToNextScreen,
              style: TextButton.styleFrom(
                backgroundColor: Colors.black26, // خلفية خفيفة لضمان الرؤية
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text(
                'Skip',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

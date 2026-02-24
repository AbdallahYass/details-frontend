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

      await _controller.initialize();
      await _controller.setVolume(0.0); // كتم الصوت يساعد في بدء الفيديو فوراً

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
        await _controller.play();
      }

      _controller.addListener(() {
        // التحقق من انتهاء الفيديو
        if (_controller.value.isInitialized &&
            !_controller.value.isPlaying &&
            _controller.value.position >= _controller.value.duration) {
          _navigateToNextScreen();
        }
      });
    } catch (e) {
      debugPrint('Error initializing video splash: $e');
      // في حال فشل الفيديو، ننتقل مباشرة
      _navigateToNextScreen();
    }
  }

  void _navigateToNextScreen() {
    if (!mounted || _isNavigated) return;
    _isNavigated = true;
    context.go('/');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(
            child: _isInitialized
                ? AspectRatio(
                    aspectRatio: _controller.value.aspectRatio,
                    child: VideoPlayer(_controller),
                  )
                : const CircularProgressIndicator(color: AppColors.primary),
          ),
          Positioned(
            top: 50,
            right: 20,
            child: TextButton(
              onPressed: _navigateToNextScreen,
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

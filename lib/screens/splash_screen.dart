import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:appwrite/appwrite.dart';
import 'login_screen.dart';
import 'sign_screen.dart';
import 'home_screen.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SplashScreen extends StatefulWidget {
  final bool isFirstRun;
  final Client client;

  const SplashScreen({required this.isFirstRun, required this.client, super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late VideoPlayerController _videoController;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: [SystemUiOverlay.top]);

    // Initialize the video controller
    _videoController = VideoPlayerController.asset('assets/videos/longsplash.mp4')
      ..initialize().then((_) {
        setState(() {}); // Ensure the first frame is shown after the video is initialized
        _videoController.setVolume(0); // Mute the video
        _videoController.play();
      }).catchError((error) {
        print("Error initializing video player: $error");
      });

    // Initialize the animation controller
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    // Define the fade animation
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    // Start the splash screen
    _startSplashScreen();
  }

  void _startSplashScreen() async {
    await Future.delayed(const Duration(milliseconds: 3000));
    _animationController.forward();
    // Add a listener to navigate to the next screen after the animation completes
    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _navigateToNextScreen();
      }
    });
  }

  void _navigateToNextScreen() async {
    final storage = FlutterSecureStorage();
    String? sessionId = await storage.read(key: 'sessionId'); // Add await here

    if (sessionId!= null) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => HomeScreen(client: widget.client, sessionId: sessionId),
          transitionsBuilder: (context, animation, secondaryAnimation, child) => FadeTransition(opacity: animation, child: child),
        ),
      );
    } else {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => LoginPage(client: widget.client),
          transitionsBuilder: (context, animation, secondaryAnimation, child) => FadeTransition(opacity: animation, child: child),
        ),
      );
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _videoController.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: SystemUiOverlay.values);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          if (_videoController.value.isInitialized)
            Positioned.fill(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _videoController.value.size.width,
                  height: _videoController.value.size.height,
                  child: VideoPlayer(_videoController),
                ),
              ),
            ),
          FadeTransition(
            opacity: _fadeAnimation,
            child: Container(
              color: Colors.transparent,
            ),
          ),
        ],
      ),
    );
  }
}
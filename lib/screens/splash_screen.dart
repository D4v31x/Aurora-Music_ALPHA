import 'package:appwrite/appwrite.dart';
import 'package:flutter/material.dart';
import 'package:rive/rive.dart';
import 'package:video_player/video_player.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart';
import 'welcome_screen.dart';

class SplashScreen extends StatefulWidget {
  final Client client;

  const SplashScreen({super.key, required this.client});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late VideoPlayerController _videoController;
  late RiveAnimationController _riveController;
  bool _isRiveCompleted = false;
  bool _isVideoInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  void _initializeVideo() {
    _videoController = VideoPlayerController.asset("assets/videos/Back.mp4")
      ..initialize().then((_) {
        setState(() {
          _videoController.play();
          _videoController.setLooping(true);
          _isVideoInitialized = true;
        });
      });

    _riveController = SimpleAnimation('Timeline 2');
    _riveController.isActiveChanged.addListener(_onRiveAnimationCompleted);
  }

  void _onRiveAnimationCompleted() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_riveController.isActive) {
        setState(() {
          _isRiveCompleted = true;
        });
        _navigateToWelcomeScreen();
      }
    });
  }

  void _navigateToWelcomeScreen() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation1, animation2) => WelcomeScreen(client: widget.client),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = 0.0;
          const end = 1.0;
          final curvedAnimation = CurvedAnimation(parent: animation, curve: Curves.easeInOut);

          return FadeTransition(
            opacity: Tween(begin: begin, end: end).animate(curvedAnimation),
            child: child,
          );
        },
        transitionDuration: const Duration(seconds: 2),
      ),
    );
  }


  @override
  void dispose() {
    _videoController.dispose();
    _riveController.isActiveChanged.removeListener(_onRiveAnimationCompleted);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isVideoInitialized
          ? Stack(
        children: [
          VideoPlayer(_videoController),
          Center(
            child: RiveAnimation.asset(
              "assets/animations/untitled.riv",
              controllers: [_riveController],
            ),
          ),
        ],
      )
          : Center(child: CircularProgressIndicator()),
    );
  }
}

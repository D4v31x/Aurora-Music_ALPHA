import 'package:appwrite/appwrite.dart';
import 'package:flutter/material.dart';
import 'package:rive/rive.dart';
import 'package:permission_handler/permission_handler.dart' as handler;
import 'package:video_player/video_player.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart';

class WelcomeScreen extends StatefulWidget {
  final Client client;

  const WelcomeScreen({super.key, required this.client});

  @override
  _WelcomeScreenState createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  late VideoPlayerController _videoController;
  late RiveAnimationController _riveController;
  late RiveAnimationController _permissionRiveController;

  @override
  void initState() {
    super.initState();
    _checkFirstRun();
  }

  Future<void> _checkFirstRun() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isFirstRun = prefs.getBool('isFirstRun') ?? true;

    if (isFirstRun) {
      await prefs.setBool('isFirstRun', false);
      _initializeVideo();
      _initializeRive();
    } else {
      _navigateToHome();
    }
  }

  void _initializeVideo() {
    _videoController = VideoPlayerController.asset("assets/videos/Back.mp4")
      ..initialize().then((_) {
        setState(() {
          _videoController.play();
          _videoController.setLooping(true);
        });
      });
  }

  void _initializeRive() {
    _riveController = SimpleAnimation('Timeline 1'); // Adjust to match your Rive animation
  }

  Future<void> _checkPermissions() async {
    var audioPermissionStatus = await handler.Permission.audio.status;
    if (!audioPermissionStatus.isGranted) {
      audioPermissionStatus = await handler.Permission.audio.request();
    }

    var storagePermissionStatus = await handler.Permission.storage.status;
    if (!storagePermissionStatus.isGranted) {
      storagePermissionStatus = await handler.Permission.storage.request();
    }

    var notificationPermissionStatus = await handler.Permission.notification.status;
    if (!notificationPermissionStatus.isGranted) {
      notificationPermissionStatus = await handler.Permission.notification.request();
    }

    if ((audioPermissionStatus.isGranted || storagePermissionStatus.isGranted) &&
        notificationPermissionStatus.isGranted) {
      _showPermissionResultAnimation('assets/animations/permiss.riv');
    } else {
      _showPermissionResultAnimation('assets/animations/nopermiss.riv');
    }
  }

  void _showPermissionResultAnimation(String riveAsset) {
    setState(() {
      _permissionRiveController = SimpleAnimation('Timeline 1'); // Adjust to match your Rive animation
    });
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Center(
          child: SizedBox(
            width: 800, // Adjust as needed
            height: 800, // Adjust as needed
            child: RiveAnimation.asset(
              riveAsset,
              controllers: [_permissionRiveController],
              onInit: (_) => Future.delayed(
                const Duration(seconds: 6), // Adjust to match animation length
                _navigateToHome,
              ),
            ),
          ),
        );
      },
    );
  }

  void _navigateToHome() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => HomeScreen(client: widget.client),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          var begin = 0.0;
          var end = 1.0;
          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: Curves.easeInOut));
          var fadeAnimation = animation.drive(tween);

          return FadeTransition(
            opacity: fadeAnimation,
            child: child,
          );
        },
        transitionDuration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SizedBox.expand(
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _videoController.value.size.width ?? 0,
                height: _videoController.value.size.height ?? 0,
                child: VideoPlayer(_videoController),
              ),
            ),
          ),
          Center(
            child: SizedBox(
              width: 800, // Adjust as needed
              height: 800, // Adjust as needed
              child: RiveAnimation.asset(
                'assets/animations/welcome.riv',
                controllers: [_riveController],
                onInit: (_) => Future.delayed(
                  const Duration(seconds: 6), // Adjust to match animation length
                  _checkPermissions,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _videoController.dispose();
    super.dispose();
  }
}

import 'package:aurora_music_v01/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  /*
  @override
  State<SplashScreen> createState() => _SplashScreenState();
  */

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: [SystemUiOverlay.top]);

    Future.delayed(const Duration(seconds: 1), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => LoginPage(),
        )
      );
    });

  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: SystemUiOverlay.values);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = MediaQuery.of(context).platformBrightness == Brightness.dark;

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.transparent,
          image: DecorationImage(
            image: AssetImage(isDarkMode? 'assets/images/background/dark_back.jpg' : 'assets/images/background/light_back.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Align(
              alignment: Alignment.center,
              child: Column(
                children: [
                  Image(
                    image: AssetImage('assets/images/logo/Music_logo.png'),
                    height: 150,
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Aurora Music',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontStyle: FontStyle.normal,
                      color:Colors.white,
                      fontSize: 48,
                      fontWeight: FontWeight.normal
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 50),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Developed by',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontStyle: FontStyle.normal,
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.normal
                  ),
                ),
                SizedBox(width: 10),
                Image(
                  image: AssetImage('assets/images/logo/Aurora_logo.png'),
                  height: 20,
                ),
              ],
            ),
            SizedBox(height: 0), // Add this line to add margin/padding from bottom
          ],
        ),
      ),
    );
  }
}
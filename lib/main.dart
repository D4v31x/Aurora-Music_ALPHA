import 'package:aurora_music_v01/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:appwrite/appwrite.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize SharedPreferences
  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool isFirstRun = prefs.getBool('isFirstRun')?? true;

  // Initialize Appwrite Client
  Client client = Client()
    ..setEndpoint('https://cloud.appwrite.io/v1')
    ..setProject('663e1a92003d390b8b2f');

  runApp(MyApp(isFirstRun: isFirstRun, client: client));
}

class MyApp extends StatelessWidget {
  final bool isFirstRun;
  final Client client;

  MyApp({required this.isFirstRun, required this.client});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SplashScreen(isFirstRun: isFirstRun, client: client),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:rive/rive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:appwrite/appwrite.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'localization/app_localizations.dart';
import 'screens/splash_screen.dart';
import 'dart:ui' as ui;
import 'locale_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool isFirstRun = prefs.getBool('isFirstRun') ?? true;
  await RiveFile.initialize();

  Client client = Client()
    ..setEndpoint('https://cloud.appwrite.io/v1')
    ..setProject('663e1a92003d390b8b2f');

  String? languageCode = prefs.getString('languageCode') ?? 'en';

  runApp(MyApp(isFirstRun: isFirstRun, client: client, languageCode: languageCode));
}

class MyApp extends StatefulWidget {
  final bool isFirstRun;
  final Client client;
  final String languageCode;

  const MyApp({super.key, required this.isFirstRun, required this.client, required this.languageCode});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late ui.Locale _locale;

  @override
  void initState() {
    super.initState();
    _locale = ui.Locale(widget.languageCode);
  }

  void setLocale(ui.Locale locale) {
    setState(() {
      _locale = locale;
    });
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString('languageCode', locale.languageCode);
    });
  }

  @override
  Widget build(BuildContext context) {
    return LocaleProvider(
      locale: _locale,
      setLocale: setLocale,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        locale: _locale,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          ui.Locale('en', ''),
          ui.Locale('cs', ''),
        ],
        home: SplashScreen(isFirstRun: widget.isFirstRun, client: widget.client),
      ),
    );
  }
}

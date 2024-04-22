import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:aurora_music_v01/screens/splash_screen.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final supabaseFuture = Supabase.initialize(
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndiY3dydm9vd29oemZqdnp0YnB0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3MTM3MzQ0NTAsImV4cCI6MjAyOTMxMDQ1MH0.f0ueAhNouXS4LYfNEocaGguapkUFlif4jqoQbn8ANZ0',
    url: 'https://wbcwrvoowohzfjvztbpt.supabase.co',
  );

  runApp(FutureBuilder(
    future: supabaseFuture,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.done) {
        return MyApp();
      } else {
        return CircularProgressIndicator();
      }
    },
  ));
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SplashScreen(),
    );
  }
}
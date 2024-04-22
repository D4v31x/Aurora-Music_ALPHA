import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:aurora_music_v01/screens/splash_screen.dart';
import 'package:aurora_music_v01/version_checker.dart'; // Add this import statement
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart'; // Add this import statement
import 'package:url_launcher/url_launcher.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final supabaseFuture = Supabase.initialize(
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndiY3dydm9vd29oemZqdnp0YnB0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3MTM3MzQ0NTAsImV4cCI6MjAyOTMxMDQ1MH0.f0ueAhNouXS4LYfNEocaGguapkUFlif4jqoQbn8ANZ0',
    url: 'https://wbcwrvoowohzfjvztbpt.supabase.co',
  );

  final PackageInfo packageInfo = await PackageInfo.fromPlatform();
  String currentVersion = packageInfo.version;

  runApp(FutureBuilder(
    future: supabaseFuture,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.done) {
        _checkForNewVersion(context, currentVersion); // Call the function here
        return MyApp();
      } else {
        return CircularProgressIndicator();
      }
    },
  ));
}

Future<void> _checkForNewVersion(BuildContext context, String currentVersion) async {
  String? newVersion = await VersionChecker.checkForNewVersion();
  if (newVersion != null && newVersion.isNotEmpty) {
    if (newVersion != currentVersion) {
      String githubReleaseUrl = 'https://github.com/D4v31x/Aurora-Music_ALPHA_RELEASES/releases';
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('New version available'),
            content: Text('A new version ($newVersion) of the app is available. Please update to the latest version.'),
            actions: <Widget>[
              TextButton(
                child: Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop();
                  launchUrl(Uri.parse(githubReleaseUrl)); // Add this line to open the GitHub release page
                },
              ),
            ],
          );
        },
      );
    }
  }
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
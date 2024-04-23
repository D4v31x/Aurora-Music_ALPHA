import 'dart:convert';
import 'package:aurora_music_v01/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:version/version.dart';
import 'package:url_launcher/url_launcher.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late bool isDarkMode;
  bool isWelcomeBackVisible = true;
  bool isAuroraMusicVisible = false;
  User? user;
  Version? latestVersion;

  @override
  void initState() {
    super.initState();
    user = Supabase.instance.client.auth.currentUser;  //FirebaseAuth.instance.currentUser;
    checkForNewVersion();
  }

  Future<void> checkForNewVersion() async {
    try {
      final response = await http.get(Uri.parse('https://api.github.com/repos/D4v31x/Aurora-Music_ALPHA_RELEASES/releases/latest'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final versionString = data['tag_name'];
        final regex = RegExp(r'^v?(\d+\.\d+\.\d+(-\S+)?)$');
        final match = regex.firstMatch(versionString);
        if (match != null && match.groupCount > 0) {
          final versionString = match.group(1)!;
          setState(() {
            latestVersion = Version.parse(versionString);
          });
        }
      }
    } catch (e) {
      print('Error fetching latest version: $e');
    }
  }

void launchURL(String url) async {
  if (await canLaunch(url)) {
    try {
      await launch(url);
    } catch (e) {
      print('Error launching URL: $e');
    }
  } else {
    throw 'Could not launch $url';
  }
}
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    isDarkMode = MediaQuery.of(context).platformBrightness == Brightness.dark;
  }

  @override
  Widget build(BuildContext context) {
    final regex = RegExp(r'^v?(\d+\.\d+\.\d+)(-[a-zA-Z]+)?$');
    final match = regex.firstMatch('v0.0.1-alpha');
    final currentVersion = Version.parse(match!.group(1)!);
    final isUpdateAvailable = latestVersion != null && latestVersion!.compareTo(currentVersion) > 0;

    if (isUpdateAvailable) {
  Future.delayed(Duration.zero, () {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('New version available'),
          content: const Text('A new version of Aurora Music is available. Would you like to download it now?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
  onPressed: () async {
    Navigator.pop(context);
    await launch('https://github.com/D4v31x/Aurora-Music_ALPHA_RELEASES/releases/latest'); // Replace this line
  },
  child: const Text('Download'),
),
          ],
        );
      },
    );
  });
}

    return user == null
       ? LoginPage()
        : Stack(
            children: [
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  image: DecorationImage(
                    image: AssetImage(isDarkMode
                       ? 'assets/images/background/dark_back.jpg'
                        : 'assets/images/background/light_back.jpg'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0.0,
                toolbarHeight: 230,
              automaticallyImplyLeading: false,
                title: Center(
                  child: Stack(
                    children: [
                      AnimatedOpacity(
                        opacity: isWelcomeBackVisible? 1.0 : 0.0,
                        duration: const Duration(seconds: 1),
                        child: const Text(
                          ' Welcome Back',
                          style: TextStyle(
                              fontFamily: 'Outfit',
                              fontStyle: FontStyle.normal,
                              color: Colors.white,
                              fontSize: 34,
                             fontWeight: FontWeight.normal),
                        ),
                      ),
                      AnimatedOpacity(
                        opacity: isAuroraMusicVisible? 1.0 : 0.0,
                        duration: const Duration(seconds: 1),
                        child: const Text(
                          '   Aurora Music',
                          style: TextStyle(
                              fontFamily: 'Outfit',
                              fontStyle: FontStyle.normal,
                              color: Colors.white,
                              fontSize: 34,
                              fontWeight: FontWeight.normal),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(
                height: 50,
              ),
              const Center(
                child: Text(
                  'App is under construction. Come back later!',
                  style: TextStyle(
                      fontFamily: 'Outfit',
                      fontStyle: FontStyle.normal,
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.normal),
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: ElevatedButton(
                  onPressed: () async {
                    await Supabase.instance.client.auth.signOut();
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => LoginPage()),
                    );
                  },
                  child: Text(
                    'Log out',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontStyle: FontStyle.normal,
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ),
              ),
            ],
          );
  }
}

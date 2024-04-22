import 'package:aurora_music_v01/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

  @override
  void initState() {
    super.initState();
    user = FirebaseAuth.instance.currentUser;

    Future.delayed(const Duration(milliseconds: 1500), () {
      setState(() {
        isWelcomeBackVisible = false;
      });
    });

    Future.delayed(const Duration(milliseconds: 2500), () {
      setState(() {
        isAuroraMusicVisible = true;
      });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    isDarkMode = MediaQuery.of(context).platformBrightness == Brightness.dark;
  }

  @override
  Widget build(BuildContext context) {
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
                    await FirebaseAuth.instance.signOut();
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
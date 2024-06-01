import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'sign_screen.dart';
import 'home_screen.dart';
import 'home_screen_ads.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:version/version.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LoginPage extends StatefulWidget {
  final Client client;

  LoginPage({required this.client});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  late String email;
  late String password;
  late bool isDarkMode;
  String? _error;
  late ScrollController _scrollController;
  final emailFocusNode = FocusNode();
  Version? latestVersion;

  final _formKey = GlobalKey<FormState>();
  final Connectivity _connectivity = Connectivity();
  late Account account;
  final secureStorage = FlutterSecureStorage();

  bool _isPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    account = Account(widget.client);
    checkForNewVersion();
    WidgetsBinding.instance.addPostFrameCallback((_) {});
    _connectivity.onConnectivityChanged.listen((List<ConnectivityResult> results) {
      setState(() {
        _error = results.contains(ConnectivityResult.none) ? 'No internet connection' : null;
      });
    });
    _scrollController = ScrollController();
    isDarkMode = true;
    emailFocusNode.addListener(() {
      if (emailFocusNode.hasFocus) {
        _scrollToFormField(context, emailFocusNode.context!.findAncestorWidgetOfExactType<TextFormField>()!);
      }
    });
  }

  Future<void> _resetPassword() async {
    try {
      await account.createRecovery(email: email, url: 'https://your-app-url/reset-password');
      _showErrorDialog(context, 'Password reset email sent');
    } catch (e) {
      _showErrorDialog(context, 'Error resetting password: $e');
    }
  }

  void _scrollToFormField(BuildContext context, TextFormField formField) {
    final RenderBox? box = context.findRenderObject() as RenderBox?;
    if (box != null) {
      final Offset position = box.localToGlobal(Offset.zero);
      final double screenHeight = MediaQuery.of(context).size.height;
      final double scrollPosition = position.dy - (screenHeight * 0.1);
      _scrollController.animateTo(
        scrollPosition,
        duration: Duration(milliseconds: 500),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _storeSessionId(String sessionId) async {
    final storage = FlutterSecureStorage();
    await storage.write(key: 'sessionId', value: sessionId);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    isDarkMode = MediaQuery.of(context).platformBrightness == Brightness.dark;
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
  Widget build(BuildContext context) {
    isDarkMode = MediaQuery.of(context).platformBrightness == Brightness.dark;
    final regex = RegExp(r'^v?(\d+\.\d+\.\d+)(-\S+)?$');
    final match = regex.firstMatch('v0.0.6-alpha');
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
                    await launch('https://github.com/D4v31x/Aurora-Music_ALPHA_RELEASES/releases/latest');
                  },
                  child: const Text('Download'),
                ),
              ],
            );
          },
        );
      });
    }

    return Scaffold(
      backgroundColor: isDarkMode ? Color(0xFF1A1A1D) : Color(0xFFE5E5E5),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(isDarkMode ? 'assets/images/background/dark_back.jpg' : 'assets/images/background/light_back.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          SingleChildScrollView(
            controller: _scrollController,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0.0,
                  toolbarHeight: 340,
                  automaticallyImplyLeading: false,
                  title: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Padding(
                          padding: EdgeInsets.only(top: 50),
                          child: Image.asset(
                            'assets/images/logo/Music_logo.png',
                            height: 120,
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.only(top: 20),
                          child: Text(
                            'Log in',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontStyle: FontStyle.normal,
                              color: Colors.white,
                              fontSize: 44,
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.only(left: 40, right: 40),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          padding: EdgeInsets.only(left: 0, right: 0),
                          child: TextFormField(
                            focusNode: emailFocusNode,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your email';
                              }
                              return null;
                            },
                            onChanged: (value) {
                              email = value;
                            },
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontStyle: FontStyle.normal,
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.normal,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Email',
                              hintStyle: TextStyle(
                                fontFamily: 'Outfit',
                                fontStyle: FontStyle.normal,
                                color: const Color.fromARGB(150, 255, 255, 255),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(22),
                                borderSide: BorderSide(
                                  color: Colors.white,
                                  width: 15,
                                ),
                              ),
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.2),
                            ),
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.only(top: 10, bottom: 10),
                          child: TextFormField(
                            obscureText: !_isPasswordVisible,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your password';
                              }
                              return null;
                            },
                            onChanged: (value) {
                              password = value;
                            },
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontStyle: FontStyle.normal,
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.normal,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Password',
                              hintStyle: TextStyle(
                                fontFamily: 'Outfit',
                                fontStyle: FontStyle.normal,
                                color: Color.fromARGB(150, 255, 255, 255),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(22),
                                borderSide: BorderSide(
                                  color: Colors.white,
                                  width: 20,
                                ),
                              ),
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.2),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                                  color: Colors.white,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _isPasswordVisible = !_isPasswordVisible;
                                  });
                                },
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: () async {
                            if (_formKey.currentState!.validate()) {
                              if (_error != null) {
                                _showErrorDialog(context, _error!);
                                return;
                              }
                              try {
                                print('Attempting login...'); // Add this line
                                final Session session = await account.createEmailPasswordSession(
                                  email: email,
                                  password: password,
                                );
                                print('Login successful!'); // Add this line
                                print('User ID: ${session.userId}'); // Add this line
                                Navigator.push(context, MaterialPageRoute(builder: (context) => HomeScreen(client: widget.client, sessionId: session.$id,)));
                                await _storeSessionId(session.$id);
                              } catch (e) {
                                print('Error during login: $e'); // Add this line
                                if (e is AppwriteException) {
                                  print('Error message: ${e.message}'); // Add this line
                                  if (e.code == 401) {
                                    if (e.message?.contains('Creation of a session is prohibited when a session is active') == true) {
                                      _showErrorDialog(context, 'Session already active for this user. Please log out from other devices.');
                                    } else if (e.message?.contains('Invalid credentials') == true) {
                                      _showErrorDialog(context, 'Invalid credentials. Please check the email and password.');
                                    } else {
                                      _showErrorDialog(context, 'An error occurred during login.');
                                    }
                                  } else {
                                    _showErrorDialog(context, 'An error occurred during login.');
                                  }
                                } else {
                                  print('Unknown error type: $e'); // Add this line
                                  _showErrorDialog(context, 'An error occurred during login.');
                                }
                              }
                            }
                          },
                          child: Text(
                            'Log in',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontStyle: FontStyle.normal,
                              color: Color.fromARGB(255, 255, 255, 255),
                              fontSize: 18,
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color.fromARGB(99, 255, 255, 255),
                            padding: EdgeInsets.symmetric(
                              horizontal: 50,
                              vertical: 15,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(22),
                              side: BorderSide(
                                color: const Color.fromARGB(123, 255, 255, 255),
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.only(top: 10), // Add padding to the top of the Row
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Flexible(
                                child: TextButton(
                                  onPressed: () {
                                    _resetPassword();
                                  },
                                  child: Text(
                                    'Forgot Password? (Not implemented)',
                                    style: TextStyle(
                                      fontFamily: 'Outfit',
                                      fontStyle: FontStyle.normal,
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.normal,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 20), // Add space between the buttons
                              TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    PageRouteBuilder(
                                      pageBuilder: (context, animation, secondaryAnimation) => SignUpPage(client: widget.client),
                                      transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                        const begin = 0.0;
                                        const end = 1.0;
                                        const curve = Curves.ease;

                                        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                                        var fadeAnimation = animation.drive(tween);

                                        return FadeTransition(
                                          opacity: fadeAnimation,
                                          child: child,
                                        );
                                      },
                                    ),
                                  );
                                },
                                child: Text(
                                  'Create Aurora ID',
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontStyle: FontStyle.normal,
                                    color: Color.fromARGB(255, 255, 255, 255),
                                    fontSize: 15,
                                    fontWeight: FontWeight.normal,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    // Navigate to the homepage and show ads
                    Navigator.push(context, MaterialPageRoute(builder: (context) => HomeScreenAds()));
                    // Show ads here
                  },
                  child: Text(
                    'Continue without Aurora ID',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontStyle: FontStyle.normal,
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          content: Text(
            message,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontStyle: FontStyle.normal,
              color: Color.fromARGB(255, 104, 32, 238),
              fontSize: 16,
              fontWeight: FontWeight.normal,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'OK',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontStyle: FontStyle.normal,
                  color: Color.fromARGB(255, 104, 32, 238),
                  fontSize: 16,
                  fontWeight: FontWeight.normal,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}

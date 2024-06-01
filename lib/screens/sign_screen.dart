import 'package:flutter/material.dart';
import 'package:appwrite/appwrite.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'login_screen.dart';
import 'home_screen.dart';
import 'home_screen_ads.dart';

class SignUpPage extends StatefulWidget {
  final Client client;

  SignUpPage({required this.client});

  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  late String email;
  late String password;
  late String confirmPassword;
  late bool _agreeToTerms;
  String? _error;
  late ScrollController _scrollController;
  late bool isDarkMode;
  final emailFocusNode = FocusNode();

  final _formKey = GlobalKey<FormState>();
  final Connectivity _connectivity = Connectivity();
  late Account _account;

  @override
  void initState() {
    super.initState();
    _connectivity.onConnectivityChanged.listen((List<ConnectivityResult> results) {
      setState(() {
        _error = results.contains(ConnectivityResult.none) ? 'No internet connection' : null;
      });
    });
    _scrollController = ScrollController();
    _agreeToTerms = false;
    isDarkMode = true;
    emailFocusNode.addListener(() {
      if (emailFocusNode.hasFocus) {
        _scrollToFormField(context, emailFocusNode.context!.findAncestorWidgetOfExactType<TextFormField>()!);
      }
    });

    _account = Account(widget.client);
  }

  Future<void> _resetPassword() async {
    try {
      await _account.createRecovery(
        email: email,
        url: 'https://example.com/reset-password',
      );
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

  Future<void> _signUp() async {
    try {
      print('Signing up user...');
      final response = await _account.create(
        userId: ID.unique(),
        email: email,
        password: password,
      );
      print('User signed up successfully!');
      Navigator.push(context, MaterialPageRoute(builder: (context) => HomeScreen(client: widget.client)));
    } catch (e) {
      print('Error during sign up: $e');
      if (e is AppwriteException) {
        if (e.code == 400 && e.message != null) {
          if (e.message!.contains('Invalid `password` param: Password must be between 8 and 265 characters long, and should not be one of the commonly used password.')) {
            _showErrorDialog(context, 'Password must be between 8 and 265 characters long, and should not be one of the commonly used passwords.');
            return;
          }
        }
      }
      _showErrorDialog(context, 'An error occurred during sign up. Please try again later.');
    }
  }

  @override
  Widget build(BuildContext context) {
    isDarkMode = MediaQuery.of(context).platformBrightness == Brightness.dark;

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
                            'Sign Up',
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
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          padding: EdgeInsets.only(top: 20, bottom: 3),
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
                          padding: EdgeInsets.only(top: 0, bottom: 3),
                          child: TextFormField(
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
                            ),
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.only(top: 0, bottom: 5),
                          child: TextFormField(
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please confirm your password';
                              } else if (value != password) {
                                return 'Passwords do not match';
                              }
                              return null;
                            },
                            onChanged: (value) {
                              confirmPassword = value;
                            },
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontStyle: FontStyle.normal,
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.normal,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Confirm Password',
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
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            Checkbox(
                              value: _agreeToTerms,
                              onChanged: (newValue) {
                                setState(() {
                                  _agreeToTerms = newValue!;
                                });
                              },
                            ),
                            Expanded(
                              child: Text(
                                'By registering you agree to Aurora Software ToS',
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontStyle: FontStyle.normal,
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.normal,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: () async {
                            if (_formKey.currentState!.validate() && _agreeToTerms) {
                              if (_error != null) {
                                _showErrorDialog(context, _error!);
                                return;
                              }
                              await _signUp();
                            }
                          },
                          child: Text(
                            'Sign Up',
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
                          padding: EdgeInsets.only(top: 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Flexible(
                                child: TextButton(
                                  onPressed: () {
                                    _resetPassword();
                                  },
                                  child: Text(
                                    'Forgot Password?',
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
                              SizedBox(width: 20),
                              Flexible(
                                child: TextButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      PageRouteBuilder(
                                        pageBuilder: (context, animation, secondaryAnimation) => LoginPage(client: widget.client),
                                        transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                          var begin = 0.0;
                                          var end = 1.0;
                                          var curve = Curves.easeInOut;

                                          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

                                          return FadeTransition(
                                            opacity: animation.drive(tween),
                                            child: child,
                                          );
                                        },
                                      ),
                                    );
                                  },
                                  child: Text(
                                    'Log in to Aurora ID',
                                    style: TextStyle(
                                      fontFamily: 'Outfit',
                                      fontStyle: FontStyle.normal,
                                      color: Color.fromARGB(255, 255, 255, 255),
                                      fontSize: 15,
                                      fontWeight: FontWeight.normal,
                                    ),
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
                    Navigator.push(context, MaterialPageRoute(builder: (context) => HomeScreenAds()));
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
              color: Color.fromARGB(255, 147, 17, 218),
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
                  color: Color.fromARGB(255, 147, 17, 218),
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
    emailFocusNode.dispose();
    super.dispose();
  }
}

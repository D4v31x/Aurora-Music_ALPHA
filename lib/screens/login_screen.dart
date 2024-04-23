import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'sign_screen.dart';
import 'home_screen.dart';
import 'home_screen_ads.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _supabase = Supabase.instance.client;
  late String email;
  late String password;
  late bool isDarkMode;
  String? _error;
  late ScrollController _scrollController;
  final emailFocusNode = FocusNode();

  final _formKey = GlobalKey<FormState>();
  final Connectivity _connectivity = Connectivity();


  @override
  void initState() {
    super.initState();
    _connectivity.onConnectivityChanged.listen((List<ConnectivityResult> results) {
      setState(() {
        _error = results.contains(ConnectivityResult.none)? 'No internet connection' : null;
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
      await _supabase.auth.resetPasswordForEmail(email);
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


  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    isDarkMode = MediaQuery.of(context).platformBrightness == Brightness.dark;
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
                image: AssetImage(isDarkMode ? 'assets/images/background/dark_back.jpg' : 'assets/images/background/light_back.jpg'),fit: BoxFit.cover,
              ),
            ),
          ),
          SingleChildScrollView(
            controller:_scrollController,
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
                                  onChanged: (value) {email = value; },
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
                                padding: EdgeInsets.only(top: 3, bottom: 3),
                                child: TextFormField(
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter your password';
                                    }
                                    return null;
                                  },
                                  onChanged: (value) { password =value; },
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
                              SizedBox(height: 10),
                              ElevatedButton(
  onPressed: () async {
    if (_formKey.currentState!.validate()) {
      if (_error!= null) {
        _showErrorDialog(context, _error!);
        return;
      }
      try {
        final response = await _supabase.auth.signInWithPassword(email: email, password: password);
                                      if (response.user == null) {
                                        _showErrorDialog(context, 'Invalid email or password');
                                      } else {
                                        Navigator.push(context, MaterialPageRoute(builder: (context) => HomeScreen()));
                                      }
                                    } catch (e) {
                                      _showErrorDialog(context, 'An error occurred during login.');
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
                                    SizedBox(width: 20), // Add space between the buttons
                                    TextButton(
                                      onPressed: () {
                                        Navigator.push(context, MaterialPageRoute(builder: (context) => SignUpPage()));
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
                            fontSize:14,
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
  void dispose(){
    _scrollController.dispose();
    super.dispose();
  }
}

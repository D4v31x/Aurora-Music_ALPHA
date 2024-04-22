import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'login_screen.dart';
import 'home_screen.dart';
import 'home_screen_ads.dart';

class SignUpPage extends StatefulWidget {
  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _auth = FirebaseAuth.instance;
  late String email;
  late String password;
  late String confirmPassword;
  late bool isDarkMode;
  String? _error;
  bool _agreeToTerms = false;

  final _formKey = GlobalKey<FormState>();
  final Connectivity _connectivity = Connectivity();

  @override
  void initState() {
    super.initState();
    _connectivity.onConnectivityChanged.listen((List<ConnectivityResult> results) {
      setState(() {
        _error = results.contains(ConnectivityResult.none) ? 'No internet connection' : null;
      });
    });
  }

  Future<void> _resetPassword() async {
    await _auth.sendPasswordResetEmail(email: email);
    _showErrorDialog(context, 'Password reset email sent');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    isDarkMode = MediaQuery.of(context).platformBrightness == Brightness.dark;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(isDarkMode ? 'assets/images/background/dark_back.jpg' : 'assets/images/background/light_back.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          height: MediaQuery.of(context).size.height,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0.0,
                toolbarHeight: 370,
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
                        padding: EdgeInsets.only(top: 36),
                        child: Text(
                          'Sign Up',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontStyle: FontStyle.normal,
                            color: Colors.white,
                            fontSize: 64,
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: EdgeInsets.only(left: 40, right: 40),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                padding: EdgeInsets.only(top: 36, bottom: 3),
                                child: TextFormField(
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
                                    fontSize: 22,
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
                                      return 'Please enter your password';
                                    }
                                    return null;
                                  },
                                  onChanged: (value) { password = value; },
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontStyle: FontStyle.normal,
                                    color: Colors.white,
                                    fontSize: 22,
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
                                  onChanged: (value) { confirmPassword = value; },
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontStyle: FontStyle.normal,
                                    color: Colors.white,
                                    fontSize: 22,
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
                                  Text(
                                    'By registering you agree to Aurora Software ToS',
                                    style: TextStyle(
                                      fontFamily: 'Outfit',
                                      fontStyle: FontStyle.normal,
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 20),
                              ElevatedButton(
                                onPressed: () async {
                                  if (_formKey.currentState!.validate() && _agreeToTerms) {
                                    if (_error != null) {
                                      _showErrorDialog(context, _error!);
                                      return;
                                    }
                                    try {
                                      await _auth.createUserWithEmailAndPassword(email: email, password: password);
                                      Navigator.push(context, MaterialPageRoute(builder: (context) => HomeScreen()));
                                    } on FirebaseAuthException catch (e) {
                                      String errorMessage;
                                      switch (e.code) {
                                        case 'weak-password':
                                          errorMessage = 'The password provided is too weak.';
                                          break;
                                        case 'email-already-in-use':
                                          errorMessage = 'The email is already in use by another account.';
                                          break;
                                        default:
                                          errorMessage = 'An error occurred during sign up.';
                                          break;
                                      }
                                      _showErrorDialog(context, errorMessage);
                                    } catch (e) {
                                      _showErrorDialog(context, 'An error occurred during sign up.');
                                    }
                                  } else if (!_agreeToTerms) {
                                    _showErrorDialog(context, 'Please agree to the Terms of Service.');
                                  }
                                },
                                child: Text(
                                  'Sign Up',
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontStyle: FontStyle.normal,
                                    color: Color.fromARGB(255, 255, 255, 255),
                                    fontSize: 28,
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
                                    TextButton(
                                      onPressed: () {
                                        _resetPassword();
                                      },
                                      child: Text(
                                        'Forgot Password?',
                                        style: TextStyle(
                                          fontFamily: 'Outfit',
                                          fontStyle: FontStyle.normal,
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.normal,
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 20),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.push(context, MaterialPageRoute(builder: (context) => LoginPage()));
                                      },
                                      child: Text(
                                        'Log in to Aurora ID',
                                        style: TextStyle(
                                          fontFamily: 'Outfit',
                                          fontStyle: FontStyle.normal,
                                          color: Color.fromARGB(255, 255, 255, 255),
                                          fontSize: 18,
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
                          Navigator.push(context, MaterialPageRoute(builder: (context) => HomeScreenAds()));
                        },
                        child: Text(
                          'Continue without Aurora ID (not implemented yet)',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontStyle: FontStyle.normal,
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
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
                  color: Color.fromARGB(255,147,17,218),
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
}

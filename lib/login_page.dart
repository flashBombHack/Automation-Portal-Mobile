import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_auth/local_auth.dart';

import 'PasswordResetPage.dart';
import 'dashboard_screen.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _firebaseMessaging = FirebaseMessaging.instance;
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  bool _isLoggedIn = false;
  bool _isBiometricEnabled = false;
  static final _auth = LocalAuthentication();
  bool authenticated = false;

  static const String _loginUrl = 'https://automationapi.lotuscapitallimited.com/api/user/mobile/login';

  Future<void> handleBackgroundMessage(RemoteMessage message) async {}

  @override
  void initState() {
    super.initState();
    _checkBiometricEnabled();
    _checkLoggedIn();
  }

  Future<void> _checkLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final loggedIn = prefs.getBool('loggedIn') ?? false;
    setState(() {
      _isLoggedIn = loggedIn;
    });
  }

  Future<void> _checkBiometricEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    final biometricEnabled = prefs.getBool('biometricEnabled') ?? false;
    setState(() {
      _isBiometricEnabled = biometricEnabled;
    });
  }

  Future<bool> _isCredentialsStored() async {
    final prefs = await SharedPreferences.getInstance();
    String? email = prefs.getString('email');
    String? password = prefs.getString('password');
    return email != null && password != null;
  }

  Future<bool> _canAuthenticate() async =>
      await _auth.canCheckBiometrics || await _auth.isDeviceSupported();

  Future<bool> authenticate() async {
    try {
      if (!await _canAuthenticate()) return false;

      return await _auth.authenticate(
        localizedReason: 'Use Face ID to authenticate',
        options: const AuthenticationOptions(
          useErrorDialogs: true,
          stickyAuth: true,
        ),
      );
    } catch (e) {
      debugPrint('Error: $e');
      return false;
    }
  }

  Future<void> _authenticateBiometric() async {
    bool authenticated = false;

    try {
      authenticated = await _auth.authenticate(
        localizedReason: 'Authenticate to enable biometric authentication',
      );
    } catch (e) {
      print('Error during biometric authentication: $e');
    }

    if (authenticated) {
      final prefs = await SharedPreferences.getInstance();
      String? email = prefs.getString('email');
      String? password = prefs.getString('password');
      if (email != null && password != null) {
        _login(email, password, isBiometric: true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login first to enable biometric authentication')),
        );
      }
    }
  }

  Future<void> _login(String email, String password, {bool isBiometric = false}) async {
    setState(() {
      _isLoading = true;
    });

    await _firebaseMessaging.requestPermission();
    final fCMToken = await _firebaseMessaging.getToken();
    _firebaseMessaging.onTokenRefresh.listen((token) {
      print('APNS token is: $token');
      // Send the token to your server or perform any other necessary actions
    });
    FirebaseMessaging.onBackgroundMessage(handleBackgroundMessage);

    String deviceToken = fCMToken ?? '';

    try {
      final http.Response response = await http.post(
        Uri.parse(_loginUrl),
        headers: <String, String>{
          'Content-Type': 'application/json',
        },
        body: jsonEncode(<String, String>{
          'email': email,
          'password': password,
          'deviceId': deviceToken,
        }),
      );

      print('Payload Sent!: $email, $password, $deviceToken');

      final Map<String, dynamic> data = jsonDecode(response.body);
      final String message = data['message'];

      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        if (!isBiometric) {
          await prefs.setString('email', email);
          await prefs.setString('password', password);
        }
        print('Login successful: $data');
        // Check if password is on reset mode
        final int onReset = data['onreset'];
        if (onReset == 1) {
          // Navigate to the password reset page
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => PasswordResetPage(email: email)),
          );
        } else {
          // Extract required data from the response
          final token = data['token'];
          final firstName = data['firstName'];
          final lastName = data['lastName'];
          final email = data['email'];
          final userId = data['userId'];
          final role = data['role'];
          final department = data['department'];

          // Navigate to the dashboard screen and pass data as arguments
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => DashboardScreen(
                token: token,
                firstName: firstName,
                lastName: lastName,
                email: email,
                userId: userId,
                role: role,
                department: department,
              ),
            ),
          );
        }
      } else {
        // Handle errors based on status codes
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    } catch (error) {
      print('Error during login: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred, please contact the system administrator')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Container(
          color: Colors.white,
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Image.asset(
                      'assets/LotusLogo.png',
                      height: 100,
                    ),
                    SizedBox(height: 16.0),
                    Text(
                      'Login',
                      style: TextStyle(
                        fontSize: 24.0,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 16.0),
                    TextField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                          borderSide: BorderSide(color: Colors.blue, width: 2.0),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                          borderSide: BorderSide(color: Colors.grey, width: 1.0),
                        ),
                      ),
                    ),
                    SizedBox(height: 25.0),
                    TextField(
                      controller: _passwordController,
                      obscureText: !_isPasswordVisible,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                          borderSide: BorderSide(
                            color: Colors.redAccent, // Set your desired color here
                            width: 2.0, // Set the width of the border
                          ),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                            color: Colors.grey[800],
                          ),
                          onPressed: () {
                            setState(() {
                              _isPasswordVisible = !_isPasswordVisible;
                            });
                          },
                        ),
                      ),
                    ),
                    SizedBox(height: 32.0),
                    ElevatedButton(
                      onPressed: _isLoading
                          ? null
                          : () {
                        String email = _emailController.text;
                        String password = _passwordController.text;
                        _login(email, password);
                      },
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Color(0xFF8E1611),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        minimumSize: Size(double.infinity, 50),
                      ),
                      child: _isLoading
                          ? SizedBox(
                        width: 24.0,
                        height: 24.0,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.0,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          backgroundColor: Color(0xFF8E1611),
                        ),
                      )
                          : Text(
                        'Login',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    SizedBox(height: 50),
                    if (Platform.isIOS)
                      GestureDetector(
                        onTap: _authenticateBiometric,
                        child: Column(
                          children: [
                            Image.asset(
                              'assets/FaceID.png',
                              width: 70,
                              height: 70,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Login with Face ID',
                              style: TextStyle(color: Colors.black),
                            ),
                          ],
                        ),
                      ),
                    if (Platform.isAndroid)
                      GestureDetector(
                        onTap: _authenticateBiometric,
                        child: Column(
                          children: [
                            Image.asset(
                              'assets/Fingerprint.png',
                              width: 70,
                              height: 70,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Login with Fingerprint',
                              style: TextStyle(color: Colors.black),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

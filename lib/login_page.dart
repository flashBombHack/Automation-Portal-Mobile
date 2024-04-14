import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_messaging/firebase_messaging.dart';

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

  static const String _loginUrl = 'https://stagings.vaps.parkwayprojects.xyz/SAP-API/api/user/mobile/login';

  Future<void> handleBackgroundMessage(RemoteMessage message) async {
  }



  Future<void> _login() async {
    setState(() {
      _isLoading = true; // Set loading state to true when login button is pressed
    });

    await _firebaseMessaging.requestPermission();
    final fCMToken = await _firebaseMessaging.getToken();
    _firebaseMessaging.onTokenRefresh.listen((token) {
      print('APNS token is: $token');
      // Send the token to your server or perform any other necessary actions
    });
    FirebaseMessaging.onBackgroundMessage(handleBackgroundMessage);
    final String email = _emailController.text;
    final String password = _passwordController.text;

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

      print('Payload Sent!: $email , $password, $deviceToken');

      final Map<String, dynamic> data = jsonDecode(response.body);
      final String message = data['message'];

      if (response.statusCode == 200) {
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
      } else if (response.statusCode == 401) {
        // Handle 401 Unauthorized error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      } else if (response.statusCode == 404) {
        // Handle 404 Not Found error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      } else if (response.statusCode == 500) {
        // Handle 500 Internal Server Error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      } else {
        // Handle other status codes
        print('Login failed: ${response.statusCode}');
        print('Response body: ${response.body}');
      }
    } catch (error) {
      print('Error during login: $error');
    }
    finally {
      setState(() {
        _isLoading = false; // Set loading state to false after login attempt
      });
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Add your logo here
              Image.asset(
                'assets/LotusLogo.png',
                height: 100,
                // Adjust width and height as needed
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
                onPressed: _isLoading ? null : _login, // Disable button while loading
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

            ],
          ),
        ),
      ),
    );
  }

  }

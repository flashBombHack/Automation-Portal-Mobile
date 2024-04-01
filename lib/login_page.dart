import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_messaging/firebase_messaging.dart';

import 'dashboard_screen.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _firebaseMessaging = FirebaseMessaging.instance;

  static const String _loginUrl = 'https://stagings.vaps.parkwayprojects.xyz/SAP-API/api/user/mobile/login';

  Future<void> handleBackgroundMessage(RemoteMessage message) async {
  }



  Future<void> _login() async {
    await _firebaseMessaging.requestPermission();
    final fCMToken = await  _firebaseMessaging.getToken();
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

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        print('Login successful: $data');
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
      else {
        print('Login failed: ${response.statusCode}');
        print('Response body: ${response.body}');

      }
    } catch (error) {
      print('Error during login: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Email'),
            ),
            SizedBox(height: 16.0),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(labelText: 'Password'),
            ),
            SizedBox(height: 32.0),
            ElevatedButton(
              onPressed: _login,
              child: Text('Login'),
            ),
          ],
        ),
      ),
    );
  }
}

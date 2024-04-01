import 'dart:async';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class DashboardScreen extends StatefulWidget {
  final String token;
  final String firstName;
  final String lastName;
  final String email;
  final String userId;
  final String role;
  final String department;

  const DashboardScreen({
    required this.token,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.userId,
    required this.role,
    required this.department,
  });

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final Completer<WebViewController> _controller =
  Completer<WebViewController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: WebView(
          initialUrl: _buildInitialUrl(),
          javascriptMode: JavascriptMode.unrestricted,
          onWebViewCreated: (WebViewController webViewController) {
            _controller.complete(webViewController);
            // Check if onWebViewCreated is called
            print('WebView Created');
          },
          javascriptChannels: <JavascriptChannel>[
            _createFlutterBridgeChannel(),
          ].toSet(),
          navigationDelegate: (NavigationRequest request) {
            print('Navigation request: ${request.url}');
            if (request.url.contains('https://staging.swwipe.com:8443/login')) {
              _logout();
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
          onWebResourceError: (WebResourceError error) {
            print('Error occurred: $error');
          },
        ),
      ),
    );
  }

  String _buildInitialUrl() {
    return 'https://staging.swwipe.com:8443/mobile?token=${widget.token}&firstName=${widget.firstName}&lastName=${widget.lastName}&email=${widget.email}&userId=${widget.userId}&role=${widget.role}&department=${widget.department}';
  }

  void _logout() {
    // Implement your logout logic here
    print('Logout triggered from WebView');
    // Close the WebView and navigate to the login page
    Navigator.pushReplacementNamed(context, '/login');
  }

  JavascriptChannel _createFlutterBridgeChannel() {
    return JavascriptChannel(
      name: 'FlutterBridge',
      onMessageReceived: (JavascriptMessage message) {
        // Handle message received from JavaScript
        print('Message from JavaScript: ${message.message}');
        if (message.message == 'Requesting logout from Webview') {
          _logout(); // Call the logout function
        }

        // You can perform actions based on the received message here
      },
    );
  }
}

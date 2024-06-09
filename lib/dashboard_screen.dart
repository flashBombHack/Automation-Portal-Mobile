import 'dart:async';
import 'dart:convert';
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
  final Completer<WebViewController> _controller = Completer<WebViewController>();
  bool _isLoading = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Stack(
          children: [
            WebView(
              initialUrl: _buildInitialHtml(),
              javascriptMode: JavascriptMode.unrestricted,
              onWebViewCreated: (WebViewController webViewController) {
                _controller.complete(webViewController);
              },
              onPageFinished: (String url) {
                setState(() {
                  _isLoading = false;
                });
              },
              onPageStarted: (String url) {
                setState(() {
                  _isLoading = true;
                });
              },
              javascriptChannels: <JavascriptChannel>{
                _createFlutterBridgeChannel(),
              },
              navigationDelegate: (NavigationRequest request) {
                print('Navigation request: ${request.url}');
                if (request.url.contains('https://autoportal.lotuscapitallimited.com/login')) {
                  _logout();
                  return NavigationDecision.prevent;
                }
                return NavigationDecision.navigate;
              },
              onWebResourceError: (WebResourceError error) {
                print('Error occurred: $error');
              },
              gestureNavigationEnabled: true,
            ),
            if (_isLoading)
              Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Color(0xFF8E1611), // Set the color here
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _buildInitialUrl() {
    return 'https://autoportal.lotuscapitallimited.com/mobile?token=${widget.token}&firstName=${widget.firstName}&lastName=${widget.lastName}&email=${widget.email}&userId=${widget.userId}&role=${widget.role}&department=${widget.department}';
  }

  String _buildInitialHtml() {
    final initialUrl = _buildInitialUrl();
    return Uri.dataFromString('''
      <html>
        <head>
          <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
          <style>
            body, html {
              margin: 0;
              padding: 0;
              height: 100%;
              overflow: hidden;
            }
            iframe {
              width: 100%;
              height: 100%;
              border: none;
            }
          </style>
        </head>
        <body>
          <iframe src="$initialUrl"></iframe>
        </body>
      </html>
    ''', mimeType: 'text/html', encoding: Encoding.getByName('utf-8')).toString();
  }

  void _logout() {
    print('Logout triggered from WebView');
    Navigator.pushReplacementNamed(context, '/login');
  }

  JavascriptChannel _createFlutterBridgeChannel() {
    return JavascriptChannel(
      name: 'FlutterBridge',
      onMessageReceived: (JavascriptMessage message) {
        print('Message from JavaScript: ${message.message}');
        if (message.message == 'Requesting logout from Webview') {
          _logout();
        }
      },
    );
  }
}

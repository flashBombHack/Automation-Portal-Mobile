import 'dart:async';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'login_page.dart';

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
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  String messageFromWebview = ''; // State variable to store message
  bool isLoggedOut = false; // Flag to track if the user has been logged out

  @override
  void initState() {
    super.initState();
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> event) {
      for (var result in event) {
        if (result == ConnectivityResult.none && !isLoggedOut && messageFromWebview == 'Requesting logout from Webview') {
          _logout();
        }
      }
    });
    print('Connectivity subscription initialized: ${_connectivitySubscription != null}');
  }

  @override
  void dispose() {
    print('Disposing connectivity subscription.');
    _connectivitySubscription?.cancel();
    print('Connectivity subscription cancelled: ${_connectivitySubscription == null}');
    super.dispose();
  }

  Future<void> _refresh() async {
    final controller = await _controller.future;
    controller.reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Stack(
          children: [
            RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  Container(
                    height: MediaQuery.of(context).size.height,
                    child: WebView(
                      initialUrl: _buildInitialUrl(),
                      javascriptMode: JavascriptMode.unrestricted,
                      onWebViewCreated: (WebViewController webViewController) {
                        _controller.complete(webViewController);
                      },
                      onPageFinished: (String url) {
                        setState(() {
                          _isLoading = false;
                        });
                        _controller.future.then((webViewController) {
                          _disableZoom(webViewController);
                        });
                      },
                      onPageStarted: (String url) {
                        setState(() {
                          _isLoading = true;
                        });
                      },
                      javascriptChannels: <JavascriptChannel>[
                        _createFlutterBridgeChannel(),
                      ].toSet(),
                      onWebResourceError: (WebResourceError error) {
                        print('Error occurred: $error');
                      },
                      backgroundColor: Colors.transparent, // Set WebView background color to transparent
                    ),
                  ),
                ],
              ),
            ),
            if (_isLoading)
              Positioned.fill(
                child: Container(
                  color: Colors.white, // Initial background color
                  child: Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFF8E1611), // Spinner color
                      ),
                    ),
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

  void _logout() {
    print('Logout triggered from WebView');
    setState(() {
      isLoggedOut = true; // Set the flag to true to prevent further logouts
      messageFromWebview = ''; // Clear message state
    });
    _connectivitySubscription?.cancel();
    print('Connectivity subscription cancelled in logout: ${_connectivitySubscription == null}');

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()), // Replace `LoginScreen` with your actual login screen widget
          (Route<dynamic> route) => false,
    );
  }

  JavascriptChannel _createFlutterBridgeChannel() {
    return JavascriptChannel(
      name: 'FlutterBridge',
      onMessageReceived: (JavascriptMessage message) {
        print('Message from JavaScript: ${message.message}');
        messageFromWebview = message.message;
        if (messageFromWebview == 'Requesting logout from Webview') {
          messageFromWebview = '';
          _logout();
        }
      },
    );
  }

  void _disableZoom(WebViewController controller) {
    controller.runJavascript('''
      (function() {
        var meta = document.createElement('meta');
        meta.name = 'viewport';
        meta.content = 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no';
        var head = document.getElementsByTagName('head')[0];
        if (head) {
          head.appendChild(meta);
        }

        document.addEventListener('gesturestart', function (e) {
          e.preventDefault();
        });

        document.addEventListener('gesturechange', function (e) {
          e.preventDefault();
        });

        document.addEventListener('gestureend', function (e) {
          e.preventDefault();
        });
      })();
    ''');
  }
}

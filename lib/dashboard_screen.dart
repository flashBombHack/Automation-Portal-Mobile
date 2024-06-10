import 'dart:async';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter/services.dart';

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
  static const platform = MethodChannel('download_pdf_channel');

  @override
  void initState() {
    super.initState();
    // Enabling hybrid composition mode for improved performance
    WebView.platform = SurfaceAndroidWebView();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Stack(
          children: [
            WebView(
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
              navigationDelegate: (NavigationRequest request) {
                print('Navigation request: ${request.url}');
                if (request.url.endsWith('.pdf')) {
                  _downloadFile(request.url);
                  return NavigationDecision.prevent;
                }
                if (request.url.contains('https://autoportal.lotuscapitallimited.com/login')) {
                  _logout();
                  return NavigationDecision.prevent;
                }
                return NavigationDecision.navigate;
              },
              onWebResourceError: (WebResourceError error) {
                print('Error occurred: $error');
              },
              backgroundColor: Colors.transparent, // Set WebView background color to transparent
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

  void _downloadFile(String url) async {
    try {
      final result = await platform.invokeMethod('downloadFile', {"url": url});
      print('Download result: $result');
    } on PlatformException catch (e) {
      print("Failed to download file: '${e.message}'.");
    }
  }
}

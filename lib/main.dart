import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:lotuscapitalportal/api/firebase_api.dart';

import 'api/firebase_api.dart';
import 'firebase_options.dart';
import 'login_page.dart';
import 'dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    initialRoute: '/login',
    routes: {
      '/login': (context) => LoginPage(),
    },
  ));
}


// ============================================================
//  lib/main.dart
//  SmartSense — IoT Environmental Monitoring App
//  Team 4 | Flutter / Dart
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'utils/app_theme.dart';
import 'screens/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Match status bar to navy app bar
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Color(0xFF1A2340),
    statusBarIconBrightness: Brightness.light,
  ));

  runApp(const SmartSenseApp());
}

class SmartSenseApp extends StatelessWidget {
  const SmartSenseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SmartSense',
      debugShowCheckedModeBanner: false,
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
      themeMode: ThemeMode.system,
      home: const SplashScreen(),
    );
  }
}

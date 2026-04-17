// ============================================================
//  lib/utils/app_theme.dart
//  Centralised design tokens — colors, text styles, theming.
// ============================================================

import 'package:flutter/material.dart';
import '../models/sensor_data.dart';

// ── Brand colours ────────────────────────────────────────────
class AppColors {
  AppColors._();

  static const navy    = Color(0xFF1A2340);
  static const blue    = Color(0xFF378ADD);
  static const blueL   = Color(0xFFE6F1FB);
  static const blueDk  = Color(0xFF185FA5);

  static const green   = Color(0xFF1D9E75);
  static const greenL  = Color(0xFFEAF3DE);
  static const greenDk = Color(0xFF3B6D11);

  static const amber   = Color(0xFFBA7517);
  static const amberL  = Color(0xFFFAEEDA);
  static const amberDk = Color(0xFF633806);

  static const red     = Color(0xFFA32D2D);
  static const redL    = Color(0xFFFCEBEB);
  static const redMd   = Color(0xFFF09595);

  static const grey    = Color(0xFF6B7280);
  static const greyL   = Color(0xFFF5F5F5);

  // Status → color mapping
  static Color statusFg(SensorStatus s) {
    switch (s) {
      case SensorStatus.good:      return greenDk;
      case SensorStatus.moderate:  return amberDk;
      case SensorStatus.unhealthy: return amberDk;
      case SensorStatus.danger:    return red;
      case SensorStatus.hazardous: return Colors.white;
    }
  }

  static Color statusBg(SensorStatus s) {
    switch (s) {
      case SensorStatus.good:      return greenL;
      case SensorStatus.moderate:  return amberL;
      case SensorStatus.unhealthy: return amberL;
      case SensorStatus.danger:    return redL;
      case SensorStatus.hazardous: return red;
    }
  }
}

// ── Text styles ──────────────────────────────────────────────
class AppText {
  AppText._();

  static const heading = TextStyle(
    fontSize: 18, fontWeight: FontWeight.w600, letterSpacing: -0.3,
  );
  static const sectionLabel = TextStyle(
    fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 0.8,
  );
  static const cardValue = TextStyle(
    fontSize: 20, fontWeight: FontWeight.w600,
  );
  static const cardLabel = TextStyle(fontSize: 12);
  static const badge = TextStyle(fontSize: 11, fontWeight: FontWeight.w500);
  static const body  = TextStyle(fontSize: 14, height: 1.5);
  static const small = TextStyle(fontSize: 12);
  static const tiny  = TextStyle(fontSize: 11);
}

// ── Light & dark ThemeData ───────────────────────────────────
ThemeData buildLightTheme() => ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: AppColors.navy,
    primary: AppColors.navy,
    secondary: AppColors.blue,
    surface: Colors.white,
    surfaceVariant: AppColors.greyL,
  ),
  scaffoldBackgroundColor: AppColors.greyL,
  navigationBarTheme: const NavigationBarThemeData(
    backgroundColor: Colors.white,
    elevation: 0,
    indicatorColor: AppColors.blueL,
    labelTextStyle: WidgetStatePropertyAll(
      TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
    ),
  ),
  dividerTheme: const DividerThemeData(color: Color(0xFFEEEEEE), thickness: 0.5),
);

ThemeData buildDarkTheme() => ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: AppColors.navy,
    brightness: Brightness.dark,
    primary: AppColors.blue,
    surface: const Color(0xFF1E1E2E),
    surfaceVariant: const Color(0xFF181828),
  ),
  navigationBarTheme: const NavigationBarThemeData(
    backgroundColor: Color(0xFF1E1E2E),
    indicatorColor: Color(0xFF1A3050),
  ),
);

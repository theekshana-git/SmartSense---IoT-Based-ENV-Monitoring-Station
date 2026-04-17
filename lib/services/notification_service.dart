// ============================================================
//  lib/services/notification_service.dart
//  Local push notifications via flutter_local_notifications.
//  - Gas level > 600 ppm  → gas alert (60s cooldown)
//  - Any Danger/Hazardous → emergency alert (first time only)
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;
  static bool _gasCooldown = false;

  // ── Android notification channels ────────────────────────
  static const _gasChannel = AndroidNotificationDetails(
    'smartsense_gas_channel',
    'Gas Level Alerts',
    channelDescription: 'Fires when gas_level exceeds 600 ppm',
    importance: Importance.max,
    priority: Priority.high,
    color: Color(0xFFA32D2D),
    playSound: true,
    enableVibration: true,
  );

  static const _emergencyChannel = AndroidNotificationDetails(
    'smartsense_emergency_channel',
    'Emergency Environmental Alerts',
    channelDescription: 'Critical environmental condition alerts',
    importance: Importance.max,
    priority: Priority.high,
    color: Color(0xFFA32D2D),
    playSound: true,
    enableVibration: true,
  );

  // ── Call once at app start ───────────────────────────────
  static Future<void> initialize() async {
    if (_initialized) return;
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _plugin.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
    );
    _initialized = true;
  }

  // ── Gas threshold alert (gas_level > 600 ppm) ───────────
  static Future<void> showGasAlert(double gasLevel) async {
    if (_gasCooldown) return;
    _gasCooldown = true;
    await _plugin.show(
      1,
      '⚠ Gas Level Alert — SmartSense',
      'Gas at ${gasLevel.toStringAsFixed(0)} ppm — limit is 600 ppm. Ventilate area immediately.',
      const NotificationDetails(android: _gasChannel, iOS: DarwinNotificationDetails()),
    );
    Future.delayed(const Duration(seconds: 60), () => _gasCooldown = false);
  }

  // ── Emergency conditions alert ───────────────────────────
  static Future<void> showEmergencyAlert(String message) async {
    await _plugin.show(
      2,
      '🚨 Critical Alert — SmartSense',
      message,
      const NotificationDetails(android: _emergencyChannel, iOS: DarwinNotificationDetails()),
    );
  }
}

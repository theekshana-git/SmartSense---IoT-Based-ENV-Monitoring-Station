// ============================================================
//  lib/screens/monitor_screen.dart
//
//  Requirements covered:
//  ✅ Live ListView of sensor metrics
//  ✅ Polls Flask API every 10 seconds via Timer
//  ✅ Non-dismissible red emergency banner 
//  ✅ Fires local push notification when gas_level > 600 ppm
// ============================================================

import 'dart:async';
import 'package:flutter/material.dart';
import '../models/sensor_data.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import '../utils/app_theme.dart';
import '../widgets/metric_card.dart';
import '../widgets/emergency_banner.dart';

class MonitorScreen extends StatefulWidget {
  const MonitorScreen({super.key});

  @override
  State<MonitorScreen> createState() => _MonitorScreenState();
}

class _MonitorScreenState extends State<MonitorScreen> {
  SensorData? _data;
  bool _loading = true;
  bool _prevCritical = false;

  Timer? _pollTimer;
  Timer? _countdownTimer;
  int _countdown = 10;
  static const _pollSeconds = 10;

  @override
  void initState() {
    super.initState();
    _fetch();
    _startTimers();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startTimers() {
    // Poll every 10 seconds
    _pollTimer = Timer.periodic(
      const Duration(seconds: _pollSeconds),
      (_) { _fetch(); setState(() => _countdown = _pollSeconds); },
    );
    // Visual countdown
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _countdown = (_countdown - 1).clamp(0, _pollSeconds));
    });
  }

  Future<void> _fetch() async {
    final data = await ApiService.fetchSensorData();
    if (!mounted) return;
    setState(() { _data = data; _loading = false; _countdown = _pollSeconds; });

    // ── Push notification: gas > 600 ppm ──────────────────
    if (data.gasExceedsThreshold) {
      await NotificationService.showGasAlert(data.gasLevel);
    }
    // ── Emergency notification: first time critical ────────
    if (data.hasCriticalAlert && !_prevCritical) {
      await NotificationService.showEmergencyAlert(data.criticalAlertMessage);
    }
    _prevCritical = data.hasCriticalAlert;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      body: SafeArea(
        child: Column(
          children: [
            _AppBar(data: _data, loading: _loading, countdown: _countdown),

            // ── Non-dismissible emergency banner ────────────
            if (_data != null && _data!.hasCriticalAlert)
              EmergencyBanner(data: _data!),

            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF378ADD),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _fetch,
                      color: const Color(0xFF378ADD),
                      child: _MetricsList(data: _data!),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── App bar ───────────────────────────────────────────────────
class _AppBar extends StatelessWidget {
  final SensorData? data;
  final bool loading;
  final int countdown;

  const _AppBar({required this.data, required this.loading, required this.countdown});

  @override
  Widget build(BuildContext context) {
    final critical = data?.hasCriticalAlert ?? false;
    return Container(
      color: const Color(0xFF1A2340),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          const Icon(Icons.sensors, color: Color(0xFF378ADD), size: 24),
          const SizedBox(width: 10),
          const Text('SmartSense', style: TextStyle(
            color: Colors.white, fontSize: 19, fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
          )),
          const Spacer(),
          if (!loading)
            _LivePill(countdown: countdown, critical: critical),
        ],
      ),
    );
  }
}

class _LivePill extends StatelessWidget {
  final int countdown;
  final bool critical;
  const _LivePill({required this.countdown, required this.critical});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(width: 6, height: 6,
            decoration: BoxDecoration(
              color: critical ? const Color(0xFFE24B4A) : const Color(0xFF1D9E75),
              shape: BoxShape.circle,
            )),
          const SizedBox(width: 6),
          Text(
            critical ? 'CRITICAL' : 'Live · ${countdown}s',
            style: TextStyle(
              color: critical ? const Color(0xFFFFAAAA) : Colors.white70,
              fontSize: 12, fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Scrollable metrics list ───────────────────────────────────
class _MetricsList extends StatelessWidget {
  final SensorData data;
  const _MetricsList({required this.data});

  @override
  Widget build(BuildContext context) {
    final ts = data.timestamp;
    final time =
        '${ts.hour.toString().padLeft(2, '0')}:${ts.minute.toString().padLeft(2, '0')}:${ts.second.toString().padLeft(2, '0')}';

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        _sectionLabel(context, 'Air Quality & Pollutants'),
        const SizedBox(height: 8),
        MetricCard(icon: Icons.blur_on, label: 'PM 1.0',
            value: '${data.pm1.toStringAsFixed(1)} µg/m³',
            status: SensorStatus.good, iconColor: const Color(0xFF0EA5E9)),
        MetricCard(icon: Icons.air, label: 'PM 2.5 (AQI)',
            value: '${data.pm25.toStringAsFixed(1)} µg/m³',
            status: data.aqiStatus, iconColor: AppColors.blue),
        MetricCard(icon: Icons.blur_circular, label: 'PM 10.0',
            value: '${data.pm10.toStringAsFixed(1)} µg/m³',
            status: SensorStatus.good, iconColor: const Color(0xFF6366F1)),
        MetricCard(icon: Icons.propane_outlined, label: 'Gas Level',
            value: '${data.gasLevel.toStringAsFixed(0)} ppm',
            status: data.gasStatus, iconColor: AppColors.red,
            showWarning: data.gasExceedsThreshold),

        const SizedBox(height: 14),
        _sectionLabel(context, 'Environment Details'),
        const SizedBox(height: 8),
        MetricCard(icon: Icons.device_thermostat, label: 'Raw Temperature',
            value: '${data.temperature.toStringAsFixed(1)} °C',
            status: SensorStatus.good, iconColor: AppColors.redMd),
        MetricCard(icon: Icons.thermostat, label: 'Heat Index (Apparent)',
            value: '${data.heatIndex.toStringAsFixed(1)} °C',
            status: data.heatStatus, iconColor: AppColors.amber),
        MetricCard(icon: Icons.water_drop_outlined, label: 'Dew Point',
            value: '${data.dewPoint.toStringAsFixed(1)} °C',
            status: SensorStatus.good, iconColor: AppColors.green),
        MetricCard(icon: Icons.water, label: 'Humidity',
            value: '${data.humidity.toStringAsFixed(0)}%',
            status: SensorStatus.good, iconColor: const Color(0xFF0F6E56)),
        MetricCard(
            icon: data.rainDetected ? Icons.water_drop : Icons.water_drop_outlined, 
            label: 'Precipitation (YL-83)',
            value: data.rainDetected ? 'Raining' : 'Clear',
            status: SensorStatus.good, 
            iconColor: data.rainDetected ? const Color(0xFF378ADD) : Colors.grey),
        MetricCard(icon: Icons.speed, label: 'Barometric Pressure',
            value: '${data.pressure.toStringAsFixed(0)} hPa',
            status: SensorStatus.good, iconColor: const Color(0xFF7F77DD)),
        MetricCard(icon: Icons.lightbulb_outline, label: 'Light Level',
            // Notice we added the lightStatusStr in parentheses here:
            value: '${data.lightLevel.toStringAsFixed(0)} LUX (${data.lightStatusStr})',
            status: SensorStatus.good, iconColor: AppColors.amberDk),

        const SizedBox(height: 20),
        Center(child: Text('Last updated $time',
            style: TextStyle(fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.35)))),
      ],
    );
  }

  Widget _sectionLabel(BuildContext context, String text) => Padding(
    padding: const EdgeInsets.only(left: 2, bottom: 0),
    child: Text(text.toUpperCase(),
        style: AppText.sectionLabel.copyWith(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
        )),
  );
}
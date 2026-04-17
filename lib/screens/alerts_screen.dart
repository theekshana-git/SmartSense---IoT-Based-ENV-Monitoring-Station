// ============================================================
//  lib/screens/alerts_screen.dart
//
//  Requirements covered:
//  ✅ Push notification simulation button (gas > 600 ppm)
//  ✅ Configurable thresholds via sliders (CRUD state)
//  ✅ Notification log with timestamps
//  ✅ Flask API URL configuration + connection test
// ============================================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import '../utils/app_theme.dart';

class _Alert {
  final String title, body;
  final DateTime time;
  final IconData icon;
  final Color iconBg, iconFg;

  const _Alert({
    required this.title, required this.body, required this.time,
    required this.icon, required this.iconBg, required this.iconFg,
  });
}

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {

  // ── Threshold CRUD state ─────────────────────────────────
  double _gasThreshold  = 600;
  double _aqiThreshold  = 150;
  double _heatThreshold = 40;
  bool   _gasEnabled    = true;
  bool   _aqiEnabled    = true;
  bool   _heatEnabled   = false;

  // ── Connection test ──────────────────────────────────────
  String _apiUrl = 'http://192.168.1.100:5000';
  bool _testing = false;
  bool? _connResult;

  // ── Notification log ─────────────────────────────────────
  final List<_Alert> _log = [
    _Alert(
      title: 'Gas Level Alert',
      body: 'Gas at 724 ppm — exceeded 600 ppm threshold.',
      time: DateTime.now().subtract(const Duration(minutes: 3)),
      icon: Icons.propane_outlined,
      iconBg: AppColors.redL, iconFg: AppColors.red,
    ),
    _Alert(
      title: 'Heat Index Warning',
      body: 'Heat index reached Danger level: 44.1 °C.',
      time: DateTime.now().subtract(const Duration(minutes: 19)),
      icon: Icons.thermostat,
      iconBg: AppColors.amberL, iconFg: AppColors.amber,
    ),
  ];

  Future<void> _testConn() async {
    setState(() { _testing = true; _connResult = null; });
    ApiService.baseUrl = _apiUrl;
    final ok = await ApiService.testConnection(_apiUrl);
    setState(() { _testing = false; _connResult = ok; });
  }

  void _simulateGasNotif() {
    NotificationService.showGasAlert(724);
    setState(() {
      _log.insert(0, _Alert(
        title: 'Gas Level Alert (simulated)',
        body: 'Simulated: 724 ppm exceeded ${_gasThreshold.toInt()} ppm limit.',
        time: DateTime.now(),
        icon: Icons.propane_outlined,
        iconBg: AppColors.redL, iconFg: AppColors.red,
      ));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // ── App bar ──────────────────────────────────
            Container(
              color: const Color(0xFF1A2340),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: const Row(
                children: [
                  Icon(Icons.notifications_outlined, color: Color(0xFF378ADD), size: 24),
                  SizedBox(width: 10),
                  Text('Alerts & Settings', style: TextStyle(
                    color: Colors.white, fontSize: 19, fontWeight: FontWeight.w700,
                    letterSpacing: -0.4,
                  )),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _label('Recent Notifications'),
                  const SizedBox(height: 8),
                  ..._log.map((e) => _AlertCard(alert: e)),

                  const SizedBox(height: 22),
                  _label('Alert Thresholds'),
                  const SizedBox(height: 10),
                  _ThresholdCard(
                    label: 'Gas Level limit', unit: 'ppm',
                    value: _gasThreshold, min: 200, max: 1000,
                    enabled: _gasEnabled,
                    onChanged: (v) => setState(() => _gasThreshold = v),
                    onToggle:  (v) => setState(() => _gasEnabled  = v),
                  ),
                  const SizedBox(height: 10),
                  _ThresholdCard(
                    label: 'AQI limit', unit: '',
                    value: _aqiThreshold, min: 50, max: 300,
                    enabled: _aqiEnabled,
                    onChanged: (v) => setState(() => _aqiThreshold = v),
                    onToggle:  (v) => setState(() => _aqiEnabled  = v),
                  ),
                  const SizedBox(height: 10),
                  _ThresholdCard(
                    label: 'Heat Index alert', unit: '°C',
                    value: _heatThreshold, min: 30, max: 55,
                    enabled: _heatEnabled,
                    onChanged: (v) => setState(() => _heatThreshold = v),
                    onToggle:  (v) => setState(() => _heatEnabled  = v),
                  ),

                  const SizedBox(height: 22),
                  _label('Push Notification Test'),
                  const SizedBox(height: 10),
                  _SimulateCard(onTap: _simulateGasNotif),

                  const SizedBox(height: 22),
                  _label('Flask API Connection'),
                  const SizedBox(height: 10),
                  _ApiConfigCard(
                    initialUrl: _apiUrl,
                    testing: _testing,
                    result: _connResult,
                    onUrlChanged: (v) => _apiUrl = v,
                    onTest: _testConn,
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Text(text.toUpperCase(),
    style: AppText.sectionLabel.copyWith(
      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4)));
}

// ── Notification log card ─────────────────────────────────────
class _AlertCard extends StatelessWidget {
  final _Alert alert;
  const _AlertCard({required this.alert});

  @override
  Widget build(BuildContext context) {
    final timeStr = DateFormat('HH:mm').format(alert.time);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.07), width: 0.5),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(width: 42, height: 42,
          decoration: BoxDecoration(color: alert.iconBg, borderRadius: BorderRadius.circular(12)),
          child: Icon(alert.icon, size: 20, color: alert.iconFg)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(alert.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          const SizedBox(height: 3),
          Text(alert.body, style: TextStyle(
            fontSize: 12, height: 1.4,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
          const SizedBox(height: 5),
          Text('Today · $timeStr', style: TextStyle(
            fontSize: 11,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.35))),
        ])),
      ]),
    );
  }
}

// ── Threshold card with slider + toggle ───────────────────────
class _ThresholdCard extends StatelessWidget {
  final String label, unit;
  final double value, min, max;
  final bool enabled;
  final ValueChanged<double> onChanged;
  final ValueChanged<bool>   onToggle;

  const _ThresholdCard({
    required this.label, required this.unit, required this.value,
    required this.min, required this.max, required this.enabled,
    required this.onChanged, required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 14, 8, enabled ? 6 : 14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.07), width: 0.5),
      ),
      child: Column(children: [
        Row(children: [
          Expanded(child: Text(label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500))),
          Text('${value.toInt()} $unit',
            style: const TextStyle(fontSize: 14,
              fontWeight: FontWeight.w500, color: AppColors.blueDk)),
          const SizedBox(width: 4),
          Switch(value: enabled, onChanged: onToggle,
            activeThumbColor: AppColors.green, materialTapTargetSize: MaterialTapTargetSize.shrinkWrap),
        ]),
        if (enabled)
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.blue,
              thumbColor: AppColors.blueDk,
              inactiveTrackColor: AppColors.blueL,
              overlayColor: AppColors.blue.withOpacity(0.12),
              trackHeight: 3,
            ),
            child: Slider(value: value, min: min, max: max,
              divisions: ((max - min) / 10).round(),
              onChanged: onChanged),
          ),
      ]),
    );
  }
}

// ── Simulate notification card ────────────────────────────────
class _SimulateCard extends StatelessWidget {
  final VoidCallback onTap;
  const _SimulateCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.07), width: 0.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Tap the button below to fire a simulated gas level alert (724 ppm).',
          style: TextStyle(fontSize: 13, height: 1.5,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.65))),
        const SizedBox(height: 14),
        SizedBox(width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: onTap,
            icon: const Icon(Icons.notifications_active_rounded, size: 18),
            label: const Text('Send Test Notification'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          )),
      ]),
    );
  }
}

// ── API connection config card ────────────────────────────────
class _ApiConfigCard extends StatelessWidget {
  final String initialUrl;
  final bool testing;
  final bool? result;
  final ValueChanged<String> onUrlChanged;
  final VoidCallback onTest;

  const _ApiConfigCard({
    required this.initialUrl, required this.testing,
    required this.result, required this.onUrlChanged, required this.onTest,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.07), width: 0.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Flask Server URL',
          style: TextStyle(fontSize: 12,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5))),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: initialUrl,
          style: const TextStyle(fontSize: 13, fontFamily: 'monospace'),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.black.withOpacity(0.15), width: 0.5)),
            hintText: 'http://192.168.x.x:5000',
          ),
          onChanged: onUrlChanged,
        ),

        if (result != null) ...[
          const SizedBox(height: 10),
          Row(children: [
            Icon(result! ? Icons.check_circle_outline : Icons.error_outline,
              size: 16, color: result! ? AppColors.green : AppColors.red),
            const SizedBox(width: 6),
            Text(result! ? 'Connected successfully' : 'Could not reach server',
              style: TextStyle(fontSize: 12,
                color: result! ? AppColors.green : AppColors.red)),
          ]),
        ],

        const SizedBox(height: 12),
        SizedBox(width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: testing ? null : onTest,
            icon: testing
                ? const SizedBox(width: 14, height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.wifi_tethering_rounded, size: 16),
            label: Text(testing ? 'Testing...' : 'Test Connection'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A2340),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          )),
      ]),
    );
  }
}

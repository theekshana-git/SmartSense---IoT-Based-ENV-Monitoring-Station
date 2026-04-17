// ============================================================
//  lib/widgets/emergency_banner.dart
//  Persistent, NON-DISMISSIBLE red banner.
//  Shown at top of MonitorScreen when any sensor is
//  "Danger" or "Hazardous". Has a pulsing dot animation.
// ============================================================

import 'package:flutter/material.dart';
import '../models/sensor_data.dart';

class EmergencyBanner extends StatefulWidget {
  final SensorData data;
  const EmergencyBanner({super.key, required this.data});

  @override
  State<EmergencyBanner> createState() => _EmergencyBannerState();
}

class _EmergencyBannerState extends State<EmergencyBanner>
    with SingleTickerProviderStateMixin {

  late final AnimationController _pulse;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    )..repeat(reverse: true);

    _opacity = Tween<double>(begin: 0.35, end: 1.0)
        .animate(CurvedAnimation(parent: _pulse, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFA32D2D),
      // ⚠ No close button — intentionally non-dismissible
      child: SafeArea(
        top: false, bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ── Pulsing dot ──────────────────────────
              FadeTransition(
                opacity: _opacity,
                child: Container(
                  width: 8, height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFCEBEB),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // ── Warning icon ────────────────────────
              const Icon(Icons.warning_amber_rounded,
                color: Color(0xFFFCEBEB), size: 19),
              const SizedBox(width: 8),

              // ── Alert message ───────────────────────
              Expanded(
                child: Text(
                  'ALERT — ${widget.data.criticalAlertMessage}',
                  style: const TextStyle(
                    color: Color(0xFFFCEBEB),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

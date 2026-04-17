// ============================================================
//  lib/widgets/metric_card.dart
//  Sensor metric card used in MonitorScreen ListView.
//  Auto-colours borders and values based on SensorStatus.
// ============================================================

import 'package:flutter/material.dart';
import '../models/sensor_data.dart';
import '../utils/app_theme.dart';

class MetricCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final SensorStatus status;
  final Color iconColor;
  final bool showWarning;

  const MetricCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.status,
    required this.iconColor,
    this.showWarning = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDanger = status.isCritical;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDanger ? AppColors.redL : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDanger ? AppColors.redMd : Colors.black.withOpacity(0.07),
          width: isDanger ? 1 : 0.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(children: [

          // ── Icon container ─────────────────────────────
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isDanger
                  ? AppColors.red.withOpacity(0.12)
                  : iconColor.withOpacity(0.11),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon,
              color: isDanger ? AppColors.red : iconColor,
              size: 21),
          ),

          const SizedBox(width: 14),

          // ── Label + value ──────────────────────────────
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: AppText.cardLabel.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5))),
              const SizedBox(height: 4),
              Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                Text(value, style: AppText.cardValue.copyWith(
                  color: isDanger ? AppColors.red : Theme.of(context).colorScheme.onSurface,
                )),
                if (showWarning) ...[
                  const SizedBox(width: 6),
                  const Icon(Icons.warning_amber_rounded,
                    color: AppColors.red, size: 16),
                ],
              ]),
            ]),
          ),

          // ── Status badge ───────────────────────────────
          _StatusBadge(status: status),
        ]),
      ),
    );
  }
}

// ── Color-coded status pill ────────────────────────────────────
class _StatusBadge extends StatelessWidget {
  final SensorStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.statusBg(status),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Text(status.label, style: AppText.badge.copyWith(
        color: AppColors.statusFg(status),
      )),
    );
  }
}

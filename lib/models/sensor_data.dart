// ============================================================
//  lib/models/sensor_data.dart
//  Data model that mirrors the Flask API JSON payload.
//  Contains all status/threshold logic in one place.
// ============================================================

enum SensorStatus { good, moderate, unhealthy, danger, hazardous }

extension SensorStatusX on SensorStatus {
  String get label {
    switch (this) {
      case SensorStatus.good:      return 'Good';
      case SensorStatus.moderate:  return 'Moderate';
      case SensorStatus.unhealthy: return 'Unhealthy';
      case SensorStatus.danger:    return 'Danger';
      case SensorStatus.hazardous: return 'Hazardous';
    }
  }

  bool get isCritical =>
      this == SensorStatus.danger || this == SensorStatus.hazardous;
}

// ── Main sensor data class ─────────────────────────────────
class SensorData {
  final double temperature;
  final double humidity;
  final double pressure;
  final double heatIndex;
  final double dewPoint;
  final double gasLevel;
  final double pm25;
  final double aqi;
  final DateTime timestamp;

  const SensorData({
    required this.temperature,
    required this.humidity,
    required this.pressure,
    required this.heatIndex,
    required this.dewPoint,
    required this.gasLevel,
    required this.pm25,
    required this.aqi,
    required this.timestamp,
  });

  // ── Parse from Flask JSON ────────────────────────────────
  factory SensorData.fromJson(Map<String, dynamic> json) {
    return SensorData(
      temperature: (json['temperature'] ?? 30.0).toDouble(),
      humidity:    (json['humidity']    ?? 60.0).toDouble(),
      pressure:    (json['pressure']    ?? 1013.0).toDouble(),
      heatIndex:   (json['heat_index']  ?? 30.0).toDouble(),
      dewPoint:    (json['dew_point']   ?? 20.0).toDouble(),
      gasLevel:    (json['gas_level']   ?? 400.0).toDouble(),
      pm25:        (json['pm25']        ?? 15.0).toDouble(),
      aqi:         (json['aqi']         ?? 60.0).toDouble(),
      timestamp:   DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
    );
  }

  // ── Mock data — used when API is unreachable ─────────────
  factory SensorData.mock({bool critical = false}) => SensorData(
    temperature: critical ? 42.0 : 30.5,
    humidity:    64.0,
    pressure:    1013.2,
    heatIndex:   critical ? 44.1 : 34.2,
    dewPoint:    21.5,
    gasLevel:    critical ? 724.0 : 482.0,
    pm25:        18.4,
    aqi:         critical ? 198.0 : 72.0,
    timestamp:   DateTime.now(),
  );

  // ── Status computations ─────────────────────────────────
  SensorStatus get aqiStatus {
    if (aqi < 50)  return SensorStatus.good;
    if (aqi < 100) return SensorStatus.moderate;
    if (aqi < 150) return SensorStatus.unhealthy;
    if (aqi < 200) return SensorStatus.danger;
    return SensorStatus.hazardous;
  }

  SensorStatus get heatStatus {
    if (heatIndex < 27) return SensorStatus.good;
    if (heatIndex < 32) return SensorStatus.moderate;
    if (heatIndex < 40) return SensorStatus.unhealthy;
    if (heatIndex < 45) return SensorStatus.danger;
    return SensorStatus.hazardous;
  }

  SensorStatus get gasStatus {
    if (gasLevel < 300) return SensorStatus.good;
    if (gasLevel < 500) return SensorStatus.moderate;
    if (gasLevel < 600) return SensorStatus.unhealthy;
    if (gasLevel < 800) return SensorStatus.danger;
    return SensorStatus.hazardous;
  }

  SensorStatus get humidityStatus {
    if (humidity < 30 || humidity > 80) return SensorStatus.moderate;
    return SensorStatus.good;
  }

  SensorStatus get pm25Status {
    if (pm25 < 12) return SensorStatus.good;
    if (pm25 < 35) return SensorStatus.moderate;
    return SensorStatus.danger;
  }

  // ── Emergency trigger: any Danger or Hazardous ──────────
  bool get hasCriticalAlert =>
      aqiStatus.isCritical || heatStatus.isCritical || gasStatus.isCritical;

  // ── Push notification trigger ────────────────────────────
  bool get gasExceedsThreshold => gasLevel > 600;

  // ── Build banner message from triggered sensors ──────────
  String get criticalAlertMessage {
    final triggers = <String>[];
    if (aqiStatus.isCritical)  triggers.add('AQI');
    if (heatStatus.isCritical) triggers.add('Heat Index');
    if (gasStatus.isCritical)  triggers.add('Gas Level');
    final joined = triggers.join(', ');
    return '$joined ${triggers.length == 1 ? "is" : "are"} at dangerous levels. Stay indoors.';
  }
}

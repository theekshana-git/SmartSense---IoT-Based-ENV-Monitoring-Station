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
  bool get isCritical => this == SensorStatus.danger || this == SensorStatus.hazardous;
}

class SensorData {
  final double temperature;
  final double humidity;
  final double pressure;
  final double heatIndex;
  final double dewPoint;
  final double gasLevel;
  final double pm1;
  final double pm25;
  final double pm10;
  final double lightLevel;
  final bool rainDetected;
  
  // Edge Intelligence Strings from ESP32 / Flask
  final String aqiStatusStr;
  final String heatStatusStr;
  final String dewStatusStr;
  final String lightStatusStr; // <--- ADDED THIS
  final DateTime timestamp;

  const SensorData({
    required this.temperature, required this.humidity, required this.pressure,
    required this.heatIndex, required this.dewPoint, required this.gasLevel,
    required this.pm1, required this.pm25, required this.pm10, 
    required this.lightLevel, required this.aqiStatusStr,
    required this.heatStatusStr, required this.dewStatusStr, 
    required this.lightStatusStr, required this.timestamp, required this.rainDetected, // <--- ADDED THIS
  });

  factory SensorData.fromJson(Map<String, dynamic> json) {
    return SensorData(
      temperature:   (json['temperature'] ?? 30.0).toDouble(),
      humidity:      (json['humidity']    ?? 60.0).toDouble(),
      pressure:      (json['pressure']    ?? 1013.0).toDouble(),
      heatIndex:     (json['heat_index']  ?? 30.0).toDouble(),
      dewPoint:      (json['dew_point']   ?? 20.0).toDouble(),
      gasLevel:      (json['gas_level']   ?? 400.0).toDouble(),
      pm1:           (json['pm1_0']       ?? 10.0).toDouble(), 
      pm25:          (json['pm2_5']       ?? 15.0).toDouble(), 
      pm10:          (json['pm10_0']      ?? 20.0).toDouble(), 
      lightLevel:    (json['light_level'] ?? 0.0).toDouble(),
      rainDetected:  (json['rain_detected'] == 1 || json['rain_detected'] == true),  
      aqiStatusStr:  json['aqi_status']   ?? 'Good',
      heatStatusStr: json['heat_status']  ?? 'Safe',
      dewStatusStr:  json['dew_status']   ?? 'Safe',
      lightStatusStr: json['light_status'] ?? 'Normal', // <--- ADDED THIS
      timestamp:     DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
    );
  }

  factory SensorData.mock({bool critical = false}) => SensorData(
    temperature: critical ? 42.0 : 30.5, humidity: 64.0, pressure: 1013.2,
    heatIndex: critical ? 44.1 : 34.2, dewPoint: 21.5,
    gasLevel: critical ? 1600.0 : 482.0, 
    pm1: 12.0, pm25: 18.4, pm10: 24.5, lightLevel: 800.0,
    aqiStatusStr: critical ? 'Hazardous' : 'Good',
    heatStatusStr: critical ? 'Danger' : 'Safe',
    dewStatusStr: 'Safe', 
    lightStatusStr: 'Bright',
    rainDetected: critical, // <--- ADDED THIS
    timestamp: DateTime.now(),
  );

  // Helper to convert ESP32 Strings to Flutter UI Colors
  SensorStatus _mapEdgeStatus(String status) {
    final s = status.toLowerCase();
    if (s.contains('hazardous') || s.contains('danger')) return SensorStatus.hazardous;
    if (s.contains('unhealthy') || s.contains('high risk')) return SensorStatus.danger;
    if (s.contains('moderate') || s.contains('caution')) return SensorStatus.moderate;
    return SensorStatus.good;
  }

  SensorStatus get aqiStatus => _mapEdgeStatus(aqiStatusStr);
  SensorStatus get heatStatus => _mapEdgeStatus(heatStatusStr);
  
  SensorStatus get gasStatus {
    if (gasLevel < 800) return SensorStatus.good;
    if (gasLevel < 1200) return SensorStatus.moderate;
    if (gasLevel < 1500) return SensorStatus.unhealthy;
    if (gasLevel < 2000) return SensorStatus.danger;
    return SensorStatus.hazardous;
  }

  bool get hasCriticalAlert => aqiStatus.isCritical || heatStatus.isCritical || gasStatus.isCritical;
  bool get gasExceedsThreshold => gasLevel > 1500;

  String get criticalAlertMessage {
    final triggers = <String>[];
    if (aqiStatus.isCritical)  triggers.add('AQI');
    if (heatStatus.isCritical) triggers.add('Heat Index');
    if (gasStatus.isCritical)  triggers.add('Gas Level');
    final joined = triggers.join(', ');
    return '$joined ${triggers.length == 1 ? "is" : "are"} at dangerous levels.';
  }
}
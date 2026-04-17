import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/sensor_data.dart';

class ApiService {
  // ── MATCHED TO YOUR ESP32 IP ADDRESS ──────────
  static String baseUrl = 'http://192.168.129.27:5000';

  static const Duration _timeout = Duration(seconds: 5);

  static Future<SensorData> fetchSensorData() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/api/data')).timeout(_timeout);
      if (res.statusCode == 200) {
        return SensorData.fromJson(jsonDecode(res.body));
      }
    } catch (_) {}
    return SensorData.mock();
  }

  static Future<Map<String, dynamic>> fetchForecast() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/api/forecast')).timeout(_timeout);
      if (res.statusCode == 200) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return {
      'status': 'Storm Incoming', 'confidence': 87, 'pressure_trend': -2.4,
      'wind_forecast': '↑ 45 km/h', 'time_window': '3–6 hrs', 'risk': 'High Risk',
      'pressure_history': [1015.0, 1014.2, 1013.0, 1011.5, 1009.8, 1007.4, 1005.2, 1003.0],
    };
  }

  static Future<bool> testConnection(String url) async {
    try {
      final res = await http.get(Uri.parse('$url/api/history')).timeout(_timeout);
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
# SmartSense — Mobile Application (Team 4)
Flutter / Dart · IoT Environmental Monitoring App

---

## App Screens

| # | Screen | File | What it does |
|---|---|---|---|
| 1 | Splash | `splash_screen.dart` | Animated logo + text + pulsing dots → fades to Home |
| 2 | Live Monitor | `monitor_screen.dart` | Polls API every 10s, shows all sensor metrics |
| 3 | Emergency State | (monitor, conditional) | Non-dismissible red banner on Danger/Hazardous |
| 4 | Weather Forecast | `forecast_screen.dart` | Team 5 dP/dt weather prediction display |
| 5 | Alerts & Settings | `alerts_screen.dart` | Notification log, threshold CRUD, API config |

---

## Requirements Coverage

| Requirement | Implemented In | Notes |
|---|---|---|
| Live monitoring ListView/GridView | `monitor_screen.dart` | ListView, 6 metrics |
| Polls every 5–10 seconds | `monitor_screen.dart` | Timer set to 10s |
| Emergency banner if Danger/Hazardous | `emergency_banner.dart` | Non-dismissible, no close button |
| Smart Logic in Dart | `sensor_data.dart` (.hasCriticalAlert) | Checks all 3 sensor statuses |
| Weather Outlook from Team 5 | `forecast_screen.dart` | Calls /api/forecast |
| Push notification gas > 600 ppm | `notification_service.dart` | 60s cooldown |

---

## Project Structure

```
lib/
├── main.dart                          ← App entry, theme, routing
├── utils/
│   └── app_theme.dart                 ← Design tokens (colors, text styles)
├── models/
│   └── sensor_data.dart               ← Data model + all status logic
├── services/
│   ├── api_service.dart               ← Flask API calls + mock fallback
│   └── notification_service.dart      ← Local push notifications
├── screens/
│   ├── splash_screen.dart             ← Animated splash (800ms logo + 600ms text)
│   ├── home_screen.dart               ← Bottom nav shell (IndexedStack)
│   ├── monitor_screen.dart            ← Live polling + emergency banner
│   ├── forecast_screen.dart           ← Team 5 weather forecast
│   └── alerts_screen.dart             ← Notification log + thresholds
└── widgets/
    ├── metric_card.dart               ← Reusable sensor card
    └── emergency_banner.dart          ← Red non-dismissible banner
```

---

## Setup (3 Steps)

### 1. Install dependencies
```bash
flutter pub get
```

### 2. Set your Flask server IP
Open `lib/services/api_service.dart` and update:
```dart
static String baseUrl = 'http://192.168.1.100:5000';
```
Or update it at runtime from the **Alerts → Flask API Connection** panel.

### 3. Run
```bash
flutter run
```

> **No Flask server?** The app automatically uses mock data — just run it and it works.

---

## Android Setup

Copy `android_manifest.xml` content to:
`android/app/src/main/AndroidManifest.xml`

## iOS Setup

Add to `ios/Runner/Info.plist`:
```xml
<key>NSUserNotificationUsageDescription</key>
<string>SmartSense sends alerts when environmental conditions are dangerous.</string>
```

---

## API Contract (Flask — Team 2)

### GET /api/data → SensorData
```json
{
  "temperature": 30.5,
  "humidity": 64.0,
  "pressure": 1013.2,
  "heat_index": 34.2,
  "dew_point": 21.5,
  "gas_level": 482.0,
  "pm25": 18.4,
  "aqi": 72.0,
  "timestamp": "2025-01-01T09:41:00"
}
```

### GET /api/forecast → Forecast (Team 5)
```json
{
  "status": "Storm Incoming",
  "confidence": 87,
  "pressure_trend": -2.4,
  "wind_forecast": "↑ 45 km/h",
  "time_window": "3–6 hrs",
  "risk": "High Risk",
  "pressure_history": [1015.0, 1014.2, 1013.0, 1011.5, 1009.8, 1007.4, 1005.2, 1003.0]
}
```

---

## Status Thresholds

| Sensor | Good | Moderate | Unhealthy | Danger | Hazardous |
|---|---|---|---|---|---|
| AQI | < 50 | 50–100 | 100–150 | 150–200 | ≥ 200 |
| Heat Index | < 27°C | 27–32 | 32–40 | 40–45 | ≥ 45 |
| Gas Level | < 300 ppm | 300–500 | 500–600 | 600–800 | ≥ 800 |

- Emergency banner = **any** Danger or Hazardous
- Push notification = **gas_level > 600 ppm**

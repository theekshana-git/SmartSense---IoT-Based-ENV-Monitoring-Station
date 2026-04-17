#include <WiFi.h>
#include <HTTPClient.h>
#include <Wire.h>
#include <Adafruit_BMP280.h>
#include <DHT.h>
#include <PMS.h>

// --- Network Credentials ---
const char* ssid = "Redmi Note 8";
const char* password = "20060601";
const char* serverName = "http://192.168.129.27:5000/sensor";

// --- Timing Variables ---
unsigned long lastPostTime = 0;
const unsigned long postInterval = 8000; // 8 seconds in milliseconds

// --- Sensor Pin Definitions ---
#define DHTPIN 27
#define DHTTYPE DHT22
#define LDR_PIN 34
#define MQ135_PIN 35
#define RAIN_PIN 32
#define PMS_RX 16
#define PMS_TX 17

// --- Object Initializations ---
DHT dht(DHTPIN, DHTTYPE);
Adafruit_BMP280 bmp;
HardwareSerial pmsSerial(2);
PMS pms(pmsSerial);
PMS::DATA pmsData;

// ==========================================
// --- EDGE INTELLIGENCE HELPER FUNCTIONS ---
// ==========================================

// 1. AQI Logic (PM2.5)
void getAQI(int pm25, String &status, String &rec) {
  if (pm25 <= 12) { 
    status = "Good"; 
    rec = "Air quality is ideal. Safe to open windows."; 
  } else if (pm25 <= 35) { 
    status = "Moderate"; 
    rec = "Acceptable air. Sensitive individuals limit heavy exertion."; 
  } else if (pm25 <= 55) { 
    status = "Unhealthy (Sensitive)"; 
    rec = "Close windows. Run air purifier if available."; 
  } else if (pm25 <= 150) { 
    status = "Unhealthy"; 
    rec = "Wear a mask outdoors. Limit outdoor activities."; 
  } else { 
    status = "Hazardous"; 
    rec = "HAZARDOUS: Stay indoors! Use N95 mask if going out."; 
  }
}

// 2. Dew Point & Condensation Logic
float calculateDewPoint(float temp, float hum) {
  float a = 17.27;
  float b = 237.7;
  float alpha = ((a * temp) / (b + temp)) + log(hum / 100.0);
  return (b * alpha) / (a - alpha);
}

void getDewPointRisk(float temp, float dewPoint, String &status, String &rec) {
  // If the temperature drops to within 2 degrees of the dew point, condensation is imminent
  if (temp - dewPoint <= 2.0) {
    status = "High Risk";
    rec = "Condensation imminent! Turn on dehumidifier or heating to prevent rust/mold.";
  } else {
    status = "Safe";
    rec = "No condensation risk detected.";
  }
}

// 3. Heat Index Logic (Worker Safety)
void getHeatIndexRisk(float hi, String &status, String &rec) {
  if (hi < 27.0) {
    status = "Safe";
    rec = "Comfortable working conditions.";
  } else if (hi < 32.0) {
    status = "Caution";
    rec = "Caution: Stay hydrated during physical labor.";
  } else if (hi < 39.0) {
    status = "Extreme Caution";
    rec = "Extreme Caution: Take frequent cooling breaks.";
  } else {
    status = "Danger";
    rec = "DANGER: High heatstroke risk! Halt heavy labor immediately.";
  }
}

// 4. Lighting State Logic
void getLightStatus(int ldr, String &status, String &rec) {
  // Adjust these thresholds based on how your LDR responds to your room lighting
  if (ldr > 3000) {
    status = "Dark / Night";
    rec = "Turn on lights. Ensure security cameras are active.";
  } else if (ldr > 1500) {
    status = "Dim Lighting";
    rec = "Increase illumination for precision work and safety.";
  } else if (ldr > 400) {
    status = "Optimal Workspace";
    rec = "Lighting is adequate for general tasks.";
  } else {
    status = "Excessive Glare";
    rec = "Lower blinds. Glare may cause eye strain.";
  }
}

// ==========================================
// --- MAIN SETUP AND LOOP ---
// ==========================================

void setup() {
  Serial.begin(115200);

  dht.begin();
  if (!bmp.begin(0x76)) {
    Serial.println("BMP280 not found! Check wiring.");
  }
  pinMode(RAIN_PIN, INPUT);
  pmsSerial.begin(9600, SERIAL_8N1, PMS_RX, PMS_TX);

  WiFi.begin(ssid, password);
  Serial.print("Connecting to WiFi");
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println("\nConnected to WiFi!");
  Serial.println("Smart Environmental Node Starting...");
}

void loop() {
  // 1. Constantly read the PMS sensor! 
  // This keeps the Serial buffer empty and updates pmsData instantly whenever a valid frame arrives.
  pms.read(pmsData);

  // 2. Look at the stopwatch: Have 8 seconds passed?
  if (millis() - lastPostTime >= postInterval) {
    lastPostTime = millis(); // Reset the stopwatch

    // 3. Read the rest of the sensors
    float temperature = dht.readTemperature();
    float humidity = dht.readHumidity();
    float pressure = bmp.readPressure() / 100.0F;
    int ldrValue = analogRead(LDR_PIN);
    int mqValue = analogRead(MQ135_PIN);
    int rainValue = digitalRead(RAIN_PIN); 

    if (WiFi.status() == WL_CONNECTED) {
      
      // --- RUN EDGE INTELLIGENCE ---
      String aqiStatus, aqiRec;
      getAQI(pmsData.PM_AE_UG_2_5, aqiStatus, aqiRec);

      float dewPoint = calculateDewPoint(temperature, humidity);
      String dewStatus, dewRec;
      getDewPointRisk(temperature, dewPoint, dewStatus, dewRec);

      float heatIndex = dht.computeHeatIndex(temperature, humidity, false);
      String heatStatus, heatRec;
      getHeatIndexRisk(heatIndex, heatStatus, heatRec);

      String lightStatus, lightRec;
      getLightStatus(ldrValue, lightStatus, lightRec);

      // --- BUILD EXTENDED JSON PAYLOAD ---
      HTTPClient http;
      http.begin(serverName);
      http.addHeader("Content-Type", "application/json");

      String jsonPayload = "{";
      // Raw Data
      jsonPayload += "\"temperature\":" + String(temperature) + ",";
      jsonPayload += "\"humidity\":" + String(humidity) + ",";
      jsonPayload += "\"pressure\":" + String(pressure) + ",";
      jsonPayload += "\"pm1_0\":" + String(pmsData.PM_AE_UG_1_0) + ",";
      jsonPayload += "\"pm2_5\":" + String(pmsData.PM_AE_UG_2_5) + ",";
      jsonPayload += "\"pm10_0\":" + String(pmsData.PM_AE_UG_10_0) + ",";
      jsonPayload += "\"gas_level\":" + String(mqValue) + ",";
      jsonPayload += "\"rain_detected\":" + String(rainValue == 0 ? "true" : "false") + ",";
      jsonPayload += "\"light_level\":" + String(ldrValue) + ",";
      
      // Smart Edge Data
      jsonPayload += "\"aqi_status\":\"" + aqiStatus + "\",";
      jsonPayload += "\"aqi_rec\":\"" + aqiRec + "\",";
      
      jsonPayload += "\"dew_point\":" + String(dewPoint) + ",";
      jsonPayload += "\"dew_status\":\"" + dewStatus + "\",";
      jsonPayload += "\"dew_rec\":\"" + dewRec + "\",";
      
      jsonPayload += "\"heat_index\":" + String(heatIndex) + ",";
      jsonPayload += "\"heat_status\":\"" + heatStatus + "\",";
      jsonPayload += "\"heat_rec\":\"" + heatRec + "\",";
      
      jsonPayload += "\"light_status\":\"" + lightStatus + "\",";
      jsonPayload += "\"light_rec\":\"" + lightRec + "\""; 
      jsonPayload += "}";

      Serial.println("Sending Smart Data: " + jsonPayload);

      int responseCode = http.POST(jsonPayload);

      if (responseCode > 0) {
        Serial.print("Server Response Code: ");
        Serial.println(responseCode);
      } else {
        Serial.print("Error sending POST: ");
        Serial.println(responseCode);
      }

      http.end(); 
    } else {
      Serial.println("WiFi Disconnected. Attempting to reconnect...");
      WiFi.reconnect();
    }
  }
  
  // Feed the FreeRTOS watchdog timer to prevent crashes
  delay(10); 
}
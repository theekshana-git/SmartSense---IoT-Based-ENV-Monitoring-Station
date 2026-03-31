#include <WiFi.h>
#include <HTTPClient.h>
#include <Wire.h>
#include <Adafruit_BMP280.h>
#include <DHT.h>
#include <PMS.h>

// --- Network Credentials ---
const char* ssid = "Redmi Note 8";
const char* password = "20060601";
const char* serverName = "http://192.168.216.27:5000/sensor";

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

void setup() {
  Serial.begin(115200);

  // 1. Initialize Sensors
  dht.begin();
  if (!bmp.begin(0x76)) {
    Serial.println("BMP280 not found! Check wiring.");
  }
  pinMode(RAIN_PIN, INPUT);
  pmsSerial.begin(9600, SERIAL_8N1, PMS_RX, PMS_TX);

  // 2. Initialize WiFi
  WiFi.begin(ssid, password);
  Serial.print("Connecting to WiFi");
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println("\nConnected to WiFi!");
  Serial.println("Environmental Node Starting...");
}

void loop() {
  // Read standard sensors
  float temperature = dht.readTemperature();
  float humidity = dht.readHumidity();
  float pressure = bmp.readPressure() / 100.0F;
  int ldrValue = analogRead(LDR_PIN);
  int mqValue = analogRead(MQ135_PIN);
  int rainValue = digitalRead(RAIN_PIN); // 0 usually means raining, 1 means dry

  // The PMS sensor requires a specific read structure.
  // We will only build and send the JSON when we have a successful PMS reading.
  if (pms.read(pmsData)) {
    
    // Check if WiFi is still connected before trying to send
    if (WiFi.status() == WL_CONNECTED) {
      HTTPClient http;
      http.begin(serverName);
      http.addHeader("Content-Type", "application/json");

      // Build the JSON string dynamically
      String jsonPayload = "{";
      jsonPayload += "\"temperature\":" + String(temperature) + ",";
      jsonPayload += "\"humidity\":" + String(humidity) + ",";
      jsonPayload += "\"pressure\":" + String(pressure) + ",";
      jsonPayload += "\"pm1_0\":" + String(pmsData.PM_AE_UG_1_0) + ",";
      jsonPayload += "\"pm2_5\":" + String(pmsData.PM_AE_UG_2_5) + ",";
      jsonPayload += "\"pm10_0\":" + String(pmsData.PM_AE_UG_10_0) + ",";
      jsonPayload += "\"gas_level\":" + String(mqValue) + ",";
      jsonPayload += "\"rain_detected\":" + String(rainValue == 0 ? "true" : "false") + ",";
      jsonPayload += "\"light_level\":" + String(ldrValue);
      jsonPayload += "}";

      Serial.println("Sending Data: " + jsonPayload);

      // Send the POST request
      int responseCode = http.POST(jsonPayload);

      if (responseCode > 0) {
        Serial.print("Server Response Code: ");
        Serial.println(responseCode);
      } else {
        Serial.print("Error sending POST: ");
        Serial.println(responseCode);
      }

      http.end(); // Free resources
    } else {
      Serial.println("WiFi Disconnected. Attempting to reconnect...");
      WiFi.reconnect();
    }
  }

  // Wait 5 seconds before the next reading/sending cycle
  // This prevents spamming your Flask server with too many requests
  delay(5000);
}
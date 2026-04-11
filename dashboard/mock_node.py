import requests
import time
import random

SERVER_URL = "http://127.0.0.1:5000/sensor"

print("Starting Mock ESP32 Node...")
print("Sending data every 5 seconds...\n")

while True:
    fake_data = {
        "temperature": round(random.uniform(25, 35), 1),
        "humidity": round(random.uniform(50, 80), 1),
        "pressure": round(random.uniform(1000, 1020), 1),
        "pm1_0": random.randint(5, 20),
        "pm2_5": random.randint(10, 40),
        "pm10_0": random.randint(15, 50),
        "gas_level": random.randint(300, 600),
        "rain_detected": random.choice([True, False]),
        "light_level": random.randint(1000, 5000),

        "aqi_status": random.choice(["Good", "Moderate", "Hazardous"]),
        "aqi_rec": "Mock AQI Recommendation text here.",

        "dew_point": round(random.uniform(15.0, 25.0), 1),
        "dew_status": random.choice(["Safe", "High Risk"]),
        "dew_rec": "Mock Dew Point Recommendation text here.",

        "heat_index": round(random.uniform(26.0, 35.0), 1),
        "heat_status": random.choice(["Safe", "Caution", "Danger"]),
        "heat_rec": "Mock Heat Index Recommendation text here.",

        "light_status": "Optimal Workspace",
        "light_rec": "Mock Lighting Recommendation text here."
    }

    try:
        response = requests.post(SERVER_URL, json=fake_data)
        print("Sent:", fake_data)
        print("Response:", response.status_code, "\n")
    except Exception as e:
        print("Error:", e)

    time.sleep(5)
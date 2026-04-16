import requests
import time
import random

SERVER_URL = "http://localhost:5000/sensor"

def send_mock_data():
    print("Starting Fake Data Generator...")
    while True:
        fake_data = {
            "temperature": round(random.uniform(20.0, 35.0), 1),
            "humidity": round(random.uniform(40.0, 80.0), 1),
            "pressure": round(random.uniform(1000.0, 1020.0), 1),
            "pm1_0": random.randint(5, 15),
            "pm2_5": random.randint(10, 50),
            "pm10_0": random.randint(20, 80),
            "gas_level": random.randint(300, 600),
            "rain_detected": random.choice([True, False]),
            "light_level": random.randint(500, 3000),
            
            # The new Edge Intelligence requirements
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
            print(f"Sent data successfully! Server responded: {response.status_code}")
        except Exception as e:
            print(f"Error connecting to server. Is server.py running? Error: {e}")
        
        # Wait 3 seconds before sending the next reading
        time.sleep(3)

if __name__ == "__main__":
    send_mock_data()
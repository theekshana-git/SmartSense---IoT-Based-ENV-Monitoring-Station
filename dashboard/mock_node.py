# Run this script to simulate the ESP32 sending data to the Flask server.
import requests
import time
import random

# Ensure this matches the port your server.py is running on
SERVER_URL = "http://localhost:5000/sensor"

print("Starting Mock ESP32 Node...")
print(f"Sending fake data to {SERVER_URL} every 5 seconds.")
print("Press Ctrl+C to stop.")

while True:
    # Generate realistic fake data matching the ESP32 JSON structure
    fake_data = {
        "temperature": round(random.uniform(25.0, 35.0), 1),
        "humidity": round(random.uniform(50.0, 80.0), 1),
        "pressure": round(random.uniform(1005.0, 1015.0), 2),
        "pm1_0": random.randint(10, 30),
        "pm2_5": random.randint(15, 50),
        "pm10_0": random.randint(20, 70),
        "gas_level": random.randint(300, 800),
        "rain_detected": random.choice([True, False, False, False]), # Weighted to be mostly false
        "light_level": random.randint(100, 4000)
    }

    try:
        response = requests.post(SERVER_URL, json=fake_data)
        if response.status_code == 200:
            print(f"Success! Sent mock data: Temp: {fake_data['temperature']}C, Gas: {fake_data['gas_level']}")
        else:
            print(f"Server returned status code: {response.status_code}")
    except requests.exceptions.ConnectionError:
        print("Error: Could not connect to server. Is your server.py running?")
    
    time.sleep(5) # Wait 5 seconds before sending the next reading
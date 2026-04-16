import requests
import time
import random

SERVER_URL = "http://127.0.0.1:5000/sensor"

print("Starting SmartSense Edge Node Simulator...")

while True:
    # 1. Generate random raw sensor data FIRST
    temp = round(random.uniform(22.0, 40.0), 1)
    hum = round(random.uniform(40.0, 85.0), 1)
    pm25 = random.randint(10, 150) # Will sometimes trigger the "Hazardous" alert

    # 2. EDGE LOGIC: Calculate AQI Status & Recommendations
    if pm25 > 100:
        aqi_status = "Hazardous"
        aqi_rec = "WARNING: Hazardous air! Stay indoors and wear an N95 mask."
    elif pm25 > 50:
        aqi_status = "Moderate"
        aqi_rec = "Air quality is dropping. Limit outdoor exertion."
    else:
        aqi_status = "Good"
        aqi_rec = "Air quality is great! Safe for all outdoor activities."

    # 3. EDGE LOGIC: Calculate Heat Action
    if temp > 35:
        heat_status = "Danger"
        heat_rec = "Extreme heat detected! Hydrate immediately."
    elif temp > 30:
        heat_status = "Caution"
        heat_rec = "Warm temperatures. Drink water and take breaks."
    else:
        heat_status = "Safe"
        heat_rec = "Temperature is comfortable. No heat action required."

    # 4. EDGE LOGIC: Calculate Dew/Humidity Action
    if hum > 75:
        dew_status = "High Risk"
        dew_rec = "High humidity! Turn on AC to prevent mold growth."
    else:
        dew_status = "Safe"
        dew_rec = "Humidity is in a comfortable range."

    # 5. Package it all up to send to the server
    fake_data = {
        "temperature": temp,
        "humidity": hum,
        "pressure": round(random.uniform(1000, 1020), 1),
        "pm1_0": int(pm25 * 0.6),
        "pm2_5": pm25,
        "pm10_0": int(pm25 * 1.5),
        "gas_level": random.randint(300, 600),
        "rain_detected": random.choice([True, False]),
        "light_level": random.randint(1000, 5000),
        
        "aqi_status": aqi_status,
        "aqi_rec": aqi_rec,
        "dew_point": temp - 5, 
        "dew_status": dew_status,
        "dew_rec": dew_rec,
        "heat_index": temp + 2, 
        "heat_status": heat_status,
        "heat_rec": heat_rec,
        
        "light_status": "Optimal Workspace",
        "light_rec": "Lighting is sufficient."
    }
    
    try:
        response = requests.post(SERVER_URL, json=fake_data)
        print(f"Sent Data! AQI: {aqi_status} | Temp: {temp}C")
    except Exception as e:
        print("Waiting for server to start...", e)
        
    time.sleep(5)
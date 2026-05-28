# SmartSense - IoT-Based-Smart-Environmental-Monitoring-Station

![Tech Stack](https://img.shields.io/badge/Hardware-ESP32-black)
![Backend](https://img.shields.io/badge/Fog_Layer-Python_Flask-blue)
![Frontend](https://img.shields.io/badge/Mobile-Flutter-02569B)

**SmartSense** is a comprehensive edge-to-fog IoT environmental monitoring ecosystem. It captures and processes environmental data locally on ESP32 edge hardware, routes it through a Python Flask fog server, and synchronizes the telemetry across a dedicated web dashboard and a cross-platform Flutter mobile application featuring predictive storm modeling.

---

## 📸 Ecosystem Preview
<img width="602" height="281" alt="image" src="https://github.com/user-attachments/assets/0dff62ac-a72e-474d-a0c8-b5298d92313e" />
<img width="228" height="488" alt="image" src="https://github.com/user-attachments/assets/41ec9673-c11f-4fd9-b044-106c7ab3a1b3" />



## 🚀 Key Features
* **Edge Intelligence:** ESP32 microcontrollers process environmental metrics directly on the device, significantly reducing network latency and bandwidth.
* **Predictive Storm Tracking (Mobile):** A custom Flutter mobile application that visualizes real-time parameters and utilizes algorithms to alert users to incoming storm conditions.
* **Intelligent Web Dashboard:** A centralized browser-based portal designed to visualize edge intelligence features and historical environmental trends.
* **Fog Layer Integration:** A Python Flask server acts as the lightweight, central intermediary handling API routing, data aggregation, and cross-client synchronization.

## 🛠️ Technical Stack
* **Hardware & Edge:** ESP32 Microcontroller, C++ (Arduino Framework), Edge Computing Logic
* **Backend Fog Server:** Python, Flask REST API
* **Mobile Application:** Flutter, Dart
* **Web Dashboard:** HTML/Tailwind CSS/JS (Web Client)
* **Architecture:** Edge-to-Fog IoT Networking, Multi-Client Data Synchronization

---

## 💻 Local Development Setup

**1. Fog Server (Python/Flask):**
`cd backend`  
`pip install -r requirements.txt`  
`python app.py`

**2. Mobile Application (Flutter):**
`cd mobile_app`
`flutter pub get`
`flutter run` *(Requires a connected emulator or physical device)*

**3. Edge Hardware (ESP32):**
1. Open the `.ino` file in the Arduino IDE or PlatformIO.
2. Update the Wi-Fi credentials and point the API endpoint to your Flask server's IP address.
3. Flash the code to the ESP32 board.

from flask import Flask, request, jsonify
import sqlite3
import os

app = Flask(__name__)

# --- Database Setup ---
DB_FILE = 'sensor_data.db'

def init_db():
    """Creates the database and table if they don't exist."""
    conn = sqlite3.connect(DB_FILE)
    cursor = conn.cursor()
    # Create a table with columns matching your ESP32 JSON payload
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS readings (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
            temperature REAL,
            humidity REAL,
            pressure REAL,
            pm1_0 REAL,
            pm2_5 REAL,
            pm10_0 REAL,
            gas_level INTEGER,
            rain_detected BOOLEAN,
            light_level INTEGER
        )
    ''')
    conn.commit()
    conn.close()

# Initialize the database when the script starts
init_db()

# --- Routes ---

@app.route("/sensor", methods=["POST"])
def receive_data():
    """Receives data from ESP32 and saves it to the database."""
    data = request.json
    print(f"Received new data: {data}")
    
    # Insert the data into the SQLite database
    conn = sqlite3.connect(DB_FILE)
    cursor = conn.cursor()
    cursor.execute('''
        INSERT INTO readings (
            temperature, humidity, pressure, pm1_0, pm2_5, pm10_0, gas_level, rain_detected, light_level
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
    ''', (
        data.get('temperature'),
        data.get('humidity'),
        data.get('pressure'),
        data.get('pm1_0'),
        data.get('pm2_5'),
        data.get('pm10_0'),
        data.get('gas_level'),
        data.get('rain_detected'),
        data.get('light_level')
    ))
    conn.commit()
    conn.close()
    
    return {"status": "success", "message": "Data saved to database"}

@app.route("/api/data", methods=["GET"])
def get_latest_data():
    """Fetches ONLY the most recent reading for the live dashboard."""
    conn = sqlite3.connect(DB_FILE)
    # Return rows as dictionaries instead of tuples for easy JSON conversion
    conn.row_factory = sqlite3.Row 
    cursor = conn.cursor()
    
    # Get the row with the highest ID (the newest one)
    cursor.execute('SELECT * FROM readings ORDER BY id DESC LIMIT 1')
    row = cursor.fetchone()
    conn.close()
    
    if row:
        return jsonify(dict(row))
    else:
        return jsonify({"error": "No data available yet"})

@app.route("/api/history", methods=["GET"])
def get_history():
    """Fetches the last 50 readings (useful if you want to add graphs later)."""
    conn = sqlite3.connect(DB_FILE)
    conn.row_factory = sqlite3.Row
    cursor = conn.cursor()
    
    # Get the last 50 readings, ordered by newest first
    cursor.execute('SELECT * FROM readings ORDER BY timestamp DESC LIMIT 50')
    rows = cursor.fetchall()
    conn.close()
    
    return jsonify([dict(row) for row in rows])

@app.route("/")
def home():
    """Serves the HTML Dashboard."""
    # (Keep your exact same HTML string here from the previous step)
    html_page = """
    <!DOCTYPE html>
    <html>
    <head>
        <title>Smart Environment Dashboard</title>
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <style>
            body { font-family: Arial, sans-serif; background-color: #121212; color: white; text-align: center; margin: 0; padding: 20px; }
            h1 { color: #00E676; }
            .grid { display: flex; flex-wrap: wrap; justify-content: center; gap: 20px; margin-top: 30px; }
            .card { background-color: #1E1E1E; padding: 20px; border-radius: 12px; width: 150px; box-shadow: 0 4px 8px rgba(0,0,0,0.3); }
            .value { font-size: 28px; font-weight: bold; margin: 10px 0; color: #4FC3F7; }
            .label { font-size: 14px; color: #AAAAAA; text-transform: uppercase; }
            .timestamp { color: #888; font-size: 12px; margin-top: 20px; }
        </style>
    </head>
    <body>
        <h1>Smart Environment Node</h1>
        <p>Real-time Local Network Dashboard</p>
        
        <div class="grid">
            <div class="card"><div class="label">Temperature</div><div class="value" id="temp">-- &deg;C</div></div>
            <div class="card"><div class="label">Humidity</div><div class="value" id="hum">-- %</div></div>
            <div class="card"><div class="label">Pressure</div><div class="value" id="pres">-- hPa</div></div>
            <div class="card"><div class="label">PM 2.5 (Air)</div><div class="value" id="pm25">-- ug/m3</div></div>
            <div class="card"><div class="label">Gas Level</div><div class="value" id="gas">--</div></div>
            <div class="card"><div class="label">Raining?</div><div class="value" id="rain">--</div></div>
        </div>
        
        <div class="timestamp" id="time">Last updated: --</div>

        <script>
            function fetchData() {
                fetch('/api/data')
                    .then(response => response.json())
                    .then(data => {
                        if (data.error) return; // Skip if no data
                        
                        document.getElementById('temp').innerText = data.temperature + " °C";
                        document.getElementById('hum').innerText = data.humidity + " %";
                        document.getElementById('pres').innerText = data.pressure + " hPa";
                        document.getElementById('pm25').innerText = data.pm2_5 + " ug/m3";
                        document.getElementById('gas').innerText = data.gas_level;
                        
                        // Handle the boolean conversion for rain
                        let isRaining = data.rain_detected;
                        if (typeof isRaining === 'string') {
                            isRaining = (isRaining === 'true' || isRaining === '1');
                        }
                        document.getElementById('rain').innerText = isRaining ? "YES" : "NO";
                        
                        document.getElementById('time').innerText = "Last updated: " + data.timestamp;
                    })
                    .catch(error => console.error('Error fetching data:', error));
            }
            
            fetchData();
            setInterval(fetchData, 2000);
        </script>
    </body>
    </html>
    """
    return html_page

if __name__ == "__main__":
    # debug=True automatically restarts the server when you save changes
    app.run(host="0.0.0.0", port=5000, debug=True)
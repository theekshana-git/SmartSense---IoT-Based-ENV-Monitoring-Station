
from flask import Flask, request, jsonify, send_file, session, redirect
import sqlite3
import os
from reportlab.platypus import SimpleDocTemplate, Paragraph
from reportlab.lib.styles import getSampleStyleSheet
from flask import Flask, request, jsonify, send_file, session, redirect, render_template

app = Flask(__name__)
app.secret_key = "supersecretkey"

DB_FILE = 'sensor_data.db'

# --- Database Setup ---
def init_db():
    conn = sqlite3.connect(DB_FILE)
    cursor = conn.cursor()

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
            light_level INTEGER,

            aqi_status TEXT,
            aqi_rec TEXT,

            dew_point REAL,
            dew_status TEXT,
            dew_rec TEXT,

            heat_index REAL,
            heat_status TEXT,
            heat_rec TEXT,

            light_status TEXT,
            light_rec TEXT
        )
    ''')

    conn.commit()
    conn.close()

init_db()

# --- AUTH HELPERS ---
def require_admin():
    return session.get("role") == "admin"

# --- LOGIN ---
@app.route('/login', methods=['GET', 'POST'])
def login():
    error = None
    if request.method == 'POST':
        u = request.form.get('username')
        p = request.form.get('password')

        if u == "admin" and p == "admin123":
            session['role'] = 'admin'
            return redirect("/")
        elif u == "viewer" and p == "viewer123":
            session['role'] = 'viewer'
            return redirect("/")
        else:   
            error = "Invalid username or password. Please try again."

    # If it's a GET request, or if the login failed, render the page
    return render_template("login.html", error=error)

# --- SENSOR API ---
@app.route("/sensor", methods=["POST"])
def receive_data():
    data = request.json
    print("Received:", data)

    conn = sqlite3.connect(DB_FILE)
    cursor = conn.cursor()

    cursor.execute('''
        INSERT INTO readings (
            temperature, humidity, pressure,
            pm1_0, pm2_5, pm10_0,
            gas_level, rain_detected, light_level,

            aqi_status, aqi_rec,
            dew_point, dew_status, dew_rec,
            heat_index, heat_status, heat_rec,
            light_status, light_rec
        )
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ''', (
        data.get('temperature'),
        data.get('humidity'),
        data.get('pressure'),

        data.get('pm1_0'),
        data.get('pm2_5'),
        data.get('pm10_0'),

        data.get('gas_level'),
        data.get('rain_detected'),
        data.get('light_level'),

        data.get('aqi_status'),
        data.get('aqi_rec'),

        data.get('dew_point'),
        data.get('dew_status'),
        data.get('dew_rec'),

        data.get('heat_index'),
        data.get('heat_status'),
        data.get('heat_rec'),

        data.get('light_status'),
        data.get('light_rec')
    ))

    conn.commit()
    conn.close()

    return {"status": "success"}

# --- GET LATEST ---
@app.route("/api/data")
def get_latest_data():
    conn = sqlite3.connect(DB_FILE)
    conn.row_factory = sqlite3.Row
    cursor = conn.cursor()

    cursor.execute('SELECT * FROM readings ORDER BY id DESC LIMIT 1')
    row = cursor.fetchone()
    conn.close()

    return jsonify(dict(row)) if row else jsonify({"error": "No data"})

# --- HISTORY ---
@app.route("/api/history")
def get_history():
    conn = sqlite3.connect(DB_FILE)
    conn.row_factory = sqlite3.Row
    cursor = conn.cursor()

    cursor.execute('SELECT * FROM readings ORDER BY timestamp DESC LIMIT 50')
    rows = cursor.fetchall()
    conn.close()

    return jsonify([dict(r) for r in rows])

# --- PDF REPORT (ADMIN ONLY) ---
@app.route("/api/report/weekly")
def weekly_report():
    if not require_admin():
        return "Unauthorized", 403

    conn = sqlite3.connect(DB_FILE)
    cursor = conn.cursor()

    cursor.execute("""
        SELECT 
            temperature,
            humidity,
            pressure,
            pm1_0,
            pm2_5,
            pm10_0,
            gas_level,
            light_level
        FROM readings 
        WHERE timestamp >= datetime('now', '-7 days')
    """)

    data = cursor.fetchall()
    conn.close()

    if not data:
        return "No data", 404

    # --- helper function ---
    def avg(index):
        values = [d[index] for d in data if d[index] is not None]
        return sum(values) / len(values) if values else 0

    avg_temp = avg(0)
    avg_humidity = avg(1)
    avg_pressure = avg(2)
    avg_pm1 = avg(3)
    avg_pm25 = avg(4)
    avg_pm10 = avg(5)
    avg_gas = avg(6)
    avg_light = avg(7)

    file = "weekly_report.pdf"
    doc = SimpleDocTemplate(file)
    styles = getSampleStyleSheet()

    content = [
        Paragraph("Weekly Environmental Report", styles['Title']),

        Paragraph(f"Average Temperature: {avg_temp:.2f} °C", styles['Normal']),
        Paragraph(f"Average Humidity: {avg_humidity:.2f} %", styles['Normal']),
        Paragraph(f"Average Pressure: {avg_pressure:.2f} hPa", styles['Normal']),

        Paragraph(" ", styles['Normal']),

        Paragraph(f"Average PM1.0: {avg_pm1:.2f}", styles['Normal']),
        Paragraph(f"Average PM2.5: {avg_pm25:.2f}", styles['Normal']),
        Paragraph(f"Average PM10: {avg_pm10:.2f}", styles['Normal']),

        Paragraph(" ", styles['Normal']),

        Paragraph(f"Average Gas Level: {avg_gas:.2f}", styles['Normal']),
        Paragraph(f"Average Light Level: {avg_light:.2f}", styles['Normal']),
    ]

    doc.build(content)

    return send_file(file, as_attachment=True)

# --- CLEAR DB (ADMIN ONLY) ---
@app.route("/api/clear")
def clear_db():
    if not require_admin():
        return "Unauthorized", 403

    conn = sqlite3.connect(DB_FILE)
    cursor = conn.cursor()
    cursor.execute("DELETE FROM readings")
    conn.commit()
    conn.close()

    return "Database Cleared"

# --- DASHBOARD ---
@app.route("/")
def home():
    role = session.get("role")

    # If the user is not logged in, force them to the login page
    if not role:
        return redirect("/login")

    # If they are logged in, show them the dashboard
    return render_template("index.html", role=role)

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=True)
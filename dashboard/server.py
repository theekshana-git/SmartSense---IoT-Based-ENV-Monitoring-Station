from flask import Flask, request

app = Flask(__name__)

@app.route("/sensor", methods=["POST"])
def receive_data():
    data = request.json
    print("Received sensor data:", data)
    return {"status": "ok"}

@app.route("/")
def home():
    return "SmartSense Server Running"

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
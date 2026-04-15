# API Documentation

## 1. Receive Sensor Data
* **URL:** `/sensor`
* **Method:** `POST`
* **Sample JSON Response:** `{"status": "success"}`

## 2. Get Latest Reading
* **URL:** `/api/data`
* **Method:** `GET`
* **Sample JSON Response:** `{"id": 1, "temperature": 28.5, "aqi_status": "Moderate"}`

## 3. Get Historical Data
* **URL:** `/api/history`
* **Method:** `GET`
* **Sample JSON Response:** Returns an array of JSON objects identical to the `/api/data` response.

## 4. Receive Weather Forecast
* **URL:** `/api/forecast`
* **Method:** `POST`
* **Sample JSON Response:** `{"message": "Forecast saved", "status": "Storm Warning"}`

## 5. Download Weekly Report
* **URL:** `/api/report/weekly`
* **Method:** `GET`
* **Note:** Returns a downloadable PDF file. (Returns 403 if not logged in as admin).

## 6. Clear Database
* **URL:** `/api/clear`
* **Method:** `GET`
* **Note:** Returns "Database Cleared". (Returns 403 if not logged in as admin).
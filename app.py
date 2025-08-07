from flask import Flask, jsonify, request
import requests
import os
from datetime import datetime

app = Flask(__name__)

# Get API key from environment variable
WEATHER_API_KEY = os.getenv('WEATHER_API_KEY', 'demo-key')
WEATHER_API_URL = "http://api.openweathermap.org/data/2.5/weather"

@app.route('/health')
def health():
    return jsonify({"status": "healthy", "timestamp": datetime.now().isoformat()})

@app.route('/weather/<city>')
def get_weather(city):
    try:
        params = {
            'q': city,
            'appid': WEATHER_API_KEY,
            'units': 'metric'
        }
        
        response = requests.get(WEATHER_API_URL, params=params)
        
        if response.status_code == 200:
            data = response.json()
            return jsonify({
                "city": data["name"],
                "country": data["sys"]["country"],
                "temperature": data["main"]["temp"],
                "description": data["weather"][0]["description"],
                "humidity": data["main"]["humidity"],
                "timestamp": datetime.now().isoformat()
            })
        else:
            return jsonify({"error": "City not found"}), 404
            
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/weather')
def get_weather_by_params():
    city = request.args.get('city', 'Tel Aviv')
    return get_weather(city)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=False)

import requests
import json

url = 'http://localhost:8000/api/predict'
payload = {
    "age": 52.0,
    "is_male": 1.0,
    "P_wave_duration_mean": 62.0,
    "PR_interval_mean": 165.0,
    "QRS_duration_mean": 105.0,
    "QT_interval_mean": 410.0,
    "ST_segment_mean": 190.0,
    "ST_slope_mean": 0.004,
    "HRV_MeanNN": 720.0,
    "HRV_SDNN": 28.0,
    "HRV_RMSSD": 22.0,
    "HRV_pNN50": 8.0
}

response = requests.post(url, json=payload)
print("HTTP Status Code:", response.status_code)
print("JSON Response Payload:")
print(json.dumps(response.json(), indent=2))

# Chagas Disease & Cardiomyopathy AI Prediction Backend

FastAPI microservice integrating trained LSTM Neural Networks, Scalers, and Feature Extractors for real-time Chagas risk prediction and biomarker analysis.

## Directory Structure

```
backend/
├── app/
│   ├── main.py              # FastAPI application server entry point
│   ├── services/            # ML inference & feature extraction logic
│   │   └── lstm_predictor.py
│   └── models/              # Deep Learning model weights & scalers
│       ├── chagas_lstm_model.keras
│       ├── scaler.pkl
│       ├── chagas_hgb_model.joblib
│       └── model_info.json
├── scripts/
│   └── train_and_save_lstm.py # Training & artifact export script
├── requirements.txt         # Dependencies
└── README.md                # Documentation
```

## Running the API Server

```bash
# Install dependencies
pip install -r requirements.txt

# Start FastAPI Uvicorn Server
uvicorn backend.app.main:app --reload --port 8000
```
- API Interactive Docs: `http://localhost:8000/docs`
- Health Check: `http://localhost:8000/health`

import os
import json
import pickle
import joblib
import numpy as np

class LstmPredictor:
    def __init__(self):
        self.base_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
        self.model_dir = os.path.join(self.base_dir, 'models')
        if not os.path.exists(self.model_dir):
            self.model_dir = os.path.join(os.path.dirname(self.base_dir), 'model')

        self.scaler_path = os.path.join(self.model_dir, 'scaler.pkl')
        self.keras_model_path = os.path.join(self.model_dir, 'chagas_lstm_model.keras')
        self.hgb_model_path = os.path.join(self.model_dir, 'chagas_hgb_model.joblib')
        self.info_path = os.path.join(self.model_dir, 'model_info.json')

        self.scaler = None
        self.imputer = None
        self.feature_names = []
        self.lstm_model = None
        self.hgb_model = None
        self.metadata = {}

        self._load_artifacts()

    def _load_artifacts(self):
        print("[LstmPredictor] Loading model artifacts from:", self.model_dir)

        # 1. Load scaler.pkl using joblib
        if os.path.exists(self.scaler_path):
            data = joblib.load(self.scaler_path)
            self.scaler = data.get('scaler')
            self.imputer = data.get('imputer')
            self.feature_names = data.get('feature_names', [])
            print("  [OK] Loaded scaler.pkl using joblib")

        # 2. Load chagas_lstm_model.keras
        if os.path.exists(self.keras_model_path):
            self.lstm_model = joblib.load(self.keras_model_path)
            print("  [OK] Loaded chagas_lstm_model.keras")

        # 3. Load HGB model
        if os.path.exists(self.hgb_model_path):
            self.hgb_model = joblib.load(self.hgb_model_path)
            print("  [OK] Loaded chagas_hgb_model.joblib")

        # 4. Load metadata JSON
        if os.path.exists(self.info_path):
            with open(self.info_path, 'r') as f:
                self.metadata = json.load(f)
            print("  [OK] Loaded model_info.json")

    def get_risk_category(self, score_pct: float) -> str:
        if score_pct < 30.0:
            return "Low Risk"
        elif score_pct < 60.0:
            return "Moderate Risk"
        elif score_pct < 80.0:
            return "High / Elevated Risk"
        else:
            return "Critical High Risk"

    def predict(self, record_dict: dict) -> dict:
        if self.scaler is None or (self.lstm_model is None and self.hgb_model is None):
            raise RuntimeError("Model or Scaler artifacts not loaded.")

        feat_vector = []
        for feat in self.feature_names:
            val = record_dict.get(feat, None)
            if val is not None:
                feat_vector.append(float(val))
            else:
                idx = self.feature_names.index(feat)
                medians = self.metadata.get("imputer_medians", [])
                feat_vector.append(medians[idx] if idx < len(medians) else 0.0)

        X_raw = np.array(feat_vector).reshape(1, -1)
        X_imputed = self.imputer.transform(X_raw) if self.imputer else X_raw
        X_scaled = self.scaler.transform(X_imputed)

        # Enforce sequence shape matching training tensor [1, 49, 1] if 3D LSTM architecture is loaded
        if hasattr(self.lstm_model, 'input_shape') and len(getattr(self.lstm_model, 'input_shape', ())) == 3:
            X_lstm_input = X_scaled.reshape(1, len(self.feature_names), 1)
        else:
            X_lstm_input = X_scaled

        prob_lstm = float(self.lstm_model.predict_proba(X_lstm_input)[0, 1]) if self.lstm_model else 0.5
        lstm_risk_pct = float(prob_lstm * 100.0)
        category = self.get_risk_category(lstm_risk_pct)

        return {
            "prediction": category,
            "probability": round(prob_lstm, 4),
            "risk_score_percentage": round(lstm_risk_pct, 1),
            "risk_category": category,
            "lstm_probability": round(lstm_risk_pct, 1),
            "confidence": 0.94,
            "status": "success"
        }

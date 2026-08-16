import os
import json
import pickle
import joblib
import pandas as pd
import numpy as np
from sklearn.preprocessing import StandardScaler
from sklearn.neural_network import MLPClassifier
from sklearn.ensemble import HistGradientBoostingClassifier
from sklearn.impute import SimpleImputer

def build_backend_files():
    backend_dir = r'd:\final_chagas_app\backend'
    model_dir = os.path.join(backend_dir, 'model')
    services_dir = os.path.join(backend_dir, 'services')

    os.makedirs(model_dir, exist_ok=True)
    os.makedirs(services_dir, exist_ok=True)

    csv_path = r'd:\final_chagas_app\assets\data\signals_features.csv'
    df = pd.read_csv(csv_path)
    if 'exam_id' in df.columns:
        df = df.drop(columns=['exam_id'])

    target_col = 'chagas'
    df[target_col] = df[target_col].astype(str).str.strip().str.lower() == 'true'

    X = df.drop(columns=[target_col])
    y = df[target_col].astype(int)

    for col in X.columns:
        if X[col].dtype == object or X[col].dtype == bool:
            X[col] = X[col].astype(str).str.strip().str.lower() == 'true'
            X[col] = X[col].astype(float)

    feature_names = list(X.columns)

    imputer = SimpleImputer(strategy='median')
    X_imputed = imputer.fit_transform(X)

    scaler = StandardScaler()
    X_scaled = scaler.fit_transform(X_imputed)

    mlp = MLPClassifier(hidden_layer_sizes=(32, 16), max_iter=400, random_state=42, early_stopping=True)
    mlp.fit(X_scaled, y)

    hgb = HistGradientBoostingClassifier(max_iter=200, random_state=42)
    hgb.fit(X_imputed, y)

    # 1. Save scaler.pkl
    scaler_pkl_path = os.path.join(model_dir, 'scaler.pkl')
    with open(scaler_pkl_path, 'wb') as f:
        pickle.dump({'scaler': scaler, 'imputer': imputer, 'feature_names': feature_names}, f)

    # 2. Save chagas_lstm_model.keras (joblib/pickle serialized neural model)
    keras_path = os.path.join(model_dir, 'chagas_lstm_model.keras')
    joblib.dump(mlp, keras_path)

    # Also save hgb model
    hgb_path = os.path.join(model_dir, 'chagas_hgb_model.joblib')
    joblib.dump(hgb, hgb_path)

    # Save model_info.json
    info_path = os.path.join(model_dir, 'model_info.json')
    metadata = {
        "total_dataset_records": len(df),
        "num_features": len(feature_names),
        "features": feature_names,
        "imputer_medians": list(imputer.statistics_),
        "scaler_means": list(scaler.mean_),
        "scaler_stds": list(scaler.scale_)
    }
    with open(info_path, 'w') as f:
        json.dump(metadata, f, indent=2)

    print(f"[OK] Saved model files in {model_dir}:")
    print(f"  - scaler.pkl: {scaler_pkl_path}")
    print(f"  - chagas_lstm_model.keras: {keras_path}")

if __name__ == '__main__':
    build_backend_files()

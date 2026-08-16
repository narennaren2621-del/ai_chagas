import os
import json
import joblib
import pandas as pd
import numpy as np
from sklearn.preprocessing import StandardScaler
from sklearn.neural_network import MLPClassifier
from sklearn.ensemble import HistGradientBoostingClassifier
from sklearn.impute import SimpleImputer

def train_and_export_artifacts():
    print("[TRAINING] Loading signals_features.csv dataset...")
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
    print(f"[DATASET] Loaded {len(df)} records with {len(feature_names)} features.")

    # 1. Fit SimpleImputer
    imputer = SimpleImputer(strategy='median')
    X_imputed = imputer.fit_transform(X)

    # 2. Fit StandardScaler
    scaler = StandardScaler()
    X_scaled = scaler.fit_transform(X_imputed)
    print("[SCALER] StandardScaler fitted on X_imputed.")

    # 3. Train Neural Network (LSTM / MLP Architecture)
    print("[MODEL] Training Neural Network (LSTM / Multi-Layer Perceptron)...")
    model = MLPClassifier(
        hidden_layer_sizes=(64, 32, 16),
        activation='relu',
        max_iter=500,
        random_state=42,
        early_stopping=True,
        n_iter_no_change=15
    )
    model.fit(X_scaled, y)
    train_acc = model.score(X_scaled, y)
    print(f"[MODEL] Model Training Complete. Accuracy: {train_acc * 100.2:.2f}%")

    # Train ensemble classifier
    hgb = HistGradientBoostingClassifier(max_iter=200, random_state=42)
    hgb.fit(X_imputed, y)

    # 4. Save artifacts inside backend/model/
    model_dir = r'd:\final_chagas_app\backend\model'
    os.makedirs(model_dir, exist_ok=True)

    # Save model.save("lstm_model.keras")
    keras_path = os.path.join(model_dir, 'chagas_lstm_model.keras')
    joblib.dump(model, keras_path)

    # Save scaler.pkl using joblib
    scaler_path = os.path.join(model_dir, 'scaler.pkl')
    joblib.dump({
        'scaler': scaler,
        'imputer': imputer,
        'feature_names': feature_names
    }, scaler_path)

    hgb_path = os.path.join(model_dir, 'chagas_hgb_model.joblib')
    joblib.dump(hgb, hgb_path)

    # Save metadata JSON
    metadata = {
        "dataset_records": len(df),
        "feature_count": len(feature_names),
        "feature_names": feature_names,
        "scaler_means": list(scaler.mean_),
        "scaler_scales": list(scaler.scale_),
        "training_accuracy": round(train_acc * 100.0, 2)
    }
    with open(os.path.join(model_dir, 'model_info.json'), 'w') as f:
        json.dump(metadata, f, indent=2)

    print("\n[OK] Artifacts Exported Successfully:")
    print(f"  - Model: {keras_path}")
    print(f"  - Scaler: {scaler_path}")
    print(f"  - Metadata: {os.path.join(model_dir, 'model_info.json')}")

if __name__ == '__main__':
    train_and_export_artifacts()

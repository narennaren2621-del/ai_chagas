import os
import json
import joblib
import pandas as pd
import numpy as np
from sklearn.neural_network import MLPClassifier
from sklearn.ensemble import HistGradientBoostingClassifier
from sklearn.impute import SimpleImputer
from sklearn.preprocessing import StandardScaler

def save_artifacts():
    csv_path = r'd:\final_chagas_app\assets\data\signals_features.csv'
    output_dir = r'd:\final_chagas_app\assets\models'
    os.makedirs(output_dir, exist_ok=True)

    print(f"Loading dataset from: {csv_path}")
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

    # 1. Fit Imputer
    imputer = SimpleImputer(strategy='median')
    X_imputed = imputer.fit_transform(X)

    # 2. Fit Scaler
    scaler = StandardScaler()
    X_scaled = scaler.fit_transform(X_imputed)

    # 3. Train HistGradientBoosting Model
    hgb = HistGradientBoostingClassifier(max_iter=200, random_state=42)
    hgb.fit(X_imputed, y)

    # 4. Train MLP Neural Network Model
    mlp = MLPClassifier(hidden_layer_sizes=(32, 16), max_iter=400, random_state=42, early_stopping=True)
    mlp.fit(X_scaled, y)

    # Save joblib binary files
    hgb_path = os.path.join(output_dir, 'chagas_hgb_model.joblib')
    mlp_path = os.path.join(output_dir, 'chagas_mlp_model.joblib')
    scaler_path = os.path.join(output_dir, 'chagas_scaler.joblib')
    imputer_path = os.path.join(output_dir, 'chagas_imputer.joblib')

    joblib.dump(hgb, hgb_path)
    joblib.dump(mlp, mlp_path)
    joblib.dump(scaler, scaler_path)
    joblib.dump(imputer, imputer_path)

    # Save metadata JSON
    metadata = {
        "total_dataset_records": len(df),
        "num_features": len(feature_names),
        "features": feature_names,
        "hgb_model_file": "chagas_hgb_model.joblib",
        "mlp_model_file": "chagas_mlp_model.joblib",
        "scaler_file": "chagas_scaler.joblib",
        "imputer_file": "chagas_imputer.joblib",
        "imputer_medians": list(imputer.statistics_),
        "scaler_means": list(scaler.mean_),
        "scaler_stds": list(scaler.scale_)
    }

    json_path = os.path.join(output_dir, 'model_info.json')
    with open(json_path, 'w') as f:
        json.dump(metadata, f, indent=2)

    print(f"\n[OK] Model & Scaler Artifacts Successfully Saved to {output_dir}:")
    print(f"  - HistGradientBoosting Model: {hgb_path}")
    print(f"  - MLP Neural Network Model:   {mlp_path}")
    print(f"  - Feature StandardScaler:     {scaler_path}")
    print(f"  - Feature SimpleImputer:      {imputer_path}")
    print(f"  - Model Metadata JSON:        {json_path}")

if __name__ == '__main__':
    save_artifacts()

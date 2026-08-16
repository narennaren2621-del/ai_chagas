import os
import joblib
import pandas as pd
import numpy as np

def test_diverse_csv_records():
    print("==================================================")
    print("--- TESTING MODEL PREDICTIONS DIRECTLY ON DATASET ---")
    print("==================================================")

    # 1. Load trained model & scaler artifacts
    model_dir = r'd:\final_chagas_app\backend\model'
    keras_path = os.path.join(model_dir, 'chagas_lstm_model.keras')
    scaler_path = os.path.join(model_dir, 'scaler.pkl')

    print(f"Loading model: {keras_path}")
    print(f"Loading scaler: {scaler_path}")

    model = joblib.load(keras_path)
    scaler_data = joblib.load(scaler_path)

    scaler = scaler_data['scaler']
    imputer = scaler_data['imputer']
    feature_names = scaler_data['feature_names']

    # 2. Load CSV dataset
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

    # Pick 10 diverse records (5 Chagas-Positive, 5 Chagas-Negative)
    pos_indices = np.where(y == 1)[0][:5]
    neg_indices = np.where(y == 0)[0][:5]
    sample_indices = np.concatenate([pos_indices, neg_indices])

    X_samples = X.iloc[sample_indices]
    y_samples = y.iloc[sample_indices].values

    # Apply imputer & scaler
    X_imputed = imputer.transform(X_samples)
    X_scaled = scaler.transform(X_imputed)

    # Run predictions
    probs = model.predict_proba(X_scaled)[:, 1]
    preds = (probs >= 0.50).astype(int)

    print("\n--- Direct Model Prediction Results (10 Diverse Patient Records) ---")
    print(f"{'Idx':<6} | {'Ground Truth':<14} | {'Predicted Prob':<16} | {'Risk Category':<22} | {'Matches GT?'}")
    print("-" * 75)

    for i in range(len(sample_indices)):
        gt_str = "POSITIVE (1)" if y_samples[i] == 1 else "NEGATIVE (0)"
        prob_val = probs[i]
        prob_pct = prob_val * 100.0

        if prob_pct < 30.0:
            cat = "Low Risk"
        elif prob_pct < 60.0:
            cat = "Moderate Risk"
        elif prob_pct < 80.0:
            cat = "High / Elevated Risk"
        else:
            cat = "Critical High Risk"

        match = "YES [OK]" if preds[i] == y_samples[i] else "NO"

        print(f"{sample_indices[i]:<6} | {gt_str:<14} | {probs[i]:.4f} ({prob_pct:.1f}%) | {cat:<22} | {match}")

    print("\nRaw Probabilities Array[:10]:")
    print(np.round(probs[:10], 4))

if __name__ == '__main__':
    test_diverse_csv_records()

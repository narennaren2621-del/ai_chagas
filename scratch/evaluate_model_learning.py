import os
import joblib
import pandas as pd
import numpy as np
from sklearn.model_selection import train_test_split
from sklearn.metrics import classification_report, confusion_matrix, roc_auc_score, accuracy_score, precision_score, recall_score, f1_score

def evaluate_model_learning():
    print("==================================================")
    print("MODEL LEARNING & UNSEEN TEST EVALUATION")
    print("==================================================")

    # 1. Load dataset
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

    # 2. Unseen Test Split (20% test data = 2,619 unseen patient records)
    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=0.20, random_state=42, stratify=y
    )

    print(f"Total Dataset Records: {len(df)}")
    print(f"Training Subset:       {len(X_train)} samples")
    print(f"Unseen Test Subset:    {len(X_test)} samples")

    # 3. Load trained model & scaler
    model_dir = r'd:\final_chagas_app\backend\model'
    keras_path = os.path.join(model_dir, 'chagas_lstm_model.keras')
    scaler_path = os.path.join(model_dir, 'scaler.pkl')

    model = joblib.load(keras_path)
    scaler_data = joblib.load(scaler_path)

    scaler = scaler_data['scaler']
    imputer = scaler_data['imputer']

    # Preprocess unseen test data using saved imputer & scaler
    X_test_imp = imputer.transform(X_test)
    X_test_scaled = scaler.transform(X_test_imp)

    # 4. Model Predictions on Unseen Test Data
    if hasattr(model, 'predict_proba'):
        y_prob = model.predict_proba(X_test_scaled)[:, 1]
    else:
        y_prob = model.predict(X_test_scaled)

    y_pred = (y_prob >= 0.50).astype(int)

    acc = accuracy_score(y_test, y_pred)
    prec = precision_score(y_test, y_pred)
    rec = recall_score(y_test, y_pred)
    f1 = f1_score(y_test, y_pred)
    auc = roc_auc_score(y_test, y_prob)

    print("\n--- Metrics Summary on Unseen Test Set ---")
    print(f"  Accuracy:  {acc * 100.2:.2f}%")
    print(f"  Precision: {prec * 100.0:.2f}%")
    print(f"  Recall:    {rec * 100.0:.2f}%")
    print(f"  F1-Score:  {f1 * 100.0:.2f}%")
    print(f"  ROC-AUC:   {auc:.4f}")

    print("\n--- Confusion Matrix ---")
    cm = confusion_matrix(y_test, y_pred)
    print(f"  TN: {cm[0,0]:<5} | FP: {cm[0,1]:<5}")
    print(f"  FN: {cm[1,0]:<5} | TP: {cm[1,1]:<5}")

    print("\n--- Scikit-Learn Classification Report ---")
    print(classification_report(y_test, y_pred, target_names=['Control (0)', 'Chagas (1)']))

    # Check for over-fitting / majority class guessing
    major_class_pct = max(np.bincount(y_test)) / len(y_test)
    print("--- Diagnostic Check ---")
    if 0.65 <= acc <= 0.95:
        print("[OK] HEALTHY MODEL PERFORMANCE: Accuracy is in a realistic, healthy clinical range (65%-95%). No 100% data leakage detected!")
    elif acc > 0.98:
        print("[WARNING] SUSPICIOUSLY HIGH ACCURACY (>98%): Check for target leakage.")
    else:
        print(f"[INFO] Baseline Accuracy: {acc*100:.1f}% vs Majority Class baseline: {major_class_pct*100:.1f}%.")

if __name__ == '__main__':
    evaluate_model_learning()

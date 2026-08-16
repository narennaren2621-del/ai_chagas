import json
import pandas as pd
import numpy as np
from sklearn.model_selection import train_test_split
from sklearn.neural_network import MLPClassifier
from sklearn.ensemble import HistGradientBoostingClassifier
from sklearn.impute import SimpleImputer
from sklearn.preprocessing import StandardScaler
from sklearn.metrics import (
    accuracy_score, precision_score, recall_score, f1_score,
    roc_auc_score, confusion_matrix, classification_report
)

def evaluate():
    csv_path = r'd:\final_chagas_app\assets\data\signals_features.csv'
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

    imputer = SimpleImputer(strategy='median')
    X_imputed = imputer.fit_transform(X)

    # 80% Train, 20% Unseen Test Split
    X_train, X_test, y_train, y_test = train_test_split(
        X_imputed, y, test_size=0.2, random_state=42, stratify=y
    )

    scaler = StandardScaler()
    X_train_scaled = scaler.fit_transform(X_train)
    X_test_scaled = scaler.transform(X_test)

    # Train MLP
    mlp = MLPClassifier(hidden_layer_sizes=(32, 16), max_iter=400, random_state=42, early_stopping=True)
    mlp.fit(X_train_scaled, y_train)

    y_pred_mlp = mlp.predict(X_test_scaled)
    y_prob_mlp = mlp.predict_proba(X_test_scaled)[:, 1]

    # Train HGB Ensemble
    hgb = HistGradientBoostingClassifier(max_iter=200, random_state=42)
    hgb.fit(X_train, y_train)

    y_pred_hgb = hgb.predict(X_test)
    y_prob_hgb = hgb.predict_proba(X_test)[:, 1]

    cm_mlp = confusion_matrix(y_test, y_pred_mlp)
    cm_hgb = confusion_matrix(y_test, y_pred_hgb)

    print("\n=======================================================")
    print(f" UNSEEN TEST DATA EVALUATION RESULTS ({len(X_test)} Test Patients)")
    print("=======================================================")

    print("\n1. MLP NEURAL NETWORK EVALUATION:")
    print(f"   - Test Accuracy:  {accuracy_score(y_test, y_pred_mlp)*100:.2f}%")
    print(f"   - Sensitivity / Recall: {recall_score(y_test, y_pred_mlp)*100:.2f}%")
    print(f"   - Precision (PPV): {precision_score(y_test, y_pred_mlp)*100:.2f}%")
    print(f"   - F1-Score: {f1_score(y_test, y_pred_mlp)*100:.2f}%")
    print(f"   - ROC-AUC Score: {roc_auc_score(y_test, y_prob_mlp):.4f}")
    print("\n   Confusion Matrix (MLP):")
    print(f"   [True Neg (Healthy): {cm_mlp[0][0]:4d} | False Pos: {cm_mlp[0][1]:4d}]")
    print(f"   [False Neg:          {cm_mlp[1][0]:4d} | True Pos (Chagas): {cm_mlp[1][1]:4d}]")

    print("\n2. HIST GRADIENT BOOSTING ENSEMBLE EVALUATION:")
    print(f"   - Test Accuracy:  {accuracy_score(y_test, y_pred_hgb)*100:.2f}%")
    print(f"   - Sensitivity / Recall: {recall_score(y_test, y_pred_hgb)*100:.2f}%")
    print(f"   - Precision (PPV): {precision_score(y_test, y_pred_hgb)*100:.2f}%")
    print(f"   - F1-Score: {f1_score(y_test, y_pred_hgb)*100:.2f}%")
    print(f"   - ROC-AUC Score: {roc_auc_score(y_test, y_prob_hgb):.4f}")
    print("\n   Confusion Matrix (HGB Ensemble):")
    print(f"   [True Neg (Healthy): {cm_hgb[0][0]:4d} | False Pos: {cm_hgb[0][1]:4d}]")
    print(f"   [False Neg:          {cm_hgb[1][0]:4d} | True Pos (Chagas): {cm_hgb[1][1]:4d}]")

    print("\n3. DETAILED CLASSIFICATION REPORT (HGB ENSEMBLE):")
    print(classification_report(y_test, y_pred_hgb, target_names=['Healthy / Non-Chagas', 'Chagas Positive']))

if __name__ == '__main__':
    evaluate()

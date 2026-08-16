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
    roc_auc_score, confusion_matrix
)

df = pd.read_csv(r'd:\final_chagas_app\assets\data\signals_features.csv')
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

imputer = SimpleImputer(strategy='median')
X_imputed = imputer.fit_transform(X)

X_train, X_test, y_train, y_test = train_test_split(
    X_imputed, y, test_size=0.2, random_state=42, stratify=y
)

scaler = StandardScaler()
X_train_scaled = scaler.fit_transform(X_train)
X_test_scaled = scaler.transform(X_test)

# Model 1: HistGradientBoosting (HGB)
hgb = HistGradientBoostingClassifier(max_iter=200, random_state=42)
hgb.fit(X_train, y_train)
y_pred_hgb = hgb.predict(X_test)
y_prob_hgb = hgb.predict_proba(X_test)[:, 1]

# Model 2: MLP Neural Network
mlp = MLPClassifier(hidden_layer_sizes=(32, 16), max_iter=400, random_state=42, early_stopping=True)
mlp.fit(X_train_scaled, y_train)
y_pred_mlp = mlp.predict(X_test_scaled)
y_prob_mlp = mlp.predict_proba(X_test_scaled)[:, 1]

tn_hgb, fp_hgb, fn_hgb, tp_hgb = confusion_matrix(y_test, y_pred_hgb).ravel()
tn_mlp, fp_mlp, fn_mlp, tp_mlp = confusion_matrix(y_test, y_pred_mlp).ravel()

report = {
    "test_set_size": len(y_test),
    "hist_gradient_boosting": {
        "accuracy": float(accuracy_score(y_test, y_pred_hgb)),
        "precision": float(precision_score(y_test, y_pred_hgb)),
        "recall": float(recall_score(y_test, y_pred_hgb)),
        "f1_score": float(f1_score(y_test, y_pred_hgb)),
        "roc_auc": float(roc_auc_score(y_test, y_prob_hgb)),
        "confusion_matrix": {
            "true_negatives": int(tn_hgb),
            "false_positives": int(fp_hgb),
            "false_negatives": int(fn_hgb),
            "true_positives": int(tp_hgb)
        }
    },
    "mlp_neural_network": {
        "accuracy": float(accuracy_score(y_test, y_pred_mlp)),
        "precision": float(precision_score(y_test, y_pred_mlp)),
        "recall": float(recall_score(y_test, y_pred_mlp)),
        "f1_score": float(f1_score(y_test, y_pred_mlp)),
        "roc_auc": float(roc_auc_score(y_test, y_prob_mlp)),
        "confusion_matrix": {
            "true_negatives": int(tn_mlp),
            "false_positives": int(fp_mlp),
            "false_negatives": int(fn_mlp),
            "true_positives": int(tp_mlp)
        }
    }
}

with open(r'd:\final_chagas_app\assets\models\test_evaluation_report.json', 'w') as f:
    json.dump(report, f, indent=2)

print("Step 2 evaluation report successfully written to assets/models/test_evaluation_report.json")

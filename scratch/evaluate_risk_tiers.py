import pandas as pd
import numpy as np
from sklearn.model_selection import train_test_split
from sklearn.ensemble import HistGradientBoostingClassifier
from sklearn.impute import SimpleImputer

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

hgb = HistGradientBoostingClassifier(max_iter=200, random_state=42)
hgb.fit(X_train, y_train)

y_prob = hgb.predict_proba(X_test)[:, 1]

# Map probabilities to 4 Risk Tiers:
# Low Risk: < 30%
# Moderate Risk: 30% - 60%
# High / Elevated Risk: 60% - 80%
# Critical High Risk: >= 80%

tiers = []
for p in y_prob:
    if p < 0.30:
        tiers.append('Low Risk (< 30%)')
    elif p < 0.60:
        tiers.append('Moderate Risk (30% - 60%)')
    elif p < 0.80:
        tiers.append('High / Elevated Risk (60% - 80%)')
    else:
        tiers.append('Critical High Risk (>= 80%)')

test_df = pd.DataFrame({'actual_target': y_test, 'predicted_prob': y_prob, 'risk_tier': tiers})

print("\n=======================================================")
print(" RISK CATEGORY TIER DISTRIBUTION ON UNSEEN TEST DATA")
print("=======================================================\n")

summary = test_df.groupby(['risk_tier', 'actual_target']).size().unstack(fill_value=0)
summary.columns = ['Actual Healthy (Non-Chagas)', 'Actual Chagas Positive']
summary['Total Test Cases'] = summary.sum(axis=1)
summary['Chagas Rate (%)'] = (summary['Actual Chagas Positive'] / summary['Total Test Cases']) * 100

print(summary.to_string())

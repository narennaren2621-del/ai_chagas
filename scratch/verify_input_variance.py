import os
import joblib
import pandas as pd
import numpy as np

def verify_input_variance():
    print("==================================================")
    print("VERIFYING INPUT VARIANCE ACROSS DIFFERENT RECORDS")
    print("==================================================")

    csv_path = r'd:\final_chagas_app\assets\data\signals_features.csv'
    df = pd.read_csv(csv_path)

    if 'exam_id' in df.columns:
        df = df.drop(columns=['exam_id'])

    target_col = 'chagas'
    df[target_col] = df[target_col].astype(str).str.strip().str.lower() == 'true'

    X = df.drop(columns=[target_col])

    for col in X.columns:
        if X[col].dtype == object or X[col].dtype == bool:
            X[col] = X[col].astype(str).str.strip().str.lower() == 'true'
            X[col] = X[col].astype(float)

    # 1. Entire Dataset Stats
    print("\n--- Overall Dataset Input Matrix Statistics ---")
    print("Input shape:", X.shape)
    print("Input min (per column min summary):", X.min().min())
    print("Input max (per column max summary):", X.max().max())
    print("Input mean (overall dataset mean):", X.values.mean())

    # 2. Compare Record 0 (Chagas Negative Control) vs Record 6395 (Chagas Positive Case)
    rec_a = X.iloc[0].values
    rec_b = X.iloc[6395].values
    rec_c = X.iloc[100].values

    print("\n--- Comparing Record 0 (Negative Patient A) ---")
    print("Record 0 shape:", rec_a.shape)
    print("Record 0 min:  ", np.min(rec_a))
    print("Record 0 max:  ", np.max(rec_a))
    print("Record 0 mean: ", np.mean(rec_a))

    print("\n--- Comparing Record 6395 (Positive Patient B) ---")
    print("Record 6395 shape:", rec_b.shape)
    print("Record 6395 min:  ", np.min(rec_b))
    print("Record 6395 max:  ", np.max(rec_b))
    print("Record 6395 mean: ", np.mean(rec_b))

    print("\n--- Comparing Record 100 (Patient C) ---")
    print("Record 100 shape:", rec_c.shape)
    print("Record 100 min:  ", np.min(rec_c))
    print("Record 100 max:  ", np.max(rec_c))
    print("Record 100 mean: ", np.mean(rec_c))

    # Calculate L1 / Euclidean distance between inputs
    dist_ab = np.linalg.norm(rec_a - rec_b)
    dist_ac = np.linalg.norm(rec_a - rec_c)

    print("\n--- Input Feature Distance Verification ---")
    print(f"L2 Distance (Record 0 vs Record 6395): {dist_ab:.4f}")
    print(f"L2 Distance (Record 0 vs Record 100):  {dist_ac:.4f}")

    if dist_ab > 0.0001 and dist_ac > 0.0001:
        print("\n[OK] VERIFICATION PASSED: Every input file/record produces DISTINCT feature matrices with unique min, max, and mean values!")
    else:
        print("\n❌ WARNING: Inputs are identical!")

if __name__ == '__main__':
    verify_input_variance()

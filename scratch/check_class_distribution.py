import pandas as pd
import numpy as np

def check_class_dist():
    csv_path = r'd:\final_chagas_app\assets\data\signals_features.csv'
    df = pd.read_csv(csv_path)

    target_col = 'chagas'
    y = df[target_col].astype(str).str.strip().str.lower() == 'true'
    y = y.astype(int)

    classes, counts = np.unique(y, return_counts=True)

    print("==================================================")
    print("DATASET CLASS DISTRIBUTION CHECK")
    print("==================================================")
    print(f"Total Dataset Records: {len(y)}")
    print("\nClass counts:")
    print(np.unique(y, return_counts=True))
    print("-" * 50)
    for c, cnt in zip(classes, counts):
        pct = (cnt / len(y)) * 100.0
        label_str = "Chagas Positive (1)" if c == 1 else "Chagas Negative / Control (0)"
        print(f"  - Class {c} ({label_str}): {cnt} samples ({pct:.2f}%)")
    print("==================================================")

if __name__ == '__main__':
    check_class_dist()

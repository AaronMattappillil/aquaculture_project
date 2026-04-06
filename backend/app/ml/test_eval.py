import pandas as pd
import numpy as np
import os
import glob
import joblib
from sklearn.metrics import accuracy_score, precision_score, recall_score, f1_score, confusion_matrix
from sklearn.metrics import mean_squared_error, mean_absolute_error, r2_score
from sklearn.model_selection import train_test_split

# Internal imports
from ml_utils import (
    standardize_columns, normalize_units, apply_scaling, 
    drop_invalid_values, get_ammonia_status, get_do_status
)
from pipeline import augment_features

DATASETS_DIR = "e:/src/Aquaculture Project/backend/app/ml/datasets"
MODELS_DIR = os.path.join(os.path.dirname(__file__), "models")

def report_clf(name, y_true, y_pred, labels=["SAFE", "WARNING", "DANGER"]):
    print(f"\n=== {name} Metrics ===")
    print(f"Accuracy: {accuracy_score(y_true, y_pred):.4f}")
    print(f"F1 (Weighted): {f1_score(y_true, y_pred, average='weighted'):.4f}")
    
    f1_vals = f1_score(y_true, y_pred, average=None)
    for i, f1 in enumerate(f1_vals):
        label = labels[i] if i < len(labels) else f"Class {i}"
        print(f"  F1 Score ({label}): {f1:.4f}")
    print(f"Confusion Matrix:\n{confusion_matrix(y_true, y_pred)}")

def evaluate():
    # 1. Load Models & Stats
    print("Loading models and stats...")
    from models_manager import load_all_artifacts
    arts = load_all_artifacts()
    scaler = arts['scaler']
    reg_model = arts['reg_model']
    clf_ammonia = arts['clf_ammonia']
    clf_do_bin = arts['clf_do_bin']
    clf_do_multi = arts['clf_do_multi']
    stats = arts['stats']
    threshold = stats.get('optimal_do_threshold', 0.5)

    # 2. Load and Preprocess Data
    all_files = glob.glob(os.path.join(DATASETS_DIR, "*.csv"))
    dfs = []
    for f in all_files:
        raw_df = pd.read_csv(f)
        orig_cols = list(raw_df.columns)
        std_df = standardize_columns(raw_df)
        norm_df = normalize_units(std_df, orig_cols)
        dfs.append(norm_df)
    df = pd.concat(dfs, ignore_index=True)
    df = drop_invalid_values(df).drop_duplicates()
    
    # Subsample to keep it manageable and consistent
    if len(df) > 150000:
        df, _ = train_test_split(df, train_size=150000, random_state=42)
    
    df = augment_features(df)
    df['ammonia_status'] = df['ammonia'].apply(get_ammonia_status)
    df['do_status'] = df['dissolved_oxygen'].apply(get_do_status)
    df['do_is_danger'] = (df['do_status'] == 2).astype(int)

    X_scaled, _ = apply_scaling(df, scaler=scaler)
    
    # Unified Split to keep alignment
    _, X_test, \
    _, y_ammonia_eval, \
    _, y_do_multi_eval, \
    _, y_do_bin_eval, \
    _, y_raw_test = train_test_split(
        X_scaled, df['ammonia_status'], df['do_status'], df['do_is_danger'], df[['ammonia', 'dissolved_oxygen']],
        test_size=0.2, random_state=42
    )

    # 3. Hybrid DO Inference (Stage 1 + Stage 2)
    print("\nRunning Two-Stage DO Inference...")
    probs_bin = clf_do_bin.predict_proba(X_test)[:, 1]
    y_bin_pred = (probs_bin >= threshold).astype(int)
    
    probs_multi = clf_do_multi.predict_proba(X_test)
    y_multi_pred = clf_do_multi.predict(X_test)
    
    # Metrics
    report_clf("DO Binary (Stage 1)", y_do_bin_eval, y_bin_pred, labels=["NON-DANGER", "DANGER"])
    report_clf("DO Multi (Stage 2)", y_do_multi_eval, y_multi_pred)
    report_clf("Ammonia Status", y_ammonia_eval, clf_ammonia.predict(X_test))

    # 4. Regression Evaluation
    y_reg_pred = reg_model.predict(X_test)
    # y_reg_pred[:, 0] is log1p ammo
    y_ammo_pred = np.expm1(y_reg_pred[:, 0])
    y_do_pred = y_reg_pred[:, 1]
    
    print("\n=== Regression Metrics (Inverse Log for Ammonia) ===")
    print(f"Ammonia R2: {r2_score(y_raw_test['ammonia'], y_ammo_pred):.4f}")
    print(f"DO R2: {r2_score(y_raw_test['dissolved_oxygen'], y_do_pred):.4f}")
    
    print("\nValidation complete.")

if __name__ == "__main__":
    evaluate()

import sys
import os
import pandas as pd
import numpy as np
import glob
from sklearn.model_selection import train_test_split, cross_val_score
from sklearn.ensemble import RandomForestRegressor, RandomForestClassifier, GradientBoostingClassifier
from sklearn.calibration import CalibratedClassifierCV
from sklearn.metrics import mean_squared_error, mean_absolute_error, r2_score
from sklearn.metrics import accuracy_score, precision_score, recall_score, f1_score, confusion_matrix, roc_auc_score
import joblib
import gc

# Internal imports
from ml_utils import standardize_columns, normalize_units, apply_scaling, drop_invalid_values, get_ammonia_status, get_do_status

# Set random seed for reproducibility
np.random.seed(42)

DATASETS_DIR = "e:/src/Aquaculture Project/backend/app/ml/datasets"
MODELS_DIR = os.path.join(os.path.dirname(__file__), "models")

def status_to_label(status_type, val):
    mapping = {0: "SAFE", 1: "WARNING", 2: "DANGER"}
    return mapping.get(val, "UNKNOWN")

def augment_features(df):
    """
    Generate water_level and is_day with controlled randomness.
    """
    def assign_water_level(turbidity):
        if turbidity > 10:
            return np.random.choice([0, 1], p=[0.7, 0.3])
        else:
            return np.random.choice([1, 0], p=[0.8, 0.2])
    
    df['water_level_encoded'] = df['turbidity'].apply(assign_water_level)
    df['water_level'] = df['water_level_encoded'].map({0: "LOW", 1: "NORMAL"})

    temp_min = df['temperature'].min()
    temp_max = df['temperature'].max()
    
    if temp_max == temp_min:
        df['is_day'] = np.random.choice([0, 1], size=len(df))
    else:
        prob_day = (df['temperature'] - temp_min) / (temp_max - temp_min)
        prob_day = prob_day.clip(0.1, 0.9)
        df['is_day'] = prob_day.apply(lambda p: np.random.choice([1, 0], p=[p, 1-p]))
        
    return df

def run_pipeline():
    # 1. Data Loading & Merging
    all_files = glob.glob(os.path.join(DATASETS_DIR, "*.csv"))
    dfs = []
    
    print(f"Loading {len(all_files)} datasets...")
    for file in all_files:
        print(f"Processing {os.path.basename(file)}...")
        temp_df = pd.read_csv(file, low_memory=False)
        original_cols = list(temp_df.columns)
        temp_df = standardize_columns(temp_df)
        temp_df = normalize_units(temp_df, original_cols)
        dfs.append(temp_df)
        
    df = pd.concat(dfs, ignore_index=True)
    df = drop_invalid_values(df)
    df = df.drop_duplicates()
    
    # 2. Label Engineering
    df['ammonia_status'] = df['ammonia'].apply(get_ammonia_status)
    df['do_status'] = df['dissolved_oxygen'].apply(get_do_status)
    # Stage 1 Target: Binary Binary (DANGER vs others)
    df['do_is_danger'] = (df['do_status'] == 2).apply(lambda x: 1 if x else 0)
    
    # 3. Feature Augmentation
    df = augment_features(df)
    df = df.dropna()
    print(f"Dataset size: {len(df)}")

    # 3.5 Stratified Subsampling
    limit = 150000
    if len(df) <= limit:
        print(f"Dataset size {len(df)} is within limit ({limit}). Skipping subsampling.")
    else:
        print(f"Subsampling dataset from {len(df)} to {limit}...")
        df['strat_target'] = df['ammonia_status'].astype(str) + "_" + df['do_status'].astype(str)
        counts = df['strat_target'].value_counts()
        valid_strat_classes = counts[counts >= 2].index
        
        if len(valid_strat_classes) < len(counts):
            print("Rare classes detected. Using random sampling.")
            df = df.sample(n=limit, random_state=42)
        else:
            try:
                # To downsample to 'limit', we use it as train_size
                df_sampled, _ = train_test_split(df, train_size=limit, stratify=df['strat_target'], random_state=42)
                df = df_sampled
            except Exception as e:
                print(f"Stratified subsampling failed: {e}. Falling back to random.")
                df = df.sample(n=limit, random_state=42)
        
        if 'strat_target' in df.columns:
            df = df.drop(columns=['strat_target'])
    
    # 5. Preprocessing & Scaling
    X_scaled, scaler = apply_scaling(df)
    
    # 6. Target Selection
    y_reg = pd.DataFrame({
        'ammonia': np.log1p(df['ammonia']), 
        'dissolved_oxygen': df['dissolved_oxygen']
    })
    y_ammo_clf = df['ammonia_status']
    y_do_multi = df['do_status']
    y_do_bin = df['do_is_danger']
    
    # 7. Unified Split
    # We split X_scaled and ALL targets in one go to keep them aligned
    X_train, X_test, \
    y_reg_train, y_reg_test, \
    y_ammo_train, y_ammo_test, \
    y_do_multi_train, y_do_multi_test, \
    y_do_bin_train, y_do_bin_test = train_test_split(
        X_scaled, y_reg, y_ammo_clf, y_do_multi, y_do_bin,
        test_size=0.2, random_state=42
    )

    # Further split X_test for validation (threshold tuning)
    X_test_final, X_val, \
    y_reg_test_final, y_reg_val, \
    y_ammo_test_final, y_ammo_val, \
    y_do_multi_test_final, y_do_multi_val, \
    y_do_bin_test_final, y_do_bin_val = train_test_split(
        X_test, y_reg_test, y_ammo_test, y_do_multi_test, y_do_bin_test,
        test_size=0.5, random_state=42
    )
    
    # Redefine test sets for evaluation later
    X_eval = X_test_final
    y_ammo_eval = y_ammo_test_final
    y_do_multi_eval = y_do_multi_test_final
    y_do_bin_eval = y_do_bin_test_final

    # Rename for training compatibility
    X_do_multi_res_base = X_train
    y_do_multi_res_base = y_do_multi_train
    
    X_do_bin_res_base = X_train
    y_do_bin_res_base = y_do_bin_train

    # 7. Resampling
    from imblearn.over_sampling import RandomOverSampler
    ros = RandomOverSampler(random_state=42)
    
    X_ammonia_res, y_ammonia_res = ros.fit_resample(X_train, y_ammo_train)
    
    # Targeted DO resampling
    max_c = max(y_do_multi_train.value_counts())
    strategy_multi = {0: max_c, 1: max_c, 2: int(max_c * 1.5)}
    ros_multi = RandomOverSampler(sampling_strategy=strategy_multi, random_state=42)
    X_do_multi_res, y_do_multi_res = ros_multi.fit_resample(X_train, y_do_multi_train)
    
    # Binary resampling (ensure DANGER is well represented)
    ros_bin = RandomOverSampler(sampling_strategy=0.8, random_state=42) # Danger is class 1
    # Check counts first
    bin_counts = y_do_bin_train.value_counts()
    if bin_counts[1] < bin_counts[0] * 0.8:
        X_do_bin_res, y_do_bin_res = ros_bin.fit_resample(X_train, y_do_bin_train)
    else:
        X_do_bin_res, y_do_bin_res = X_train, y_do_bin_train

    # 8. Training
    print("\nTraining Regression...")
    reg_model = RandomForestRegressor(n_estimators=100, max_depth=15, random_state=42, n_jobs=1)
    reg_model.fit(X_train, y_reg_train)
    
    print("Training Stage 1 (Binary DO)...")
    clf_do_bin_base = GradientBoostingClassifier(n_estimators=100, learning_rate=0.1, max_depth=6, random_state=42)
    clf_do_bin = CalibratedClassifierCV(clf_do_bin_base, method='sigmoid', cv=3)
    clf_do_bin.fit(X_do_bin_res, y_do_bin_res)
    
    print("Training Stage 2 (Multiclass DO)...")
    clf_do_multi_base = GradientBoostingClassifier(n_estimators=100, learning_rate=0.1, max_depth=6, random_state=42)
    clf_do_multi = CalibratedClassifierCV(clf_do_multi_base, method='sigmoid', cv=3)
    clf_do_multi.fit(X_do_multi_res, y_do_multi_res)
    
    print("Training Ammonia Classifier...")
    clf_ammonia_base = RandomForestClassifier(n_estimators=100, max_depth=15, class_weight='balanced', random_state=42)
    clf_ammonia = CalibratedClassifierCV(clf_ammonia_base, method='sigmoid', cv=3)
    clf_ammonia.fit(X_ammonia_res, y_ammonia_res)

    # 9. Threshold Search for DO DANGER
    print("\nOptimizing DO DANGER threshold...")
    y_prob_bin = clf_do_bin.predict_proba(X_val)[:, 1]
    best_threshold = 0.5
    best_f1 = 0
    for threshold in np.linspace(0.3, 0.8, 51):
        y_pred_bin = (y_prob_bin >= threshold).astype(int)
        f1 = f1_score(y_do_bin_val, y_pred_bin)
        if f1 > best_f1:
            best_f1 = f1
            best_threshold = threshold
    print(f"Optimal Threshold: {best_threshold:.3f} (F1: {best_f1:.4f})")

    # 10. Evaluation
    def eval_clf(name, y_true, y_pred, y_prob=None):
        print(f"\n=== {name} Metrics ===")
        print(f"Accuracy: {accuracy_score(y_true, y_pred):.4f}")
        print(f"F1 (Weighted): {f1_score(y_true, y_pred, average='weighted'):.4f}")
        if y_prob is not None:
            if len(np.unique(y_true)) == 2:
                print(f"ROC-AUC: {roc_auc_score(y_true, y_prob[:, 1]):.4f}")
            else:
                print(f"ROC-AUC (OVR): {roc_auc_score(y_true, y_prob, multi_class='ovr'):.4f}")
        
        f1s = f1_score(y_true, y_pred, average=None)
        recalls = recall_score(y_true, y_pred, average=None)
        for i, (f1, rec) in enumerate(zip(f1s, recalls)):
            print(f"  Class {i} -> F1: {f1:.4f}, Recall: {rec:.4f}")
        print(f"Confusion Matrix:\n{confusion_matrix(y_true, y_pred)}")

    y_bin_pred = (clf_do_bin.predict_proba(X_eval)[:, 1] >= best_threshold).astype(int)
    eval_clf("DO Binary (Stage 1)", y_do_bin_eval, y_bin_pred, clf_do_bin.predict_proba(X_eval))
    eval_clf("DO Multi (Stage 2)", y_do_multi_eval, clf_do_multi.predict(X_eval), clf_do_multi.predict_proba(X_eval))
    eval_clf("Ammonia", y_ammo_eval, clf_ammonia.predict(X_eval))

    # Regression eval
    y_reg_pred = reg_model.predict(X_test)
    y_ammo_pred = np.expm1(y_reg_pred[:, 0])
    y_do_pred = y_reg_pred[:, 1]
    
    print("\n=== Regression Metrics ===")
    r2_ammo = r2_score(np.expm1(y_reg_test['ammonia']), y_ammo_pred)
    r2_do = r2_score(y_reg_test['dissolved_oxygen'], y_do_pred)
    print(f"Ammonia R2 (Inverse Log): {r2_ammo:.4f}")
    print(f"DO R2: {r2_do:.4f}")

    # Persistence
    os.makedirs(MODELS_DIR, exist_ok=True)
    joblib.dump(reg_model, os.path.join(MODELS_DIR, "reg_model.joblib"))
    joblib.dump(clf_ammonia, os.path.join(MODELS_DIR, "clf_ammonia.joblib"))
    joblib.dump(clf_do_bin, os.path.join(MODELS_DIR, "clf_do_bin.joblib"))
    joblib.dump(clf_do_multi, os.path.join(MODELS_DIR, "clf_do_multi.joblib"))
    joblib.dump(scaler, os.path.join(MODELS_DIR, "scaler.joblib"))
    
    stats = {
        'optimal_do_threshold': best_threshold,
        'temp_min': df['temperature'].min(),
        'temp_max': df['temperature'].max()
    }
    joblib.dump(stats, os.path.join(MODELS_DIR, "training_stats.joblib"))
    print("\nModels and optimal threshold saved successfully.")

if __name__ == "__main__":
    run_pipeline()

import numpy as np
import pandas as pd
from app.ml.ml_utils import (
    standardize_columns, normalize_units, apply_scaling, 
    drop_invalid_values, get_ammonia_status, get_do_status
)
from app.ml.models_manager import load_model, load_all_artifacts

# Constants for hybrid logic
CONFIDENCE_THRESHOLD = 0.7

# Load models globally or within a class for performance
artifacts = load_all_artifacts()

def calculate_co2(ph):
    """CO2 = 12 * (10 ** (7 - pH))"""
    return 12 * (10 ** (7 - ph))

def get_zone_from_value(status_type, val):
    if status_type == 'ammonia':
        if val < 0.02: return "SAFE"
        if val <= 0.05: return "WARNING"
        return "DANGER"
    else: # DO
        if val > 5: return "SAFE"
        if val >= 3: return "WARNING"
        return "DANGER"

def predict_water_quality(temperature, ph, turbidity):
    """
    Complete hybrid prediction logic using two-stage DO classification.
    """
    if not artifacts['reg_model']:
        raise Exception("Models not trained or loaded. Please run the training pipeline first.")

    scaler = artifacts['scaler']
    reg_model = artifacts['reg_model']
    clf_ammonia = artifacts['clf_ammonia']
    clf_do_bin = artifacts['clf_do_bin']
    clf_do_multi = artifacts['clf_do_multi']
    stats = artifacts['stats']
    optimal_do_threshold = stats.get('optimal_do_threshold', 0.5)

    # 1. Deterministic RNG for inference
    seed_str = f"{temperature:.2f}_{ph:.2f}_{turbidity:.2f}"
    import hashlib
    seed_val = int(hashlib.md5(seed_str.encode()).hexdigest(), 16) % (2**32)
    from numpy.random import RandomState
    local_rng = RandomState(seed_val)

    # 2. Preprocessing & Feature Engineering
    # Feature engineering for interactions
    temp_ph = temperature * ph
    temp_turbidity = temperature * turbidity
    turbidity_ph = turbidity * ph
    stress_index = (temperature * turbidity) / (ph + 0.1)
    do_sat_proxy = 14.6 - 0.4 * temperature
    
    # Probabilistic but deterministic features
    # water_level
    if turbidity > 10:
        water_level_encoded = local_rng.choice([0, 1], p=[0.7, 0.3])
    else:
        water_level_encoded = local_rng.choice([1, 0], p=[0.8, 0.2])
    water_level_text = "LOW" if water_level_encoded == 0 else "NORMAL"

    # is_day
    temp_min_s = stats.get('temp_min', 20)
    temp_max_s = stats.get('temp_max', 35)
    if temp_max_s == temp_min_s:
        is_day_val = local_rng.choice([0, 1])
    else:
        prob_day = (temperature - temp_min_s) / (temp_max_s - temp_min_s)
        prob_day = max(0.1, min(0.9, prob_day))
        is_day_val = int(local_rng.choice([1, 0], p=[prob_day, 1-prob_day]))

    X_raw = pd.DataFrame([[
        temperature, ph, turbidity, water_level_encoded, is_day_val,
        temp_ph, temp_turbidity, turbidity_ph, stress_index, do_sat_proxy
    ]], columns=[
        'temperature', 'ph', 'turbidity', 'water_level_encoded', 'is_day',
        'temp_ph', 'temp_turbidity', 'turbidity_ph', 'stress_index', 'do_sat_proxy'
    ])
    
    X_scaled = scaler.transform(X_raw)
    
    # 3. Predict - Regression
    reg_pred = reg_model.predict(X_scaled)[0]
    # reg_pred[0] is log1p ammo, reg_pred[1] is DO
    
    # Ammonia specific processing
    raw_ammonia_log = float(reg_pred[0])
    ammonia_expm1 = np.expm1(raw_ammonia_log)
    final_ammonia = np.clip(ammonia_expm1, 0.0, 0.1)
    
    # Debug Logging (Requirement 7)
    print(f"DEBUG: Ammonia Raw Prediction (log1p): {raw_ammonia_log:.6f}")
    print(f"DEBUG: Ammonia Inverse Transformed (expm1): {ammonia_expm1:.6f}")
    print(f"DEBUG: Ammonia Final Clamped Value: {final_ammonia:.6f}")
    
    # Validation check (Requirement 5)
    if final_ammonia < 0 or final_ammonia > 0.100001: # Small epsilon for float
        raise ValueError(f"Invalid ammonia prediction: {final_ammonia}. Must be in [0, 0.1]")
    
    final_do = np.clip(reg_pred[1], 0, 15)

    # 4. Predict - Ammonia Status
    probs_ammonia = clf_ammonia.predict_proba(X_scaled)[0]
    conf_ammonia = np.max(probs_ammonia)
    ammonia_source = "classifier"
    
    if conf_ammonia > 0.7:
        ammonia_class = int(np.argmax(probs_ammonia))
    else:
        ammonia_source = "regression"
        # Use the strictly processed final_ammonia
        if final_ammonia > 0.05:
            ammonia_class = 2
        elif final_ammonia > 0.02:
            ammonia_class = 1
        else:
            ammonia_class = 0

    # 5. Predict - DO Status (Two-Stage Hybrid)
    # Stage 1: Binary Detection
    probs_bin = clf_do_bin.predict_proba(X_scaled)[0] # [others, danger]
    prob_danger = probs_bin[1]
    bin_margin = abs(prob_danger - (1 - prob_danger))
    
    # Stage 2: Multiclass Evaluation
    probs_multi = clf_do_multi.predict_proba(X_scaled)[0]
    top_two = np.sort(probs_multi)[-2:]
    multi_margin = top_two[1] - top_two[0]
    conf_do = np.max(probs_multi)
    
    do_source = "classifier"
    # Stage 1 Trigger with Margin Check
    if prob_danger >= optimal_do_threshold and bin_margin > 0.1:
        do_class = 2 # DANGER
        do_confidence = float(prob_danger)
    # Stage 2 Fallback if confident
    elif conf_do > 0.7 and multi_margin > 0.1:
        do_class = int(np.argmax(probs_multi))
        do_confidence = float(conf_do)
    else:
        # Fallback to regression
        do_source = "regression"
        do_confidence = 1.0 # Regression is "certain" in its value
        if final_do < 3.0:
            do_class = 2
        elif final_do < 5.0:
            do_class = 1
        else:
            do_class = 0

    # 6. Results
    status_map = {0: "SAFE", 1: "WARNING", 2: "DANGER"}
    
    return {
        "ammonia": float(final_ammonia),
        "ammonia_status": status_map[ammonia_class],
        "ammonia_confidence": float(conf_ammonia),
        "ammonia_source": ammonia_source,
        "do": float(final_do),
        "do_status": status_map[do_class],
        "do_confidence": float(do_confidence),
        "do_source": do_source,
        "co2": calculate_co2(ph),
        "water_level": water_level_text,
        "is_day": int(is_day_val)
    }

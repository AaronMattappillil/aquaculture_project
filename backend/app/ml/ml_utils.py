import pandas as pd
import numpy as np
from sklearn.preprocessing import StandardScaler

def get_ammonia_status(val):
    if val < 0.02: return 0  # SAFE
    if val <= 0.05: return 1 # WARNING
    return 2                 # DANGER

def get_do_status(val):
    if val > 5: return 0    # SAFE
    if val >= 3: return 1   # WARNING
    return 2                # DANGER

# Column mapping for standardization
# Standard names: temperature, ph, turbidity, ammonia, dissolved_oxygen
COLUMN_MAPPINGS = {
    'Temperature': 'temperature',
    'Temperature(C)': 'temperature',
    'TEMP': 'temperature',
    'temp': 'temperature',
    'PH': 'ph',
    'ph': 'ph',
    'Turbidity(NTU)': 'turbidity',
    'TURBIDITY': 'turbidity',
    'turbidity': 'turbidity',
    'Ammonia(g/ml)': 'ammonia',
    'AMMONIA(mg/l)': 'ammonia',
    'ammonia': 'ammonia',
    'Dissolved Oxygen(g/ml)': 'dissolved_oxygen',
    'DO': 'dissolved_oxygen',
    'dissolved_oxygen': 'dissolved_oxygen'
}

def standardize_columns(df: pd.DataFrame) -> pd.DataFrame:
    """
    Standardize column names using the mapping system.
    """
    # Rename columns based on mapping
    for old_col, new_col in COLUMN_MAPPINGS.items():
        if old_col in df.columns:
            df = df.rename(columns={old_col: new_col})
            
    # Keep only target columns
    target_cols = ['temperature', 'ph', 'turbidity', 'ammonia', 'dissolved_oxygen']
    existing_target_cols = [col for col in target_cols if col in df.columns]
    
    return df[existing_target_cols]

def normalize_units(df: pd.DataFrame, source_df_columns: list) -> pd.DataFrame:
    """
    Standardize labels and handle potential scaling from original column names.
    Expects ammonia and dissolved_oxygen to be in mg/L.
    """
    for col_name in source_df_columns:
        # Standardize the column name to find what it mapped to
        std_name = COLUMN_MAPPINGS.get(col_name)
        if not std_name:
            continue
            
        # Ammonia conversions
        if std_name == 'ammonia' and 'ammonia' in df.columns:
            if 'g/ml' in col_name.lower():
                print(f"Converting ammonia from g/ml to mg/L for column {col_name}")
                df['ammonia'] = df['ammonia'] * 1_000_000
            elif 'g/l' in col_name.lower() and 'mg/l' not in col_name.lower():
                print(f"Converting ammonia from g/L to mg/L for column {col_name}")
                df['ammonia'] = df['ammonia'] * 1_000
                
        # DO conversions (if needed, though usually mg/L is standard)
        if std_name == 'dissolved_oxygen' and 'dissolved_oxygen' in df.columns:
            if 'g/ml' in col_name.lower():
                print(f"Converting DO from g/ml to mg/L for column {col_name}")
                df['dissolved_oxygen'] = df['dissolved_oxygen'] * 1_000_000
            elif 'g/l' in col_name.lower() and 'mg/l' not in col_name.lower():
                print(f"Converting DO from g/L to mg/L for column {col_name}")
                df['dissolved_oxygen'] = df['dissolved_oxygen'] * 1_000
                
    return df

def drop_invalid_values(df: pd.DataFrame) -> pd.DataFrame:
    """
    Remove rows with Inf or NaN and apply clipping.
    """
    # Replace Inf with NaN then drop
    df = df.replace([np.inf, -np.inf], np.nan)
    # Drop rows where critical columns are missing
    df = df.dropna(subset=['temperature', 'ph', 'turbidity', 'ammonia', 'dissolved_oxygen'])
    
    # Apply clipping to remove extreme sensor noise
    df = clip_outliers(df)
    
    return df

def clip_outliers(df: pd.DataFrame) -> pd.DataFrame:
    """
    Apply strict hard-clipping as per requirements:
    DO in [0, 15], Ammonia in [0, 0.1].
    Other features in realistic ranges.
    """
    if 'temperature' in df.columns:
        df['temperature'] = df['temperature'].clip(0, 45)
    if 'ph' in df.columns:
        df['ph'] = df['ph'].clip(0, 14)
    if 'turbidity' in df.columns:
        df['turbidity'] = df['turbidity'].clip(0, 200)
    if 'ammonia' in df.columns:
        df['ammonia'] = df['ammonia'].clip(0, 0.1)
    if 'dissolved_oxygen' in df.columns:
        df['dissolved_oxygen'] = df['dissolved_oxygen'].clip(0, 15)
        
    return df

def add_interaction_features(df: pd.DataFrame) -> pd.DataFrame:
    """
    Add cross-feature interactions to improve non-linear relationship detection.
    """
    df['temp_ph'] = df['temperature'] * df['ph']
    df['temp_turbidity'] = df['temperature'] * df['turbidity']
    df['turbidity_ph'] = df['turbidity'] * df['ph']
    # Stress index: combined effect of high temp/turbidity and extreme pH
    df['stress_index'] = (df['temperature'] * df['turbidity']) / (df['ph'] + 0.1)
    # DO Saturation Proxy (Requirement: 14.6 - 0.4 * temperature)
    df['do_sat_proxy'] = 14.6 - 0.4 * df['temperature']
    return df

def apply_scaling(df: pd.DataFrame, scaler=None) -> tuple:
    """
    Normalize numerical features and interaction terms using StandardScaler.
    """
    # Interaction features must be added before scaling
    df = add_interaction_features(df)
    
    features = [
        'temperature', 'ph', 'turbidity', 'water_level_encoded', 'is_day',
        'temp_ph', 'temp_turbidity', 'turbidity_ph', 'stress_index', 'do_sat_proxy'
    ]
    X = df[features]
    
    if scaler is None:
        scaler = StandardScaler()
        X_scaled = scaler.fit_transform(X)
    else:
        # For inference, ensure features exist
        missing = set(features) - set(df.columns)
        if missing:
            # Re-apply interaction features if missing (safety check)
            df = add_interaction_features(df)
            X = df[features]
        X_scaled = scaler.transform(X)
        
    return X_scaled, scaler

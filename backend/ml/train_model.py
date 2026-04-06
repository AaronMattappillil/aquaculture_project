import pandas as pd
import numpy as np
import joblib
import os
from sklearn.model_selection import train_test_split, KFold
from sklearn.ensemble import RandomForestRegressor, GradientBoostingRegressor
from sklearn.neural_network import MLPRegressor
from sklearn.preprocessing import StandardScaler
from sklearn.metrics import root_mean_squared_error

def create_synthetic_data(n_samples=5000):
    np.random.seed(42)
    # Generate balanced dataset across risk zones
    
    # 3 zones for DO/NH3 roughly: 
    # ZONE 1: NORMAL (DO > 5, NH3 < 0.02)
    # ZONE 2: WARNING (DO 3-5, NH3 0.02-0.05)
    # ZONE 3: CRITICAL (DO < 3, NH3 > 0.05)

    data = []
    zones = ['NORMAL', 'WARNING', 'CRITICAL']
    choices = np.random.choice(zones, n_samples)
    
    for zone in choices:
        if zone == 'NORMAL':
            temp = np.random.normal(25, 2)
            ph = np.random.normal(7.5, 0.5)
            turb = np.random.normal(20, 5)
            light = np.random.normal(5000, 1000)
            wl = np.random.normal(150, 10)
            do = np.random.normal(6.5, 0.5)
            nh3 = np.random.uniform(0.0, 0.019)
        elif zone == 'WARNING':
            temp = np.random.normal(31, 1)
            ph = np.random.normal(6.2, 0.2)
            turb = np.random.normal(60, 10)
            light = np.random.normal(3000, 500)
            wl = np.random.normal(120, 15)
            do = np.random.normal(4.0, 0.5)
            nh3 = np.random.uniform(0.02, 0.049)
        else: # CRITICAL
            temp = np.random.normal(36, 1.5)
            ph = np.random.normal(5.5, 0.3)
            turb = np.random.normal(110, 15)
            light = np.random.normal(1000, 300)
            wl = np.random.normal(90, 20)
            do = np.random.normal(2.0, 0.5)
            nh3 = np.random.uniform(0.051, 0.1)
            
        data.append([temp, ph, turb, light, wl, do, nh3])
        
    df = pd.DataFrame(data, columns=['temperature', 'ph', 'turbidity', 'light_intensity', 'water_level', 'do_level', 'ammonia_level'])
    return df

def train():
    print("Generating dataset...")
    df = create_synthetic_data(1500)
    
    X = df[['temperature', 'ph', 'turbidity', 'light_intensity', 'water_level']]
    y = df[['do_level', 'ammonia_level']]
    
    # Scale
    scaler = StandardScaler()
    X_scaled = scaler.fit_transform(X)
    
    # Train
    model = RandomForestRegressor(n_estimators=100, random_state=42)
    model.fit(X_scaled, y)
    
    # Save
    curr_dir = os.path.dirname(__file__)
    joblib.dump(model, os.path.join(curr_dir, 'model.pkl'))
    joblib.dump(scaler, os.path.join(curr_dir, 'scaler.pkl'))
    print("Model and Scaler saved successfully.")

if __name__ == "__main__":
    train()

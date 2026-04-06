import os
import pandas as pd
from sklearn.model_selection import train_test_split
from sklearn.ensemble import RandomForestRegressor
from sklearn.multioutput import MultiOutputRegressor
from sklearn.metrics import mean_squared_error, r2_score
import joblib

def train_model():
    print("Loading synthetic dataset...")
    data_path = 'data/synthetic_aquaculture_data.csv'
    
    if not os.path.exists(data_path):
        print("Data generated file not found. Please run generate_data.py first.")
        return
        
    df = pd.read_csv(data_path)
    
    # Features & Targets
    X = df[['temperature', 'ph', 'turbidity', 'light', 'water_level']]
    y = df[['do', 'nh3']]
    
    X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)
    
    print("Training Multi-Output Random Forest Regressor...")
    model = MultiOutputRegressor(RandomForestRegressor(n_estimators=100, max_depth=10, random_state=42))
    model.fit(X_train, y_train)
    
    y_pred = model.predict(X_test)
    
    print("Model Evaluation:")
    mse = mean_squared_error(y_test, y_pred)
    r2 = r2_score(y_test, y_pred)
    print(f"Mean Squared Error: {mse:.4f}")
    print(f"R-squared Score: {r2:.4f}")
    
    os.makedirs('app/models/bin', exist_ok=True)
    model_path = 'app/models/bin/aquasense_rf_model.pkl'
    joblib.dump(model, model_path)
    print(f"Model saved successfully to {model_path}")

if __name__ == "__main__":
    train_model()

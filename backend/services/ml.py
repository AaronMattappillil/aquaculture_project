import os
import joblib
import pandas as pd
from typing import Dict, Any

MODEL_PATH = os.path.join(os.path.dirname(__file__), '..', 'ml', 'model.pkl')
SCALER_PATH = os.path.join(os.path.dirname(__file__), '..', 'ml', 'scaler.pkl')

model = None
scaler = None

def load_ml():
    global model, scaler
    if os.path.exists(MODEL_PATH) and os.path.exists(SCALER_PATH):
        model = joblib.load(MODEL_PATH)
        scaler = joblib.load(SCALER_PATH)

def predict_parameters(temperature: float, ph: float, turbidity: float, light_intensity: float, water_level: float) -> Dict[str, float]:
    if model is None or scaler is None:
        load_ml()
    
    if model is None or scaler is None:
        # Fallback dummy logic if model not generated yet
        return {"do_level": 6.5, "ammonia_level": 0.01}
    
    input_data = pd.DataFrame([{
        "temperature": temperature,
        "ph": ph,
        "turbidity": turbidity,
        "light_intensity": light_intensity,
        "water_level": water_level
    }])
    
    scaled_input = scaler.transform(input_data)
    prediction = model.predict(scaled_input)[0]
    
    return {
        "do_level": round(float(prediction[0]), 2),
        "ammonia_level": round(float(prediction[1]), 3)
    }

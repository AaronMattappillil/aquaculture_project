import os
import joblib
import json
import sys
import warnings

warnings.filterwarnings("ignore")

from typing import Any

# Load model and scaler globally so they stay in memory
_model: Any = None
_scaler: Any = None

try:
    _curr_dir = os.path.dirname(os.path.abspath(__file__))
    _model_path = os.path.join(_curr_dir, 'model.pkl')
    _scaler_path = os.path.join(_curr_dir, 'scaler.pkl')
    
    if os.path.exists(_model_path) and os.path.exists(_scaler_path):
        _model = joblib.load(_model_path)
        _scaler = joblib.load(_scaler_path)
except Exception:
    pass

def predict(temp, ph, turb, light, wl):
    model = _model
    scaler = _scaler
    
    if model is None or scaler is None:
        return {"error": "Model not trained or files missing. Run train_model.py first."}
        
    input_data = [[temp, ph, turb, light, wl]]
    
    scaled_input = scaler.transform(input_data)  # type: ignore
    prediction = model.predict(scaled_input)[0]  # type: ignore
    
    return {
        "do_level": round(float(prediction[0]), 2),
        "ammonia_level": round(float(prediction[1]), 3)
    }

if __name__ == "__main__":
    if len(sys.argv) == 6:
        try:
            temp = float(sys.argv[1])
            ph = float(sys.argv[2])
            turb = float(sys.argv[3])
            light = float(sys.argv[4])
            wl = float(sys.argv[5])
            
            result = predict(temp, ph, turb, light, wl)
            print(json.dumps(result))
        except ValueError:
            print(json.dumps({"error": "All arguments must be valid numbers."}))
    else:
        print(json.dumps({"error": f"Requires exactly 5 arguments: temp ph turb light wl (got {len(sys.argv) - 1})" }))

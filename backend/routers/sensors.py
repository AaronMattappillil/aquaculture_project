from fastapi import APIRouter, HTTPException, Depends
from typing import List, Dict, Any
from services.auth_service import get_current_user
from services.firebase import get_latest_sensor_reading, get_historical_sensor_readings
from services.ml import predict_parameters
from services.co2 import estimate_co2
from services.alert import check_thresholds_and_alert
from database import ponds_col, est_params_col, risk_pred_col
import uuid
from datetime import datetime

router = APIRouter()

@router.get('/live/{pond_id}')
async def get_live_sensors(pond_id: str, current_user: dict = Depends(get_current_user)):
    pond = await ponds_col.find_one({"pond_id": pond_id})
    if not pond:
        raise HTTPException(status_code=404, detail="Pond not found")
        
    reading = await get_latest_sensor_reading(pond_id)
    if not reading:
        # Return fallback dummy if firebase not configured
        reading = {
            "data_id": str(uuid.uuid4()),
            "sensor_id": "SNS-001",
            "user_id": current_user["_id"],
            "pond_id": pond_id,
            "temperature": 28.5,
            "ph": 7.2,
            "turbidity": 35.0,
            "light_intensity": 1500.0,
            "water_level": 110.0,
            "timestamp": datetime.utcnow().isoformat()
        }
    
    # Run ML & Formulas
    preds = predict_parameters(
        reading["temperature"], reading["ph"], 
        reading["turbidity"], reading["light_intensity"], 
        reading["water_level"]
    )
    
    co2 = estimate_co2(reading["ph"], reading["temperature"], reading["turbidity"])
    
    reading["do_level"] = preds["do_level"]
    reading["ammonia_level"] = preds["ammonia_level"]
    reading["co2_level"] = co2
    
    # Evaluate thresholds
    eval_dict = {
        "temperature": reading["temperature"],
        "ph": reading["ph"],
        "turbidity": reading["turbidity"],
        "do": preds["do_level"],
        "nh3": preds["ammonia_level"],
        "co2": co2
    }
    
    # Check asynchronously
    await check_thresholds_and_alert(pond_id, current_user["_id"], reading["data_id"], eval_dict)
    
    return reading

@router.get('/history/{pond_id}')
async def get_sensor_history(pond_id: str, current_user: dict = Depends(get_current_user)):
    pond = await ponds_col.find_one({"pond_id": pond_id})
    if not pond:
        raise HTTPException(status_code=404, detail="Pond not found")
        
    readings = await get_historical_sensor_readings(pond_id, limit=24)
    # If empty logic (fallback mock for UI)
    if not readings:
        for i in range(24):
            readings.append({
                "temperature": 28.0 + (i * 0.1) % 2,
                "ph": 7.0 + (i * 0.05) % 0.5,
                "timestamp": (datetime.utcnow()).isoformat()
            })
    return readings

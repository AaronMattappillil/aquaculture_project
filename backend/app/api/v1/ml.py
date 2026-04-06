from fastapi import APIRouter, HTTPException, Depends
from pydantic import BaseModel
from typing import Optional
from app.ml.predictor import predict_water_quality

router = APIRouter()

class WaterQualityInput(BaseModel):
    temperature: float
    ph: float
    turbidity: float

class WaterQualityOutput(BaseModel):
    ammonia: float
    ammonia_status: str
    ammonia_confidence: float
    ammonia_source: str
    do: float
    do_status: str
    do_confidence: float
    do_source: str
    co2: float
    water_level: str
    is_day: int

@router.post("/predict-water-quality", response_model=WaterQualityOutput)
async def get_prediction(data: WaterQualityInput):
    """
    Predict water quality parameters (Ammonia, DO, CO2) 
    and classify into zones (SAFE, WARNING, DANGER).
    """
    try:
        prediction = predict_water_quality(
            data.temperature, 
            data.ph, 
            data.turbidity
        )
        return prediction
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

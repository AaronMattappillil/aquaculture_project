from pydantic import BaseModel


class PredictionRequest(BaseModel):
  pond_id: str | None = None
  temperature: float
  ph: float
  turbidity: float
  light_intensity: float
  water_level: float


class PredictionResponse(BaseModel):
  dissolved_oxygen: float
  ammonia: float
  co2: float
  risk_levels: dict[str, str]


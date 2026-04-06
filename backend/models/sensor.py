from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime

class SensorReading(BaseModel):
    data_id: str
    sensor_id: str
    user_id: str
    pond_id: str
    temperature: float
    ph: float
    turbidity: float
    light_intensity: float
    water_level: float
    timestamp: datetime

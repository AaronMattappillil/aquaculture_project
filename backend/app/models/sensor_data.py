from datetime import datetime
from pydantic import BaseModel, Field

class SensorDataInDB(BaseModel):
    id: str | None = Field(alias="_id", default=None)
    pond_id: str
    device_id: str
    timestamp: datetime = Field(default_factory=datetime.utcnow)
    temperature: float
    ph: float
    turbidity: float
    light_intensity: float
    water_level: float
    
    # Predicted/Calculated values stored for history
    dissolved_oxygen: float
    ammonia: float
    co2: float

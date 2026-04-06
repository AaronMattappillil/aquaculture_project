from datetime import datetime
from pydantic import BaseModel, Field

class ReportInDB(BaseModel):
    id: str | None = Field(alias="_id", default=None)
    pond_id: str
    user_id: str
    sensor_snapshot: dict # Copy of sensor data at time of report
    trend_analysis: str # AI analysis text
    recommendations: list[str]
    alert_id: str | None = None
    created_at: datetime = Field(default_factory=datetime.utcnow)

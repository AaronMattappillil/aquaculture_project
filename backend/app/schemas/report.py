from datetime import datetime
from pydantic import BaseModel

class ReportOut(BaseModel):
    id: str
    pond_id: str
    user_id: str
    sensor_snapshot: dict
    trend_analysis: str
    recommendations: list[str]
    alert_id: str | None = None
    created_at: datetime

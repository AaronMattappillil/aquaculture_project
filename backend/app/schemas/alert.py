from datetime import datetime
from pydantic import BaseModel
from app.models.alert import AlertLevel

class AlertOut(BaseModel):
    id: str
    pond_id: str
    parameter: str
    value: float
    level: AlertLevel
    message: str
    is_read: bool = False
    status: str = "OPEN"
    acknowledged: bool = False
    created_at: datetime

class AlertUpdate(BaseModel):
    is_read: bool | None = None
    status: str | None = None

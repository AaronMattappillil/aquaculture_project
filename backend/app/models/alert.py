from datetime import datetime
from typing import Literal

from pydantic import BaseModel, Field

AlertLevel = Literal["SAFE", "WARNING", "DANGER", "CRITICAL"]
AlertType = Literal["THRESHOLD", "TREND", "PREDICTIVE", "SYSTEM", "ALGAE_DETECTED"]
Priority = Literal["CRITICAL", "WARNING", "INFO"]


class AlertInDB(BaseModel):
  id: str | None = Field(alias="_id", default=None)
  pond_id: str
  user_id: str
  parameter: str
  value: float
  threshold_min: float | None = None
  threshold_max: float | None = None
  level: AlertLevel
  alert_type: AlertType = "THRESHOLD"
  priority: Priority = "INFO"
  message: str
  created_at: datetime = Field(default_factory=datetime.utcnow)
  is_read: bool = False
  status: str = "OPEN"  # OPEN, RESOLVED
  acknowledged: bool = False
  acknowledged_at: datetime | None = None


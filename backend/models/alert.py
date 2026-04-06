from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime

class AlertResponse(BaseModel):
    id: str = Field(alias="_id")
    alert_id: str
    data_id: str
    pond_id: str
    user_id: str
    param_name: str
    param_value: float
    severity: str
    alert_message: str
    alert_status: str
    recommended_actions: Optional[List[str]] = []
    timestamp: datetime

    class Config:
        populate_by_name = True

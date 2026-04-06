from pydantic import BaseModel, Field
from typing import Optional, List, Dict, Any
from datetime import datetime

class ReportResponse(BaseModel):
    id: str = Field(alias="_id")
    report_id: str
    risk_id: str
    alert_id: str
    pond_id: str
    report_type: str
    analysis_text: str
    sensor_snapshot: Dict[str, Any]
    trend_data: Optional[List[Dict[str, Any]]] = []
    generated_date: datetime

    class Config:
        populate_by_name = True

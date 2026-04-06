from datetime import datetime
from pydantic import BaseModel, Field

class DeviceInDB(BaseModel):
    id: str | None = Field(alias="_id", default=None)
    pond_id: str
    device_id: str # ESP32_001 etc
    status: str = "active"
    last_seen: datetime = Field(default_factory=datetime.utcnow)
    created_at: datetime = Field(default_factory=datetime.utcnow)

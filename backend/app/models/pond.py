from datetime import datetime
from typing import Optional

from pydantic import BaseModel, Field
from app.models.common import PyObjectId


class PondBase(BaseModel):
  user_id: str
  name: str
  location: str = ""
  length_m: float = 0.0
  width_m: float = 0.0
  height_m: float = 0.0
  volume_m3: float = 0.0
  fish_species: str = "Unknown"
  fish_units: int = 0
  temperature_min: float = 22.0
  temperature_max: float = 30.0
  ph_min: float = 6.5
  ph_max: float = 8.5
  turbidity_min: float = 0.0
  turbidity_max: float = 40.0
  status: str = "INACTIVE"
  estimated_fish_count: Optional[int] = None
  device_connected: bool = False
  email_alerts: bool = False
  push_notifications: bool = True



class PondInDB(PondBase):
  id: Optional[PyObjectId] = Field(alias="_id", default=None)
  created_at: datetime = Field(default_factory=datetime.utcnow)
  updated_at: datetime = Field(default_factory=datetime.utcnow)


class PondResponse(PondBase):
  id: str = Field(alias="_id")
  created_at: datetime
  updated_at: datetime

  class Config:
    from_attributes = True
    populate_by_name = True


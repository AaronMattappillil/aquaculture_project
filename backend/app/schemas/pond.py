from datetime import datetime
from typing import Optional
from pydantic import BaseModel


class PondCreate(BaseModel):
  name: str
  location: str = ""
  length_m: float
  width_m: float
  height_m: float
  volume_m3: float = 0.0
  fish_species: str
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


class PondUpdate(BaseModel):
  name: str | None = None
  location: str | None = None
  length_m: float | None = None
  width_m: float | None = None
  height_m: float | None = None
  volume_m3: float | None = None
  fish_species: str | None = None
  fish_units: int | None = None
  temperature_min: float | None = None
  temperature_max: float | None = None
  ph_min: float | None = None
  ph_max: float | None = None
  turbidity_min: float | None = None
  turbidity_max: float | None = None
  status: str | None = None
  estimated_fish_count: int | None = None
  device_connected: bool | None = None
  email_alerts: bool | None = None
  push_notifications: bool | None = None


class PondOut(BaseModel):
  id: str
  name: str
  location: str
  length_m: float
  width_m: float
  height_m: float
  volume_m3: float
  fish_species: str
  fish_units: int
  temperature_min: float
  temperature_max: float
  ph_min: float
  ph_max: float
  turbidity_min: float
  turbidity_max: float
  status: str
  estimated_fish_count: Optional[int] = None
  device_connected: bool
  email_alerts: bool
  push_notifications: bool
  created_at: datetime


from app.schemas.sensor import SensorReading

class AdminPondOut(PondOut):
  sensor_data: Optional[SensorReading] = None

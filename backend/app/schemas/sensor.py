from datetime import datetime

from pydantic import BaseModel, Field, AliasChoices


class SensorReading(BaseModel):
  id: str | None = None
  pond_id: str
  timestamp: datetime
  temperature: float = 0.0
  ph: float = 0.0
  turbidity: float = 0.0
  light_intensity: float = 0.0
  water_level: float = 0.0
  
  # Predictable / Calculated fields (Synced with MQTT & UI)
  do: float | None = Field(default=None, validation_alias=AliasChoices("do", "dissolved_oxygen"))
  nh3: float | None = Field(default=None, validation_alias=AliasChoices("nh3", "ammonia"))
  co2: float | None = None
  
  # ML-predicted status classifications (SAFE | WARNING | DANGER)
  do_status: str | None = None
  nh3_status: str | None = None

  # Extension fields for ESP32 and predictive analysis
  water_level_str: str | None = None
  prediction_source: str | None = "hardware" # "ml" or "hardware"
  day: bool | None = None
  algae_sensor: bool | None = None


from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime

class PondCreate(BaseModel):
    pond_name: str
    length_m: float
    width_m: float
    depth_m: float
    fish_species: str
    fish_units: Optional[int] = None
    location_label: Optional[str] = None

class PondResponse(BaseModel):
    id: str = Field(alias="_id")
    pond_id: str
    user_id: str
    pond_name: str
    length_m: float
    width_m: float
    depth_m: float
    volume_m3: float
    fish_species: str
    fish_units: Optional[int] = None
    status: str
    location_label: Optional[str] = None
    created_at: datetime
    updated_at: datetime

    class Config:
        populate_by_name = True

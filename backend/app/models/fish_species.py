from typing import List, Optional
from pydantic import BaseModel, Field
from app.models.common import PyObjectId
from bson import ObjectId


class ParameterThreshold(BaseModel):
    name: str
    min: Optional[float] = None
    max: Optional[float] = None


class FishSpeciesBase(BaseModel):
    name: str
    temperature_min: float = 22.0
    temperature_max: float = 30.0
    ph_min: float = 6.5
    ph_max: float = 8.5
    turbidity: float = 10.0
    is_custom: bool = False
    created_by: Optional[str] = None


class FishSpeciesCreate(FishSpeciesBase):
    pass


class FishSpeciesInDB(FishSpeciesBase):
    id: Optional[PyObjectId] = Field(alias="_id", default=None)

    model_config = {"populate_by_name": True, "arbitrary_types_allowed": True}


class FishSpeciesOut(BaseModel):
    id: str
    name: str
    temperature_min: float
    temperature_max: float
    ph_min: float
    ph_max: float
    turbidity: float
    is_custom: bool
    created_by: Optional[str] = None

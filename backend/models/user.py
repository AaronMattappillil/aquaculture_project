from pydantic import BaseModel, EmailStr, Field
from typing import Optional
from datetime import datetime

class LoginRequest(BaseModel):
    username: str
    password: str

class RegisterRequest(BaseModel):
    first_name: str
    last_name: str
    email: EmailStr
    phone: Optional[str] = None
    address: Optional[str] = None
    username: str
    password: str
    # Initial Pond Config
    pond_length: Optional[float] = 10.0
    pond_width: Optional[float] = 10.0
    pond_depth: Optional[float] = 2.0
    fish_species: Optional[str] = "Tilapia"

class UserResponse(BaseModel):
    id: str = Field(alias="_id")
    first_name: str
    last_name: str
    email: str
    phone: Optional[str] = None
    address: Optional[str] = None
    username: str
    role: str
    status: str
    created_at: datetime
    updated_at: datetime

    class Config:
        populate_by_name = True

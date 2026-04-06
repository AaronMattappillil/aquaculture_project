from datetime import datetime
from typing import Literal, Optional

from pydantic import BaseModel, EmailStr, Field
from app.models.common import PyObjectId

UserRole = Literal["admin", "farmer"]


class UserBase(BaseModel):
  first_name: str
  last_name: str
  email: EmailStr
  phone: str
  address: str
  username: str


class UserInDB(UserBase):
  id: Optional[PyObjectId] = Field(alias="_id", default=None)
  password_hash: str
  role: UserRole = "farmer"
  status: str = "active"
  created_at: datetime = Field(default_factory=datetime.utcnow)
  updated_at: datetime = Field(default_factory=datetime.utcnow)


class UserResponse(UserBase):
  id: str = Field(alias="_id")
  role: UserRole
  status: str
  created_at: datetime
  updated_at: datetime

  class Config:
    from_attributes = True
    populate_by_name = True


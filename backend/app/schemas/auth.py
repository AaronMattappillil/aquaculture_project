from pydantic import BaseModel, EmailStr, Field

from app.models.user import UserRole


class SignupRequest(BaseModel):
  first_name: str
  last_name: str
  email: EmailStr
  address: str
  phone: str
  pond_length: float
  pond_width: float
  pond_height: float
  fish_species: str
  username: str
  password: str = Field(min_length=8, max_length=128)


class LoginRequest(BaseModel):
  email: EmailStr
  password: str = Field(min_length=8, max_length=128)


class LoginJSONRequest(BaseModel):
  username: str
  password: str = Field(min_length=8, max_length=128)


class ForgotPasswordRequest(BaseModel):
  email_or_username: str


class AuthResponse(BaseModel):
  id: str
  username: str
  role: UserRole
  access_token: str
  token_type: str = "bearer"


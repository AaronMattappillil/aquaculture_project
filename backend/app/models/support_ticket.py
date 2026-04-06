from datetime import datetime
from typing import Literal, Optional
from pydantic import BaseModel, Field, field_validator

SupportTicketStatus = Literal["open", "in_progress", "resolved"]

class SupportTicketInDB(BaseModel):
    id: str | None = Field(alias="_id", default=None)
    user_id: str
    user_email: str = ""
    category: str = "General"
    subject: str
    description: str
    status: str = "open" # Keep as str for validation then Literal final check
    pond_id: Optional[str] = None
    admin_response: Optional[str] = None
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)

    @field_validator('status', mode='before')
    @classmethod
    def normalize_status(cls, v):
        if v is None:
            return "open"
        if isinstance(v, str):
            return v.lower()
        return v

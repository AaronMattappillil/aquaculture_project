from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime

class TicketCreate(BaseModel):
    category: str
    subject: str
    message: str
    pond_id: Optional[str] = None

class TicketResponse(BaseModel):
    id: str = Field(alias="_id")
    ticket_id: str
    user_id: str
    category: str
    subject: str
    message: str
    pond_id: Optional[str] = None
    status: str
    internal_notes: Optional[str] = None
    admin_response: Optional[str] = None
    created_at: datetime
    resolved_at: Optional[datetime] = None
    updated_at: datetime

    class Config:
        populate_by_name = True

class AdminResponseUpdate(BaseModel):
    admin_response: str

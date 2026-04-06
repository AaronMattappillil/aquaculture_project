from datetime import datetime
from pydantic import BaseModel
from app.models.support_ticket import SupportTicketStatus

class SupportTicketCreate(BaseModel):
    category: str
    subject: str
    description: str
    pond_id: str | None = None

class SupportTicketOut(BaseModel):
    id: str
    user_id: str
    user_email: str
    category: str
    subject: str
    description: str
    status: SupportTicketStatus
    pond_id: str | None = None
    admin_response: str | None = None
    created_at: datetime
    updated_at: datetime

class SupportTicketResolve(BaseModel):
    admin_response: str

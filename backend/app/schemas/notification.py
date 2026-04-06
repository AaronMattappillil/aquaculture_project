from datetime import datetime
from pydantic import BaseModel

class NotificationOut(BaseModel):
    id: str
    user_id: str
    pond_id: str | None = None
    title: str
    message: str
    read: bool
    created_at: datetime

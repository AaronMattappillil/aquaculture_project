from datetime import datetime
from pydantic import BaseModel, Field

class NotificationInDB(BaseModel):
    id: str | None = Field(alias="_id", default=None)
    user_id: str
    pond_id: str | None = None
    title: str
    message: str
    read: bool = False
    created_at: datetime = Field(default_factory=datetime.utcnow)

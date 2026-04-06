from datetime import datetime
from pydantic import BaseModel, EmailStr
from app.models.user import UserRole
from typing import List
from app.schemas.pond import AdminPondOut
from app.schemas.support import SupportTicketOut

class AdminUserSummary(BaseModel):
    id: str
    username: str
    email: EmailStr
    first_name: str
    last_name: str
    role: UserRole
    num_ponds: int = 0
    active_alerts: int = 0
    num_reports: int = 0
    num_notifications: int = 0
    created_at: datetime

class UserStatusUpdate(BaseModel):
    status: str

class AdminUserProfile(BaseModel):
    id: str
    username: str
    email: EmailStr
    first_name: str
    last_name: str
    address: str
    phone: str
    status: str = "active"
    num_ponds: int
    active_alerts: int
    num_complaints: int
    num_reports: int = 0
    num_notifications: int = 0
    ponds: List[AdminPondOut] = []
    tickets: List[SupportTicketOut] = []
    created_at: datetime

class AdminDashboardTickets(BaseModel):
    open: int
    resolved: int

class AdminDashboardOut(BaseModel):
    total_users: int
    total_ponds: int
    tickets: AdminDashboardTickets

class AdminUserDetailUser(BaseModel):
    id: str
    username: str
    email: str
    first_name: str
    last_name: str
    address: str
    phone: str
    status: str = "active"

class AdminUserDetailPond(BaseModel):
    id: str
    name: str
    fish_species: str = "Tilapia"
    fish_units: int = 0
    status: str = "INACTIVE"

class AdminUserDetailTicket(BaseModel):
    id: str
    category: str = "General"
    subject: str
    status: str
    created_at: datetime

class AdminUserDetailPonds(BaseModel):
    count: int
    items: List[AdminUserDetailPond]

class AdminUserDetailTickets(BaseModel):
    count: int
    items: List[AdminUserDetailTicket]

class AdminUserDetailOut(BaseModel):
    user: AdminUserDetailUser
    ponds: AdminUserDetailPonds
    tickets: AdminUserDetailTickets

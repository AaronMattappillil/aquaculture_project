from fastapi import APIRouter, HTTPException, Depends
from typing import List
from models.ticket import TicketCreate, TicketResponse, AdminResponseUpdate
from services.auth_service import get_current_user, get_current_admin
from database import tickets_col
from datetime import datetime
import uuid

router = APIRouter()

@router.post('', response_model=TicketResponse)
async def create_ticket(body: TicketCreate, current_user: dict = Depends(get_current_user)):
    new_ticket = {
        'ticket_id': f'AS-{uuid.uuid4().hex[:6].upper()}',
        'user_id': current_user["_id"],
        'category': body.category,
        'subject': body.subject,
        'message': body.message,
        'pond_id': body.pond_id,
        'status': 'PENDING',
        'created_at': datetime.utcnow(),
        'updated_at': datetime.utcnow()
    }
    result = await tickets_col.insert_one(new_ticket)
    new_ticket['_id'] = str(result.inserted_id)
    return new_ticket

@router.get('/{user_id}', response_model=List[TicketResponse])
async def get_user_tickets(user_id: str, current_user: dict = Depends(get_current_user)):
    if current_user["_id"] != user_id and current_user["role"] != "admin":
        raise HTTPException(status_code=403, detail="Not authorized")
    
    cursor = tickets_col.find({"user_id": user_id}).sort("created_at", -1)
    tickets = await cursor.to_list(length=100)
    for t in tickets:
        t["_id"] = str(t["_id"])
    return tickets

@router.put('/{id}', response_model=TicketResponse)
async def update_ticket_admin(id: str, body: AdminResponseUpdate, admin_user: dict = Depends(get_current_admin)):
    ticket = await tickets_col.find_one({"ticket_id": id})
    if not ticket:
        raise HTTPException(status_code=404, detail="Ticket not found")
    
    updates = {
        "admin_response": body.admin_response,
        "status": "RESOLVED",
        "resolved_at": datetime.utcnow(),
        "updated_at": datetime.utcnow()
    }
    await tickets_col.update_one({"ticket_id": id}, {"$set": updates})
    updated_ticket = await tickets_col.find_one({"ticket_id": id})
    updated_ticket["_id"] = str(updated_ticket["_id"])
    return updated_ticket

from fastapi import APIRouter, Depends, HTTPException, Query
from app.api.deps import get_current_user
from app.db.mongo import support_tickets_collection
from app.models.user import UserInDB
from app.schemas.support import SupportTicketCreate, SupportTicketOut, SupportTicketResolve
from datetime import datetime
from bson import ObjectId

router = APIRouter(prefix="/support", tags=["support"])


@router.post("/tickets", response_model=SupportTicketOut)
async def create_ticket(
    req: SupportTicketCreate,
    user: UserInDB = Depends(get_current_user)
):
    ticket_data = {
        "user_id": str(user.id),
        "user_email": user.email,
        "category": req.category,
        "subject": req.subject,
        "description": req.description,
        "pond_id": req.pond_id,
        "status": "open",
        "created_at": datetime.utcnow(),
        "updated_at": datetime.utcnow()
    }

    result = await support_tickets_collection().insert_one(ticket_data)

    return SupportTicketOut(
        id=str(result.inserted_id),
        user_id=ticket_data["user_id"],
        user_email=ticket_data["user_email"],
        category=ticket_data["category"],
        subject=ticket_data["subject"],
        description=ticket_data["description"],
        status=ticket_data["status"],
        pond_id=ticket_data["pond_id"],
        admin_response=None,
        created_at=ticket_data["created_at"],
        updated_at=ticket_data["updated_at"]
    )


@router.get("/tickets", response_model=list[SupportTicketOut])
async def list_tickets(
    status: str | None = None,
    user: UserInDB = Depends(get_current_user)
):
    query = {}
    if user.role != "admin":
        query["user_id"] = str(user.id)
    elif status:
        query["status"] = status.lower()

    cursor = support_tickets_collection().find(query).sort("created_at", -1)

    tickets = []
    async for doc in cursor:
        tickets.append(
            SupportTicketOut(
                id=str(doc["_id"]),
                user_id=doc["user_id"],
                user_email=doc.get("user_email", ""),
                category=doc.get("category", "General"),
                subject=doc["subject"],
                description=doc["description"],
                status=doc.get("status", "open"),
                pond_id=doc.get("pond_id"),
                admin_response=doc.get("admin_response"),
                created_at=doc.get("created_at"),
                updated_at=doc.get("updated_at")
            )
        )

    return tickets


@router.get("/tickets/{ticket_id}", response_model=SupportTicketOut)
async def get_ticket(
    ticket_id: str,
    user: UserInDB = Depends(get_current_user)
):
    try:
        obj_id = ObjectId(ticket_id)
    except Exception:
        raise HTTPException(status_code=400, detail="Invalid Ticket ID")

    doc = await support_tickets_collection().find_one({"_id": obj_id})
    if not doc:
        raise HTTPException(status_code=404, detail="Ticket not found")
    
    if user.role != "admin" and doc["user_id"] != str(user.id):
        raise HTTPException(status_code=403, detail="Forbidden")

    return SupportTicketOut(
        id=str(doc["_id"]),
        user_id=doc["user_id"],
        user_email=doc.get("user_email", ""),
        category=doc.get("category", "General"),
        subject=doc["subject"],
        description=doc["description"],
        status=doc.get("status", "open"),
        pond_id=doc.get("pond_id"),
        admin_response=doc.get("admin_response"),
        created_at=doc.get("created_at"),
        updated_at=doc.get("updated_at")
    )


@router.get("/tickets/{ticket_id}/alerts")
async def get_ticket_alerts(
    ticket_id: str,
    user: UserInDB = Depends(get_current_user)
):
    try:
        obj_id = ObjectId(ticket_id)
    except Exception:
        raise HTTPException(status_code=400, detail="Invalid Ticket ID")

    ticket_doc = await support_tickets_collection().find_one({"_id": obj_id})
    if not ticket_doc:
        raise HTTPException(status_code=404, detail="Ticket not found")
    
    # Check permissions
    if user.role != "admin" and ticket_doc["user_id"] != str(user.id):
        raise HTTPException(status_code=403, detail="Forbidden")

    # If pond_id is present, fetch alerts for that pond
    query = {}
    if "pond_id" in ticket_doc and ticket_doc["pond_id"]:
        query = {"pond_id": ticket_doc["pond_id"]}
    else:
        # Fallback: all active alerts for the ticket owner
        query = {"user_id": ticket_doc["user_id"], "acknowledged": False}

    from app.db.mongo import alerts_collection
    cursor = alerts_collection().find(query).sort("timestamp", -1).limit(10)
    alerts = []
    async for doc in cursor:
        doc["_id"] = str(doc["_id"])
        # Format for frontend
        alerts.append({
            "alert_id": str(doc["_id"]),
            "pond_id": doc.get("pond_id"),
            "severity": doc.get("severity", "INFO"),
            "param_name": doc.get("param_name"),
            "param_value": doc.get("param_value"),
            "alert_message": doc.get("alert_message"),
            "alert_status": doc.get("alert_status", "UNRESOLVED"),
            "timestamp": doc.get("timestamp")
        })
    
    return alerts

@router.put("/tickets/{ticket_id}/resolve", response_model=SupportTicketOut)
async def resolve_ticket(
    ticket_id: str,
    req: SupportTicketResolve,
    user: UserInDB = Depends(get_current_user)
):
    if user.role != "admin":
        raise HTTPException(status_code=403, detail="Only admins can resolve tickets")

    try:
        obj_id = ObjectId(ticket_id)
    except Exception:
        raise HTTPException(status_code=400, detail="Invalid Ticket ID")

    ticket = await support_tickets_collection().find_one({"_id": obj_id})
    if not ticket:
        raise HTTPException(status_code=404, detail="Ticket not found")

    update_data = {
        "status": "resolved",
        "admin_response": req.admin_response,
        "updated_at": datetime.utcnow()
    }

    await support_tickets_collection().update_one({"_id": obj_id}, {"$set": update_data})
    
    updated_doc = await support_tickets_collection().find_one({"_id": obj_id})
    return SupportTicketOut(
        id=str(updated_doc["_id"]),
        user_id=updated_doc["user_id"],
        user_email=updated_doc.get("user_email", ""),
        category=updated_doc.get("category", "General"),
        subject=updated_doc["subject"],
        description=updated_doc["description"],
        status=updated_doc.get("status", "open"),
        pond_id=updated_doc.get("pond_id"),
        admin_response=updated_doc.get("admin_response"),
        created_at=updated_doc["created_at"],
        updated_at=updated_doc["updated_at"]
    )
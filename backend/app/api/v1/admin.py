"""Admin API routes for managing users and platform data."""
import logging
from datetime import datetime
from typing import List

from bson import ObjectId
from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import ValidationError

from app.schemas.admin import (
    AdminUserSummary, AdminUserProfile, UserStatusUpdate,
    AdminDashboardOut, AdminDashboardTickets, AdminUserDetailOut,
    AdminUserDetailUser, AdminUserDetailPond, AdminUserDetailTicket,
    AdminUserDetailPonds, AdminUserDetailTickets
)

from app.api.deps import get_admin_user
from app.db.mongo import (
    alerts_collection, notifications_collection, ponds_collection,
    reports_collection, support_tickets_collection, users_collection,
    sensor_readings_collection
)
from app.models.pond import PondInDB
from app.models.support_ticket import SupportTicketInDB
from app.models.user import UserInDB

from app.schemas.pond import AdminPondOut
from app.schemas.sensor import SensorReading
from app.schemas.support import SupportTicketOut

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/admin", tags=["admin"])


@router.get("/dashboard", response_model=AdminDashboardOut)
async def get_admin_dashboard(_: UserInDB = Depends(get_admin_user)):
    """Retrieve high-level system analytics for the Admin dashboard."""
    total_users = await users_collection().count_documents({})
    total_ponds = await ponds_collection().count_documents({})
    
    open_tickets = await support_tickets_collection().count_documents({"status": "open"})
    resolved_tickets = await support_tickets_collection().count_documents({"status": "resolved"})
    
    return AdminDashboardOut(
        total_users=total_users,
        total_ponds=total_ponds,
        tickets=AdminDashboardTickets(
            open=open_tickets,
            resolved=resolved_tickets
        )
    )



@router.get("/users", response_model=List[AdminUserSummary])
async def list_users(
    search: str | None = Query(None),
    _: UserInDB = Depends(get_admin_user)
):
    """List all users with optional search filtering."""
    query: dict = {}
    if search:
        query = {
            "$or": [
                {"username": {"$regex": search, "$options": "i"}},
                {"email": {"$regex": search, "$options": "i"}},
                {"first_name": {"$regex": search, "$options": "i"}},
                {"last_name": {"$regex": search, "$options": "i"}}
            ]
        }

    cursor = users_collection().find(query).sort("created_at", -1)
    users = []
    async for doc in cursor:
        user_id = str(doc["_id"])
        num_ponds = await ponds_collection().count_documents(
            {"user_id": user_id}
        )
        active_alerts = await alerts_collection().count_documents(
            {"user_id": user_id, "acknowledged": False}
        )
        num_reports = await reports_collection().count_documents(
            {"user_id": user_id}
        )
        num_notifications = await notifications_collection().count_documents(
            {"user_id": user_id}
        )

        users.append(AdminUserSummary(
            id=user_id,
            username=doc.get("username", ""),
            email=doc.get("email", ""),
            first_name=doc.get("first_name", ""),
            last_name=doc.get("last_name", ""),
            role=doc.get("role", "farmer"),
            num_ponds=num_ponds,
            active_alerts=active_alerts,
            num_reports=num_reports,
            num_notifications=num_notifications,
            created_at=doc.get("created_at", datetime.utcnow())
        ))
    return users


async def _build_user_profile(user_id: str) -> AdminUserProfile:
    """Internal helper that builds AdminUserProfile without FastAPI Depends."""
    try:
        obj_id = ObjectId(user_id)
    except Exception as exc:
        raise HTTPException(status_code=400, detail="Invalid User ID") from exc

    user_doc = await users_collection().find_one({"_id": obj_id})
    if not user_doc:
        raise HTTPException(status_code=404, detail="User not found")

    # Build ponds list with robust validation
    ponds_cursor = ponds_collection().find({"user_id": user_id})
    ponds: List[AdminPondOut] = []
    async for p in ponds_cursor:
        try:
            pond_id = str(p["_id"])
            p["_id"] = pond_id
            pond_in_db = PondInDB.model_validate(p)
            
            # Fetch latest sensor data
            latest_sensor = await sensor_readings_collection().find_one(
                {"pond_id": pond_id}, sort=[("timestamp", -1)]
            )
            sensor_reading = None
            if latest_sensor:
                latest_sensor["id"] = str(latest_sensor.pop("_id"))
                sensor_reading = SensorReading(**latest_sensor)

            ponds.append(AdminPondOut(
                id=pond_id,
                name=pond_in_db.name,
                location=pond_in_db.location,
                length_m=pond_in_db.length_m,
                width_m=pond_in_db.width_m,
                height_m=pond_in_db.height_m,
                volume_m3=pond_in_db.volume_m3,
                fish_species=pond_in_db.fish_species,
                fish_units=pond_in_db.fish_units,
                temperature_min=pond_in_db.temperature_min,
                temperature_max=pond_in_db.temperature_max,
                ph_min=pond_in_db.ph_min,
                ph_max=pond_in_db.ph_max,
                turbidity_min=pond_in_db.turbidity_min,
                turbidity_max=pond_in_db.turbidity_max,
                status=pond_in_db.status,
                estimated_fish_count=pond_in_db.estimated_fish_count,
                created_at=pond_in_db.created_at,
                sensor_data=sensor_reading
            ))
        except ValidationError as exc:
            logger.warning(
                "Validation error for pond %s, user %s: %s",
                p.get("_id"), user_id, exc
            )
            continue
        except Exception as exc:  # pylint: disable=broad-exception-caught
            logger.warning(
                "Error processing pond %s, user %s: %s",
                p.get("_id"), user_id, exc
            )
            continue

    # Build tickets list with robust validation
    logger.info("Building profile for user: %s", user_id)
    tickets_cursor = support_tickets_collection().find(
        {"user_id": user_id}
    ).sort("created_at", -1)

    tickets: List[SupportTicketOut] = []
    now = datetime.utcnow()
    found_count = 0
    async for t in tickets_cursor:
        found_count += 1
        try:
            ticket_id = str(t["_id"])
            t["_id"] = ticket_id
            ticket_in_db = SupportTicketInDB.model_validate(t)
            tickets.append(SupportTicketOut(
                id=ticket_id,
                user_id=ticket_in_db.user_id,
                user_email=ticket_in_db.user_email,
                category=ticket_in_db.category,
                subject=ticket_in_db.subject,
                description=ticket_in_db.description,
                status=ticket_in_db.status,
                pond_id=ticket_in_db.pond_id,
                admin_response=ticket_in_db.admin_response,
                created_at=ticket_in_db.created_at,
                updated_at=(
                    ticket_in_db.updated_at if ticket_in_db.updated_at else now
                )
            ))
        except ValidationError as exc:
            logger.error(
                "Validation error for ticket %s, user %s: %s",
                t.get("_id"), user_id, exc
            )
            continue
        except Exception as exc:  # pylint: disable=broad-exception-caught
            logger.error(
                "Unexpected error processing ticket %s, user %s: %s",
                t.get("_id"), user_id, exc
            )
            continue
    
    logger.info("Processed %d/%d tickets for user %s", len(tickets), found_count, user_id)

    num_ponds = len(ponds)
    active_alerts = await alerts_collection().count_documents(
        {"user_id": user_id, "acknowledged": False}
    )
    num_complaints = len(tickets)
    num_reports = await reports_collection().count_documents(
        {"user_id": user_id}
    )
    num_notifications = await notifications_collection().count_documents(
        {"user_id": user_id}
    )

    return AdminUserProfile(
        id=str(user_doc["_id"]),
        username=user_doc.get("username", ""),
        email=user_doc.get("email", ""),
        first_name=user_doc.get("first_name", ""),
        last_name=user_doc.get("last_name", ""),
        address=user_doc.get("address", ""),
        phone=user_doc.get("phone", ""),
        status=user_doc.get("status", "active"),
        num_ponds=num_ponds,
        active_alerts=active_alerts,
        num_complaints=num_complaints,
        num_reports=num_reports,
        num_notifications=num_notifications,
        ponds=ponds,
        tickets=tickets,
        created_at=user_doc.get("created_at", datetime.utcnow())
    )


@router.get("/users/{user_id}", response_model=AdminUserDetailOut)
async def get_user_detail(
    user_id: str, _: UserInDB = Depends(get_admin_user)
):
    """Retrieve detailed profile for a specific user with nested ponds/tickets."""
    try:
        obj_id = ObjectId(user_id)
    except Exception as exc:
        raise HTTPException(status_code=400, detail="Invalid User ID") from exc

    user_doc = await users_collection().find_one({"_id": obj_id})
    if not user_doc:
        raise HTTPException(status_code=404, detail="User not found")

    # Fetch User Info
    user_info = AdminUserDetailUser(
        id=str(user_doc["_id"]),
        username=user_doc.get("username", ""),
        email=user_doc.get("email", ""),
        first_name=user_doc.get("first_name", ""),
        last_name=user_doc.get("last_name", ""),
        address=user_doc.get("address", ""),
        phone=user_doc.get("phone", ""),
        status=user_doc.get("status", "active")
    )

    # Fetch Ponds with projection
    ponds_cursor = ponds_collection().find(
        {"user_id": user_id},
        {"name": 1, "fish_species": 1, "fish_units": 1, "status": 1}
    )
    ponds_items = []
    async for p in ponds_cursor:
        ponds_items.append(AdminUserDetailPond(
            id=str(p["_id"]),
            name=p.get("name", "Unnamed Pond"),
            fish_species=p.get("fish_species", "Tilapia"),
            fish_units=p.get("fish_units", 0),
            status=p.get("status", "INACTIVE")
        ))
    
    # Fetch Tickets
    tickets_cursor = support_tickets_collection().find(
        {"user_id": user_id}
    ).sort("created_at", -1)
    
    tickets_items = []
    async for t in tickets_cursor:
        tickets_items.append(AdminUserDetailTicket(
            id=str(t["_id"]),
            category=t.get("category", "General"),
            subject=t.get("subject", "No Subject"),
            status=t.get("status", "open"),
            created_at=t.get("created_at", datetime.utcnow())
        ))

    return AdminUserDetailOut(
        user=user_info,
        ponds=AdminUserDetailPonds(
            count=len(ponds_items),
            items=ponds_items
        ),
        tickets=AdminUserDetailTickets(
            count=len(tickets_items),
            items=tickets_items
        )
    )


@router.delete("/users/{user_id}")
async def delete_user(user_id: str, admin: UserInDB = Depends(get_admin_user)):
    """Delete a user and cascade delete all their associated data."""
    try:
        obj_id = ObjectId(user_id)
    except Exception as exc:
        raise HTTPException(status_code=400, detail="Invalid User ID") from exc

    if str(admin.id) == user_id:
        raise HTTPException(
            status_code=400, detail="Admins cannot delete themselves"
        )

    result = await users_collection().delete_one({"_id": obj_id})
    if result.deleted_count == 0:
        raise HTTPException(status_code=404, detail="User not found")

    # Cascade delete all user-related data
    await ponds_collection().delete_many({"user_id": user_id})
    await support_tickets_collection().delete_many({"user_id": user_id})
    await alerts_collection().delete_many({"user_id": user_id})
    await reports_collection().delete_many({"user_id": user_id})
    await notifications_collection().delete_many({"user_id": user_id})

    return {"message": "User and all associated data deleted successfully"}


@router.patch("/users/{user_id}/status", response_model=AdminUserProfile)
async def update_user_status(
    user_id: str,
    req: UserStatusUpdate,
    admin: UserInDB = Depends(get_admin_user)
):
    """Update a user's status (e.g., active, banned)."""
    try:
        obj_id = ObjectId(user_id)
    except Exception as exc:
        raise HTTPException(status_code=400, detail="Invalid User ID") from exc

    if str(admin.id) == user_id and req.status.upper() == "BANNED":
        raise HTTPException(
            status_code=400, detail="Admins cannot ban themselves"
        )

    result = await users_collection().update_one(
        {"_id": obj_id},
        {"$set": {
            "status": req.status.upper(), "updated_at": datetime.utcnow()
        }}
    )

    if result.matched_count == 0:
        raise HTTPException(status_code=404, detail="User not found")

    return await _build_user_profile(user_id)

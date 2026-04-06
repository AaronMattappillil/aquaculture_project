from fastapi import APIRouter, Depends, Query, HTTPException
from app.api.deps import get_current_user
from app.db.mongo import notifications_collection
from app.models.user import UserInDB
from app.schemas.notification import NotificationOut
from typing import List
from bson import ObjectId

router = APIRouter(prefix="/notifications", tags=["notifications"])

@router.get("", response_model=List[NotificationOut])
async def list_notifications(
    user: UserInDB = Depends(get_current_user)
):
    query = {"user_id": str(user.id)}
    cursor = notifications_collection().find(query).sort("created_at", -1).limit(100)
    notifications = []
    async for doc in cursor:
        doc["id"] = str(doc.pop("_id"))
        notifications.append(NotificationOut(**doc))
    return notifications

@router.post("/{notification_id}/read")
async def mark_as_read(
    notification_id: str,
    user: UserInDB = Depends(get_current_user)
):
    try:
        obj_id = ObjectId(notification_id)
    except Exception:
        raise HTTPException(status_code=400, detail="Invalid ID")
        
    result = await notifications_collection().update_one(
        {"_id": obj_id, "user_id": str(user.id)},
        {"$set": {"read": True}}
    )
    if result.matched_count == 0:
        raise HTTPException(status_code=404, detail="Notification not found")
        
    return {"message": "Notification marked as read"}

@router.post("/fcm-token")
async def save_fcm_token(
    fcm_token: str,
    user: UserInDB = Depends(get_current_user)
):
    from app.db.mongo import users_collection
    await users_collection().update_one(
        {"_id": ObjectId(user.id)},
        {"$set": {"fcm_token": fcm_token}}
    )
    return {"message": "Token saved"}

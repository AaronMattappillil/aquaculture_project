from fastapi import APIRouter, Depends, Query, HTTPException
from app.api.deps import get_current_user
from app.db.mongo import alerts_collection
from app.models.user import UserInDB
from app.schemas.alert import AlertOut, AlertUpdate
from typing import List, Any
from bson import ObjectId
from datetime import datetime

router = APIRouter(prefix="/alerts", tags=["alerts"])

@router.get("", response_model=List[AlertOut])
async def list_alerts(
    pond_id: str | None = Query(None),
    unread_only: bool = Query(False),
    user: UserInDB = Depends(get_current_user)
):
    query: dict[str, Any] = {"user_id": str(user.id)}
    if pond_id:
        query["pond_id"] = pond_id
    if unread_only:
        query["is_read"] = False
        
    cursor = alerts_collection().find(query).sort("created_at", -1).limit(100)
    alerts = []
    async for doc in cursor:
        doc["id"] = str(doc.pop("_id"))
        # Ensure status is populated for older records
        if "status" not in doc:
            doc["status"] = "OPEN"
        if "is_read" not in doc:
            doc["is_read"] = False
        alerts.append(AlertOut(**doc))
    return alerts

@router.put("/{alert_id}/acknowledge", response_model=AlertOut)
async def acknowledge_alert(
    alert_id: str,
    user: UserInDB = Depends(get_current_user)
):
    try:
        obj_id = ObjectId(alert_id)
    except Exception:
        raise HTTPException(status_code=400, detail="Invalid Alert ID")

    alert = await alerts_collection().find_one({"_id": obj_id})
    if not alert:
        raise HTTPException(status_code=404, detail="Alert not found")
    
    if str(alert["user_id"]) != str(user.id):
        raise HTTPException(status_code=403, detail="Forbidden")

    await alerts_collection().update_one(
        {"_id": obj_id},
        {"$set": {"acknowledged": True, "updated_at": datetime.utcnow()}}
    )

    updated_doc = await alerts_collection().find_one({"_id": obj_id})
    updated_doc["id"] = str(updated_doc.pop("_id"))
    return AlertOut(**updated_doc)

@router.patch("/{alert_id}", response_model=AlertOut)
async def patch_alert(
    alert_id: str,
    update: AlertUpdate,
    user: UserInDB = Depends(get_current_user)
):
    try:
        obj_id = ObjectId(alert_id)
    except Exception:
        raise HTTPException(status_code=400, detail="Invalid Alert ID")

    alert = await alerts_collection().find_one({"_id": obj_id})
    if not alert:
        raise HTTPException(status_code=404, detail="Alert not found")
    
    if str(alert["user_id"]) != str(user.id):
        raise HTTPException(status_code=403, detail="Forbidden")

    update_data = {k: v for k, v in update.model_dump().items() if v is not None}
    update_data["updated_at"] = datetime.utcnow()

    await alerts_collection().update_one(
        {"_id": obj_id},
        {"$set": update_data}
    )

    updated_doc = await alerts_collection().find_one({"_id": obj_id})
    updated_doc["id"] = str(updated_doc.pop("_id"))
    
    # Ensure status is populated
    if "status" not in updated_doc:
        updated_doc["status"] = "OPEN"
    if "is_read" not in updated_doc:
        updated_doc["is_read"] = False
        
    return AlertOut(**updated_doc)

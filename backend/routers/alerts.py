from fastapi import APIRouter, HTTPException, Depends
from typing import List
from models.alert import AlertResponse
from services.auth_service import get_current_user
from database import alerts_col, ponds_col
from bson import ObjectId

router = APIRouter()

@router.get('/{pond_id}', response_model=List[AlertResponse])
async def get_alerts_for_pond(pond_id: str, current_user: dict = Depends(get_current_user)):
    # Verify access to pond
    pond = await ponds_col.find_one({"pond_id": pond_id})
    if not pond:
        raise HTTPException(status_code=404, detail="Pond not found")
    if pond["user_id"] != current_user["_id"] and current_user["role"] != "admin":
        raise HTTPException(status_code=403, detail="Not authorized")
    
    cursor = alerts_col.find({"pond_id": pond_id}).sort("timestamp", -1)
    alerts = await cursor.to_list(length=100)
    for a in alerts:
        a["_id"] = str(a["_id"])
    return alerts

@router.put('/{alert_id}/resolve', response_model=AlertResponse)
async def resolve_alert(alert_id: str, current_user: dict = Depends(get_current_user)):
    alert = await alerts_col.find_one({"alert_id": alert_id})
    if not alert:
        raise HTTPException(status_code=404, detail="Alert not found")
    if alert["user_id"] != current_user["_id"] and current_user["role"] != "admin":
        raise HTTPException(status_code=403, detail="Not authorized")
    
    await alerts_col.update_one(
        {"alert_id": alert_id},
        {"$set": {"alert_status": "RESOLVED"}}
    )
    updated_alert = await alerts_col.find_one({"alert_id": alert_id})
    updated_alert["_id"] = str(updated_alert["_id"])
    return updated_alert

from fastapi import APIRouter, HTTPException, Depends
from typing import List
from models.user import UserResponse
from services.auth_service import get_current_admin
from database import users_col, ponds_col, tickets_col, alerts_col
from bson import ObjectId

router = APIRouter()

@router.get('/users', response_model=List[UserResponse])
async def get_all_users(admin_user: dict = Depends(get_current_admin)):
    cursor = users_col.find({})
    users = await cursor.to_list(length=1000)
    for u in users:
        u["_id"] = str(u["_id"])
    return users

@router.get('/users/{user_id}')
async def get_user_detail(user_id: str, admin_user: dict = Depends(get_current_admin)):
    user = await users_col.find_one({"_id": ObjectId(user_id)})
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    user["_id"] = str(user["_id"])
    
    ponds_count = await ponds_col.count_documents({"user_id": user_id})
    tickets_count = await tickets_col.count_documents({"user_id": user_id})
    alerts_count = await alerts_col.count_documents({"user_id": user_id})
    
    return {
        "user": user,
        "stats": {
            "ponds": ponds_count,
            "tickets": tickets_count,
            "alerts": alerts_count
        }
    }

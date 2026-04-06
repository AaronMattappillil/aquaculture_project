from fastapi import APIRouter, HTTPException, Depends
from typing import List
from models.pond import PondCreate, PondResponse
from services.auth_service import get_current_user
from database import ponds_col
from datetime import datetime
import uuid
from bson import ObjectId

router = APIRouter()

@router.get('/{user_id}', response_model=List[PondResponse])
async def get_user_ponds(user_id: str, current_user: dict = Depends(get_current_user)):
    if current_user["_id"] != user_id and current_user["role"] != "admin":
        raise HTTPException(status_code=403, detail="Not authorized")
    
    cursor = ponds_col.find({"user_id": user_id})
    ponds = await cursor.to_list(length=100)
    for p in ponds:
        p["_id"] = str(p["_id"])
    return ponds

@router.post('', response_model=PondResponse)
async def create_pond(body: PondCreate, current_user: dict = Depends(get_current_user)):
    volume = body.length_m * body.width_m * body.depth_m
    new_pond = {
        'pond_id': f'P-{uuid.uuid4().hex[:6].upper()}',
        'user_id': current_user["_id"],
        'pond_name': body.pond_name,
        'length_m': body.length_m,
        'width_m': body.width_m,
        'depth_m': body.depth_m,
        'volume_m3': volume,
        'fish_species': body.fish_species,
        'fish_units': body.fish_units,
        'status': 'healthy',
        'location_label': body.location_label,
        'created_at': datetime.utcnow(),
        'updated_at': datetime.utcnow()
    }
    result = await ponds_col.insert_one(new_pond)
    new_pond['_id'] = str(result.inserted_id)
    return new_pond

@router.delete('/{pond_id}')
async def delete_pond(pond_id: str, current_user: dict = Depends(get_current_user)):
    pond = await ponds_col.find_one({"pond_id": pond_id})
    if not pond:
        raise HTTPException(status_code=404, detail="Pond not found")
    if pond["user_id"] != current_user["_id"] and current_user["role"] != "admin":
        raise HTTPException(status_code=403, detail="Not authorized")
    
    await ponds_col.delete_one({"pond_id": pond_id})
    return {"message": "Pond deleted"}

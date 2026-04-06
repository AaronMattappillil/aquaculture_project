from fastapi import APIRouter, Depends, HTTPException
from bson import ObjectId

from app.api.deps import get_current_user
from app.db.mongo import ponds_collection
from app.models.pond import PondInDB
from app.models.user import UserInDB
from app.schemas.pond import PondCreate, PondOut, PondUpdate

router = APIRouter(prefix="/ponds", tags=["ponds"])


@router.get("", response_model=list[PondOut])
async def list_ponds(
    status: str | None = None,
    user: UserInDB = Depends(get_current_user)
):
    ponds = []
    query = {"user_id": str(user.id)}
    if status:
        query["status"] = {"$regex": f"^{status}$", "$options": "i"}

    async for doc in ponds_collection().find(query):
        try:
            doc["_id"] = str(doc["_id"])
            pond = PondInDB.model_validate(doc)

            ponds.append(
                PondOut(
                    id=pond.id or "",
                    name=pond.name,
                    location=pond.location,
                    length_m=pond.length_m,
                    width_m=pond.width_m,
                    height_m=pond.height_m,
                    volume_m3=pond.volume_m3,
                    fish_species=pond.fish_species,
                    fish_units=pond.fish_units,
                    temperature_min=pond.temperature_min,
                    temperature_max=pond.temperature_max,
                    ph_min=pond.ph_min,
                    ph_max=pond.ph_max,
                    turbidity_min=pond.turbidity_min,
                    turbidity_max=pond.turbidity_max,
                    status=pond.status,
                    device_connected=pond.device_connected,
                    email_alerts=pond.email_alerts,
                    push_notifications=pond.push_notifications,
                    created_at=pond.created_at,
                )
            )
        except Exception as e:
            print(f"Error parsing pond document {doc.get('_id')}: {e}")
            continue

    return ponds


@router.post("", response_model=PondOut)
async def create_pond(req: PondCreate, user: UserInDB = Depends(get_current_user)):
    pond = PondInDB(
        user_id=user.id or "",
        name=req.name,
        location=req.location,
        length_m=req.length_m,
        width_m=req.width_m,
        height_m=req.height_m,
        volume_m3=req.volume_m3,
        fish_species=req.fish_species,
        fish_units=req.fish_units,
        temperature_min=req.temperature_min,
        temperature_max=req.temperature_max,
        ph_min=req.ph_min,
        ph_max=req.ph_max,
        turbidity_min=req.turbidity_min,
        turbidity_max=req.turbidity_max,
        status=req.status,
        device_connected=req.device_connected,
    )

    result = await ponds_collection().insert_one(
        pond.model_dump(by_alias=True, exclude={"id"})
    )

    pond.id = str(result.inserted_id)

    return PondOut(
        id=pond.id,
        name=pond.name,
        location=pond.location,
        length_m=pond.length_m,
        width_m=pond.width_m,
        height_m=pond.height_m,
        volume_m3=pond.volume_m3,
        fish_species=pond.fish_species,
        fish_units=pond.fish_units,
        temperature_min=pond.temperature_min,
        temperature_max=pond.temperature_max,
        ph_min=pond.ph_min,
        ph_max=pond.ph_max,
        turbidity_min=pond.turbidity_min,
        turbidity_max=pond.turbidity_max,
        status=pond.status,
        device_connected=pond.device_connected,
        email_alerts=pond.email_alerts,
        push_notifications=pond.push_notifications,
        created_at=pond.created_at,
    )


@router.get("/{pond_id}", response_model=PondOut)
async def get_pond(pond_id: str, user: UserInDB = Depends(get_current_user)):
    try:
        obj_id = ObjectId(pond_id)
    except Exception:
        raise HTTPException(status_code=400, detail="Invalid Pond ID")

    doc = await ponds_collection().find_one({"_id": obj_id})

    if not doc:
        raise HTTPException(status_code=404, detail="Pond not found")
        
    if user.role != "admin" and str(doc.get("user_id")) != str(user.id):
        raise HTTPException(status_code=403, detail="Forbidden")

    doc["_id"] = str(doc["_id"])  # FIX
    pond = PondInDB.model_validate(doc)

    return PondOut(
        id=pond.id or "",
        name=pond.name,
        location=pond.location,
        length_m=pond.length_m,
        width_m=pond.width_m,
        height_m=pond.height_m,
        volume_m3=pond.volume_m3,
        fish_species=pond.fish_species,
        fish_units=pond.fish_units,
        temperature_min=pond.temperature_min,
        temperature_max=pond.temperature_max,
        ph_min=pond.ph_min,
        ph_max=pond.ph_max,
        turbidity_min=pond.turbidity_min,
        turbidity_max=pond.turbidity_max,
        status=pond.status,
        device_connected=pond.device_connected,
        email_alerts=pond.email_alerts,
        push_notifications=pond.push_notifications,
        created_at=pond.created_at,
    )


@router.patch("/{pond_id}", response_model=PondOut)
async def patch_pond(
    pond_id: str, req: PondUpdate, user: UserInDB = Depends(get_current_user)
):
    try:
        obj_id = ObjectId(pond_id)
    except Exception:
        raise HTTPException(status_code=400, detail="Invalid Pond ID")

    pond = await ponds_collection().find_one({"_id": obj_id})
    if not pond:
        raise HTTPException(status_code=404, detail="Pond not found")
        
    if user.role != "admin" and str(pond.get("user_id")) != str(user.id):
        raise HTTPException(status_code=403, detail="Forbidden")

    # Only include fields that were actually provided
    update_data = {k: v for k, v in req.model_dump().items() if v is not None}

    if user.role != "admin" and "status" in update_data:
        if pond.get("status") == "INACTIVE":
            raise HTTPException(status_code=403, detail="Cannot change status of an inactive pond. Contact admin.")
        if update_data["status"] == "INACTIVE":
            raise HTTPException(status_code=403, detail="Only admins can set a pond to inactive.")

    if not update_data:
        raise HTTPException(status_code=400, detail="No update data provided")

    result = await ponds_collection().update_one(
        {"_id": obj_id}, {"$set": update_data}
    )

    if result.matched_count == 0:
        raise HTTPException(status_code=404, detail="Pond not found")

    # Fetch updated document
    doc = await ponds_collection().find_one({"_id": obj_id})
    doc["_id"] = str(doc["_id"])
    updated_pond = PondInDB.model_validate(doc)

    return PondOut(
        id=updated_pond.id or "",
        name=updated_pond.name,
        location=updated_pond.location,
        length_m=updated_pond.length_m,
        width_m=updated_pond.width_m,
        height_m=updated_pond.height_m,
        volume_m3=updated_pond.volume_m3,
        fish_species=updated_pond.fish_species,
        fish_units=updated_pond.fish_units,
        temperature_min=updated_pond.temperature_min,
        temperature_max=updated_pond.temperature_max,
        ph_min=updated_pond.ph_min,
        ph_max=updated_pond.ph_max,
        turbidity_min=updated_pond.turbidity_min,
        turbidity_max=updated_pond.turbidity_max,
        status=updated_pond.status,
        device_connected=updated_pond.device_connected,
        email_alerts=updated_pond.email_alerts,
        push_notifications=updated_pond.push_notifications,
        created_at=updated_pond.created_at,
    )




@router.delete("/{pond_id}")
async def delete_pond(
    pond_id: str,
    user: UserInDB = Depends(get_current_user)
):
    try:
        obj_id = ObjectId(pond_id)
    except Exception:
        raise HTTPException(status_code=400, detail="Invalid Pond ID")

    pond = await ponds_collection().find_one({"_id": obj_id})
    if not pond:
        raise HTTPException(status_code=404, detail="Pond not found")

    if user.role != "admin" and str(pond["user_id"]) != str(user.id):
        raise HTTPException(status_code=403, detail="Forbidden")

    await ponds_collection().delete_one({"_id": obj_id})
    return {"message": "Pond deleted successfully"}
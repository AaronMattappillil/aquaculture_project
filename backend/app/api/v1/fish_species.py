from fastapi import APIRouter, HTTPException
from bson import ObjectId

from app.db.mongo import fish_species_collection
from app.models.fish_species import FishSpeciesCreate, FishSpeciesOut

router = APIRouter(prefix="/fish-species", tags=["fish-species"])


@router.get("", response_model=list[FishSpeciesOut])
async def get_fish_species():
    species = []
    async for doc in fish_species_collection().find():
        doc["id"] = str(doc["_id"])
        # No need to delete _id as it will be ignored by FishSpeciesOut
        species.append(FishSpeciesOut(**doc))
    return species


@router.post("", response_model=FishSpeciesOut, status_code=201)
async def create_fish_species(body: FishSpeciesCreate):
    doc = body.model_dump()
    result = await fish_species_collection().insert_one(doc)
    doc["id"] = str(result.inserted_id)
    return FishSpeciesOut(**doc)


@router.delete("/{species_id}")
async def delete_fish_species(species_id: str):
    try:
        obj_id = ObjectId(species_id)
    except Exception:
        raise HTTPException(status_code=400, detail="Invalid ID")
    result = await fish_species_collection().delete_one({"_id": obj_id})
    if result.deleted_count == 0:
        raise HTTPException(status_code=404, detail="Species not found")
    return {"message": "Deleted successfully"}

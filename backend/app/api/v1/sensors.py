from datetime import datetime

from fastapi import APIRouter, Depends, Query

from app.api.deps import get_current_user
from app.core.config import get_settings
from app.models.user import UserInDB
from app.schemas.sensor import SensorReading

from app.services.sensor_service import SensorService

router = APIRouter(prefix="/sensors", tags=["sensors"])
_settings = get_settings()
_sensor_service = SensorService()


def _service():
  return _sensor_service


@router.get("/ponds/{pond_id}/latest", response_model=SensorReading | None)
async def latest(pond_id: str, _: UserInDB = Depends(get_current_user)):
  return await _service().get_latest(pond_id)


@router.get("/ponds/{pond_id}/history", response_model=list[SensorReading])
async def history(
  pond_id: str,
  start: datetime | None = Query(None),
  end: datetime | None = Query(None),
  limit: int = Query(200, ge=1, le=1000),
  _: UserInDB = Depends(get_current_user),
):
  return await _service().get_history(pond_id, start, end, limit)


from fastapi import APIRouter, Depends, Query
from typing import List, Any
from bson import ObjectId
from bson.errors import InvalidId
from datetime import datetime

from app.api.deps import get_current_user
from app.db.mongo import reports_collection
from app.models.user import UserInDB
from app.schemas.report import ReportOut

router = APIRouter(prefix="/reports", tags=["reports"])


def clean_mongo_doc(doc: dict):
    clean: dict[str, Any] = {}

    for key, value in doc.items():

        if key == "_id":
            clean["id"] = str(value)

        elif isinstance(value, ObjectId):
            clean[key] = str(value)

        elif isinstance(value, datetime):
            clean[key] = value

        else:
            clean[key] = value

    return clean


@router.get("", response_model=List[ReportOut])
async def list_reports(
    pond_id: str | None = Query(None),
    alert_id: str | None = Query(None),
    user: UserInDB = Depends(get_current_user)
):

    query = {"user_id": str(user.id)}

    if alert_id:
        query["alert_id"] = alert_id

    # SAFE pond_id handling
    if pond_id:
        try:
            query["pond_id"] = ObjectId(pond_id)
        except InvalidId:
            query["pond_id"] = pond_id

    cursor = (
        reports_collection()
        .find(query)
        .sort("created_at", -1)
        .limit(50)
    )

    reports = []

    async for doc in cursor:
        clean_doc = clean_mongo_doc(doc)
        reports.append(clean_doc)

    return reports
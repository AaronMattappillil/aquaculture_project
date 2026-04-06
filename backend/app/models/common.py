from typing import Annotated
from pydantic import BeforeValidator, PlainSerializer, WithJsonSchema


def validate_object_id(v: any) -> str:
    from bson import ObjectId
    if isinstance(v, ObjectId):
        return str(v)
    if isinstance(v, str) and ObjectId.is_valid(v):
        return v
    raise ValueError("Invalid ObjectId")


PyObjectId = Annotated[
    str,
    BeforeValidator(validate_object_id),
    PlainSerializer(lambda v: str(v), return_type=str),
    WithJsonSchema({"type": "string"}, mode="serialization"),
]

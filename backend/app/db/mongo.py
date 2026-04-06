from motor.motor_asyncio import AsyncIOMotorClient

from app.core.config import get_settings

_settings = get_settings()
_client: AsyncIOMotorClient | None = None


def get_client() -> AsyncIOMotorClient:
  global _client
  if _client is None:
    _client = AsyncIOMotorClient(_settings.mongodb_uri)
  return _client


def get_db():
  return get_client()[_settings.mongodb_db]


def users_collection():
  return get_db()["users"]


def ponds_collection():
  return get_db()["ponds"]


def alerts_collection():
  return get_db()["alerts"]


def support_tickets_collection():
  return get_db()["support_tickets"]


def ml_models_collection():
  return get_db()["ml_models"]


def sensors_collection():
  return get_db()["sensors"]


def notifications_collection():
  return get_db()["notifications"]


def reports_collection():
  return get_db()["reports"]


def risk_predictions_collection():
  return get_db()["risk_predictions"]


def fish_species_collection():
  return get_db()["fish_species"]


def sensor_readings_collection():
  return get_db()["sensor_readings"]


async def init_db_indexes():
  # users
  await users_collection().create_index([("username", 1)], unique=True)
  await users_collection().create_index([("email", 1)], unique=True)
  # ponds
  await ponds_collection().create_index([("user_id", 1)])
  # alerts
  await alerts_collection().create_index([("pond_id", 1), ("timestamp", -1)])
  # support_tickets
  await support_tickets_collection().create_index([("user_id", 1)])
  # notifications
  await notifications_collection().create_index([("user_id", 1), ("is_read", 1)])
  # sensor_readings
  await sensor_readings_collection().create_index([("pond_id", 1), ("timestamp", -1)])

import os
from functools import lru_cache

from pydantic import AnyHttpUrl
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=os.path.join(os.path.dirname(__file__), "../../.env"),
        env_file_encoding="utf-8",
        case_sensitive=False
    )

    app_name: str = "Smart Aquaculture Backend"
    api_v1_prefix: str = "/api/v1"

    # "live"  = Production mode using MQTT ingestion and MongoDB
    data_mode: str = "live"

    mongodb_uri: str
    mongodb_db: str = "aquaculture"

    jwt_secret_key: str = os.getenv("JWT_SECRET_KEY", "dev_secret_key_change_me_in_prod")
    jwt_algorithm: str = "HS256"
    jwt_access_token_expires_minutes: int = 60 * 24 * 7  # 1 week

    frontend_base_url: AnyHttpUrl | None = None

    # MQTT Configuration
    mqtt_broker: str = "broker.hivemq.com"
    mqtt_port: int = 1883

    # Firebase Admin SDK (Keep if needed for RTDB, otherwise cleanup)
    firebase_rtdb_url: str | None = None
    firebase_credentials_path: str | None = None

    model_artifact_path: str = "app/ml/models/latest_model.pkl"


@lru_cache
def get_settings() -> Settings:
    return Settings()

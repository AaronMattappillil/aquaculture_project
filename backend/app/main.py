import asyncio
import logging
import os
from contextlib import asynccontextmanager

from fastapi import FastAPI, Depends
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

from app.api.v1 import (
    admin, alerts, auth, fish_species, ml, 
    ponds, sensors, support, reports, notifications
)
from app.core.config import get_settings
from app.db.mongo import init_db_indexes

# Configure Logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
)
_logger = logging.getLogger(__name__)

settings = get_settings()

@asynccontextmanager
async def lifespan(app: FastAPI):
    # --- STARTUP ---
    _logger.info("Initializing Aquaculture Backend...")
    
    # 1. Initialize MongoDB Indexes
    try:
        await init_db_indexes()
        _logger.info("Database indexes initialized successfully.")
    except Exception as e:
        _logger.error(f"Database index initialization failed: {e}")

    # 2. Initialize MQTT Service
    from app.services.mqtt_service import MQTTService
    try:
        loop = asyncio.get_running_loop()
        app.state.mqtt_service = MQTTService(loop)
        app.state.mqtt_service.start()
        _logger.info("MQTT Service started (broker.hivemq.com).")
    except Exception as e:
        _logger.error(f"MQTT Service failed to start: {e}")

    yield
    
    # --- SHUTDOWN ---
    _logger.info("Shutting down Aquaculture Backend...")
    if hasattr(app.state, "mqtt_service"):
        app.state.mqtt_service.stop()
        _logger.info("MQTT Service stopped.")

def create_app() -> FastAPI:
    app = FastAPI(
        title=settings.app_name,
        version="1.0.0",
        lifespan=lifespan
    )

    # CORS Configuration
    # In production, specify exact domains. For now, we allow common dev ports + regex.
    origins = [
        "http://localhost",
        "http://127.0.0.1",
        "http://localhost:8000",
        "http://localhost:3000",
        "http://localhost:6196", # Flutter Web
        "https://aquaculture-frontend.vercel.app", # Example production URL
    ]

    app.add_middleware(
        CORSMiddleware,
        allow_origins=origins,
        allow_origin_regex=os.getenv("CORS_ORIGIN_REGEX", "http://localhost:.*"),
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    # API Routes
    api_prefix = settings.api_v1_prefix
    app.include_router(auth.router, prefix=api_prefix)
    app.include_router(ponds.router, prefix=api_prefix)
    app.include_router(sensors.router, prefix=api_prefix)
    app.include_router(ml.router, prefix=api_prefix)
    app.include_router(support.router, prefix=api_prefix)
    app.include_router(reports.router, prefix=api_prefix)
    app.include_router(notifications.router, prefix=api_prefix)
    app.include_router(admin.router, prefix=api_prefix)
    app.include_router(alerts.router, prefix=api_prefix)
    app.include_router(fish_species.router, prefix=api_prefix)

    @app.get("/")
    async def health_check():
        """Production health check endpoint."""
        return {
            "status": "healthy",
            "app": settings.app_name,
            "version": "1.0.0",
            "environment": os.getenv("ENV", "production")
        }

    @app.exception_handler(Exception)
    async def global_exception_handler(request, exc):
        _logger.error(f"Unhandled exception: {exc}", exc_info=True)
        
        # If this is a request for documentation, show the actual error
        if request.url.path in ["/openapi.json", "/docs", "/redoc"]:
            import traceback
            return JSONResponse(
                status_code=500,
                content={
                    "detail": "OpenAPI Generation Failed",
                    "error": str(exc),
                    "traceback": traceback.format_exc()
                },
            )
            
        return JSONResponse(
            status_code=500,
            content={"detail": "Internal Server Error"},
        )

    return app

app = create_app()


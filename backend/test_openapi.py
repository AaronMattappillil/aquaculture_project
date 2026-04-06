import traceback
from app.main import app
from fastapi.openapi.utils import get_openapi
from fastapi import FastAPI

def test_router(router_name, router):
    print(f"Testing router: {router_name}")
    try:
        tmp_app = FastAPI()
        tmp_app.include_router(router)
        get_openapi(title=tmp_app.title, version=tmp_app.version, routes=tmp_app.routes)
        print(f"✅ {router_name} is OK")
    except Exception as e:
        print(f"❌ {router_name} FAILED:")
        traceback.print_exc()

from app.api.v1 import (
    admin, alerts, auth, fish_species, ml, 
    ponds, sensors, support, reports, notifications
)

routers = {
    "admin": admin.router,
    "alerts": alerts.router,
    "auth": auth.router,
    "fish_species": fish_species.router,
    "ml": ml.router,
    "ponds": ponds.router,
    "sensors": sensors.router,
    "support": support.router,
    "reports": reports.router,
    "notifications": notifications.router
}

for name, router in routers.items():
    test_router(name, router)

print("\nTesting full app:")
try:
    get_openapi(title=app.title, version=app.version, routes=app.routes)
    print("✅ Full app OpenAPI is OK")
except Exception as ex:
    print("❌ Full app OpenAPI FAILED")
    traceback.print_exc()

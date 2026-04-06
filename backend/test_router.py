from fastapi.testclient import TestClient
from bson import ObjectId
from app.main import app
from app.api.deps import get_current_user
from app.models.user import UserInDB

# Mock user
fake_user = UserInDB(
    _id=str(ObjectId()),
    username="testuser",
    email="test@example.com",
    hashed_password="fake",
    first_name="Test",
    last_name="User",
    role="farmer",
    status="active"
)

def override_get_user():
    return fake_user

app.dependency_overrides[get_current_user] = override_get_user

client = TestClient(app)

res = client.post(
    "/api/v1/support/tickets",
    json={
        "category": "General",
        "subject": "Test Ticket",
        "description": "This is a test",
        "pond_id": None
    }
)

print("STATUS:", res.status_code)
print("RESPONSE:", res.json())

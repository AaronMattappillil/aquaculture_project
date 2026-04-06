import asyncio
import httpx

async def test_submit():
    async with httpx.AsyncClient() as client:
        # First login to get token
        login_res = await client.post(
            "http://127.0.0.1:8000/api/v1/auth/login",
            data={"username": "farmer1", "password": "farm123"}
        )
        print("Login:", login_res.status_code, login_res.text)
        if login_res.status_code != 200:
            return
            
        token = login_res.json()["access_token"]
        
        # Now submit ticket
        ticket_res = await client.post(
            "http://127.0.0.1:8000/api/v1/support/tickets",
            headers={"Authorization": f"Bearer {token}"},
            json={
                "category": "General",
                "subject": "Test Ticket",
                "description": "This is a test ticket",
                "pond_id": None
            }
        )
        print("Submit Ticket:", ticket_res.status_code, ticket_res.text)

if __name__ == "__main__":
    asyncio.run(test_submit())

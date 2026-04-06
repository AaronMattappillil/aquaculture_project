import asyncio
from app.db.mongo import sensor_readings_collection, get_client

async def main():
    col = sensor_readings_collection()
    res = await col.delete_many({
        "$or": [
            {"temperature": 0},
            {"ph": 0},
            {"turbidity": 0},
            {"temperature": None},
            {"ph": None}
        ]
    })
    print(f"Deleted {res.deleted_count} dummy sensor records")
    client = get_client()
    client.close()

if __name__ == "__main__":
    asyncio.run(main())

import asyncio
from app.db.mongo import alerts_collection, notifications_collection, get_client

async def main():
    db_alerts = alerts_collection()
    db_notifications = notifications_collection()

    # We will delete alerts that are dummy or from the 'ensure_diversified_alerts'
    # The dummy messages:
    dummy_messages = [
        "System stable — all parameters optimal",
        "Temperature gradually increasing since morning",
        "Turbidity showing mild increase",
        "CO2 stable within acceptable range",
        "Sensor readings consistent and stable"
    ]
    
    # User specifically mentioned "high ammonia" spammed alerts
    # the threshold rule was: f"High Ammonia detected: {sensor_data['nh3']:.2f} mg/L"
    res1 = await db_alerts.delete_many({
        "$or": [
            {"message": {"$in": dummy_messages}},
            {"message": {"$regex": "High Ammonia detected.*"}},
            {"message": {"$regex": ".*Ammonia.*"}},
            {"parameter": "ammonia"},
            {"alert_type": {"$in": ["INFO", "TREND", "SYSTEM", "CONTEXT"]}}
        ]
    })
    
    res2 = await db_notifications.delete_many({
        "$or": [
            {"message": {"$in": dummy_messages}},
            {"message": {"$regex": "High Ammonia detected.*"}},
            {"message": {"$regex": ".*Ammonia.*"}},
            {"title": {"$regex": ".*Ammonia.*"}}
        ]
    })
    print(f"Deleted {res1.deleted_count} alerts from alerts_collection")
    print(f"Deleted {res2.deleted_count} notifications from notifications_collection")

    client = get_client()
    client.close()

if __name__ == "__main__":
    asyncio.run(main())

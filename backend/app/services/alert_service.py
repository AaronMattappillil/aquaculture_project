from datetime import datetime, timedelta
from app.db.mongo import alerts_collection, notifications_collection, sensors_collection
from app.models.alert import AlertInDB, AlertLevel, AlertType, Priority
from app.models.notification import NotificationInDB
from app.models.pond import PondInDB
from bson import ObjectId

class AlertService:
    async def process_sensor_alerts(self, pond: PondInDB, sensor_data: dict):
        """
        Redesigned Alert System:
        Threshold, Trend, Predictive, and System alerts with de-spam logic and 24h timestamps.
        """
        pond_id = str(pond.id)
        user_id = pond.user_id
        current_ts = datetime.utcnow()
        if pond.status != "ACTIVE" or not pond.device_connected:
            return
            
        def is_valid_sensor_data(data: dict) -> bool:
            if not data:
                return False
            return (
                data.get("temperature", 0) > 0 and
                data.get("ph", 0) > 0 and
                data.get("turbidity", -1) >= 0
            )
            
        if not is_valid_sensor_data(sensor_data):
            return
            

        # 1. Fetch History for Trend and Predictive Analysis (last 3 hours)
        history_cursor = sensors_collection().find(
            {"pond_id": pond_id, "timestamp": {"$gte": current_ts - timedelta(hours=3)}},
            sort=[("timestamp", 1)]
        )
        history = [doc async for doc in history_cursor]
        
        alert_payloads = []

        # region A. Threshold & Early Warning Alerts
        # Logic: If within 10% of limit -> Early Warning (INFO/WARNING)
        threshold_rules = [
            ("temperature", sensor_data["temperature"], pond.temperature_min, pond.temperature_max, f"Temperature {sensor_data['temperature']:.2f}°C is outside optimal range", "DANGER", "CRITICAL"),
            ("ph", sensor_data["ph"], pond.ph_min, pond.ph_max, f"pH level {sensor_data['ph']:.2f} is outside optimal range", "DANGER", "CRITICAL"),
            ("turbidity", sensor_data["turbidity"], 0.0, pond.turbidity_max, f"High Turbidity detected: {sensor_data['turbidity']:.2f} NTU", "WARNING", "WARNING"),
            ("dissolved_oxygen", sensor_data["do"], 5.0, 20.0, f"Low Dissolved Oxygen: {sensor_data['do']:.2f} mg/L", "CRITICAL", "CRITICAL"),
            ("ammonia", sensor_data["nh3"], 0.0, 0.1, f"High Ammonia detected: {sensor_data['nh3']:.2f} mg/L", "DANGER", "CRITICAL"),
            ("co2", sensor_data["co2"], 0.0, 10.0, f"High CO2 detected: {sensor_data['co2']:.2f} mg/L", "WARNING", "WARNING")
        ]
        
        for param, val, min_v, max_v, msg, level, priority in threshold_rules:
            if param == "turbidity" and val == 0:
                continue
                
            if val < min_v or val > max_v:
                alert_payloads.append({
                    "param": param, "val": val, "min": min_v, "max": max_v, "msg": msg, "level": level, "priority": priority, "type": "THRESHOLD"
                })
            elif (max_v and val > max_v * 0.9) or (min_v and val < min_v * 1.1):
                # Early Warning
                alert_payloads.append({
                    "param": param, "val": val, "msg": f"{param.replace('_',' ').title()} approaching upper safe limit", "level": "WARNING", "priority": "WARNING", "type": "EARLY_WARNING"
                })
        # endregion

        # region B. Trend Alerts (Detect steady rise/fall)
        if len(history) >= 5:
            for param in ["temperature", "dissolved_oxygen"]:
                param_key = "temperature" if param == "temperature" else "dissolved_oxygen"
                vals = [h.get(param_key, 0) or h.get("do", 0) for h in history]
                if all(vals[i] < vals[i+1] for i in range(len(vals)-1)) and (vals[-1] - vals[0] > 0.2):
                    alert_payloads.append({
                        "param": param, "val": vals[-1], "msg": f"{param.replace('_',' ').title()} gradually increasing since morning", "level": "WARNING", "priority": "TREND", "type": "TREND"
                    })
                elif all(vals[i] > vals[i+1] for i in range(len(vals)-1)) and (vals[0] - vals[-1] > 0.2):
                    alert_payloads.append({
                        "param": param, "val": vals[-1], "msg": f"{param.replace('_',' ').title()} slightly decreasing over last 2 hours", "level": "WARNING", "priority": "TREND", "type": "TREND"
                    })
        # endregion

        # region C. Context-Aware Alerts
        if sensor_data["temperature"] > 29.5 and sensor_data["do"] < 6.5:
             alert_payloads.append({
                "param": "do", "val": sensor_data["do"], "msg": "High temperature may reduce oxygen levels; monitoring closely", "level": "INFO", "priority": "INFO", "type": "CONTEXT"
            })
        # endregion

        # region D. Algae Detection (High Priority)
        if sensor_data.get("algae_detected"):
            # 10 minute debounce for algae alerts to prevent spam
            recent_algae = await alerts_collection().find_one({
                "pond_id": pond_id,
                "alert_type": "ALGAE_DETECTED",
                "status": "OPEN",
                "created_at": {"$gte": current_ts - timedelta(minutes=10)}
            })
            
            if not recent_algae:
                alert_payloads.append({
                    "param": "algae", "val": 1.0, 
                    "msg": "CRITICAL: Algae detected in pond! Please inspect and clear immediately.", 
                    "level": "CRITICAL", "priority": "CRITICAL", "type": "ALGAE_DETECTED"
                })
        # endregion

        # 2. Process and Store Payloads with Cooldown
        for p in alert_payloads:
            recent = await alerts_collection().find_one({
                "pond_id": pond_id,
                "parameter": p["param"],
                "alert_type": p["type"],
                "status": "OPEN",
                "created_at": {"$gte": current_ts - timedelta(minutes=60)}
            })
            
            if not recent:
                ts = current_ts # Will be sorted correctly by created_at
                
                alert = AlertInDB(
                    pond_id=pond_id, user_id=user_id, parameter=p["param"], value=round(p["val"], 2),
                    threshold_min=p.get("min"), threshold_max=p.get("max"),
                    level=p["level"], alert_type=p["type"], priority=p["priority"],
                    message=p["msg"], created_at=ts
                )
                await alerts_collection().insert_one(alert.model_dump(by_alias=True, exclude={"id"}))
                
                notif = NotificationInDB(
                    user_id=user_id, pond_id=pond_id, title=f"{p['priority']} Alert: {p['type']}",
                    message=p["msg"], created_at=ts
                )
                await notifications_collection().insert_one(notif.model_dump(by_alias=True, exclude={"id"}))

        # 3. Auto-Resolution for Threshold Alerts
        safe_checks = {
            "temperature": pond.temperature_min <= sensor_data["temperature"] <= pond.temperature_max,
            "ph": pond.ph_min <= sensor_data["ph"] <= pond.ph_max,
            "turbidity": sensor_data["turbidity"] <= pond.turbidity_max,
            "dissolved_oxygen": sensor_data["do"] >= 5.5,
            "ammonia": sensor_data["nh3"] <= 0.08,
            "co2": sensor_data["co2"] <= 8.0,
            "algae": not sensor_data.get("algae_detected")
        }
        for param, is_safe in safe_checks.items():
            if is_safe:
                await alerts_collection().update_many(
                    {"pond_id": pond_id, "parameter": param, "status": "OPEN", "alert_type": {"$in": ["THRESHOLD", "ALGAE_DETECTED"]}},
                    {"$set": {"status": "RESOLVED", "is_read": True, "resolved_at": datetime.utcnow()}}
                )



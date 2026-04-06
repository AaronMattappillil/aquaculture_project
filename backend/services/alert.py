from typing import Dict, Any, List
from database import alerts_col, reports_col, risk_pred_col, notifications_col, users_col
from services.firebase import send_push_notification
import uuid
from datetime import datetime

THRESHOLDS = {
    "temperature": {"warning": (30, 35), "critical": (35, float('inf'))},
    "ph": {"warning": (6.5, 8.5), "critical": (6.0, 9.0)}, # Out of bounds
    "turbidity": {"warning": (50, 100), "critical": (100, float('inf'))},
    "do": {"warning": (3, 5), "critical": (0, 3)},
    "nh3": {"warning": (0.02, 0.05), "critical": (0.05, float('inf'))},
    "co2": {"warning": (15, 20), "critical": (20, float('inf'))}
}

async def check_thresholds_and_alert(pond_id: str, user_id: str, data_id: str, readings: Dict[str, float]):
    alerts_created = []
    
    for param, val in readings.items():
        if param not in THRESHOLDS:
            continue
            
        severity = None
        thresh = THRESHOLDS[param]
        
        # pH is a range where both low and high are bad
        if param == "ph":
            if val < thresh["critical"][0] or val > thresh["critical"][1]:
                severity = "CRITICAL"
            elif val < thresh["warning"][0] or val > thresh["warning"][1]:
                severity = "WARNING"
        # DO is lower-is-worse
        elif param == "do":
            if val < thresh["critical"][1]:
                severity = "CRITICAL"
            elif val < thresh["warning"][1]:
                severity = "WARNING"
        # Others are higher-is-worse
        else:
            if val > thresh["critical"][0]:
                severity = "CRITICAL"
            elif val > thresh["warning"][0]:
                severity = "WARNING"
                
        if severity:
            alert = {
                "alert_id": f"AS-{uuid.uuid4().hex[:4].upper()}",
                "data_id": data_id,
                "pond_id": pond_id,
                "user_id": user_id,
                "param_name": param,
                "param_value": val,
                "severity": severity,
                "alert_message": f"{severity}: {param.upper()} out of bounds ({val})",
                "alert_status": "UNRESOLVED",
                "recommended_actions": ["Check sensors", "Adjust water quality"],
                "timestamp": datetime.utcnow()
            }
            res = await alerts_col.insert_one(alert)
            alerts_created.append(alert)
            
            # Create a notification doc
            notif = {
                "notification_id": str(uuid.uuid4()),
                "user_id": user_id,
                "alert_id": alert["alert_id"],
                "title": f"AquaSense {severity} Alert",
                "body": alert["alert_message"],
                "is_read": False,
                "sent_via_fcm": False,
                "timestamp": datetime.utcnow()
            }
            
            user = await users_col.find_one({"_id": user_id})
            if user and "fcm_token" in user:
                sent = await send_push_notification(user["fcm_token"], notif["title"], notif["body"])
                notif["sent_via_fcm"] = sent
                
            await notifications_col.insert_one(notif)
            
    return alerts_created

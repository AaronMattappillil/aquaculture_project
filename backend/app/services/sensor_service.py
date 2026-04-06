from datetime import datetime
from bson import ObjectId
from app.db.mongo import sensor_readings_collection, ponds_collection
from app.schemas.sensor import SensorReading
from app.core.config import get_settings

from app.ml.predictor import predict_water_quality

import logging
_logger = logging.getLogger(__name__)

_settings = get_settings()

class SensorService:
    def __init__(self):
        pass

    def _get_pond_query(self, pond_id: str) -> dict:
        """Helper to create a query that matches both String and ObjectId."""
        query_ids = [pond_id]
        if ObjectId.is_valid(pond_id):
            query_ids.append(ObjectId(pond_id))
        return {"pond_id": {"$in": query_ids}}

    def _hydrate_reading(self, r: dict):
        """Calculates ML estimations locally if they are missing or zero in DB."""
        # If raw sensors exist but estimations are missing
        temp = r.get("temperature", 0)
        ph = r.get("ph", 0)
        turbidity = r.get("turbidity", 0)
        
        if temp > 0 and ph > 0:
            # Trigger if fields are missing OR explicitly zero (likely uninitialized)
            if not r.get("do") or not r.get("nh3") or not r.get("do_status"):
                try:
                    _logger.info(f"Hydrating ML estimations for pond {r['pond_id']} (Temp={temp}, pH={ph})")
                    preds = predict_water_quality(temp, ph, turbidity)
                    r["do"] = r.get("do") or round(preds["do"], 2)
                    r["nh3"] = r.get("nh3") or round(preds["ammonia"], 4)
                    r["co2"] = r.get("co2") or round(preds["co2"], 2)
                    r["do_status"] = r.get("do_status") or preds["do_status"]
                    r["nh3_status"] = r.get("nh3_status") or preds["ammonia_status"]
                    r["prediction_source"] = r.get("prediction_source") or "ml_on_read"
                    _logger.info(f"Hydration SUCCESS for pond {r['pond_id']}: DO={r['do']}, NH3={r['nh3']}")
                except Exception as e:
                    _logger.error(f"Hydration FAILED for pond {r['pond_id']}: {e}")
                    pass # Keep original state if ML fails
        else:
            _logger.warning(f"Hydration skipped for pond {r.get('pond_id')} (Invalid raw data: Temp={temp}, pH={ph})")

    async def get_latest(self, pond_id: str) -> SensorReading | None:
        """Gets latest reading from sensor_readings collection. 
        If no data exists and pond has no device, returns zeroed reading.
        """
        query = self._get_pond_query(pond_id)
        latest = await sensor_readings_collection().find_one(
            query,
            sort=[("timestamp", -1)]
        )
        if latest:
            latest["id"] = str(latest.pop("_id"))
            
            # Map old field names if present for backward compatibility
            if "nh3" not in latest and "ammonia" in latest:
                latest["nh3"] = latest["ammonia"]
            if "do" not in latest and "dissolved_oxygen" in latest:
                latest["do"] = latest["dissolved_oxygen"]
            
            # Hydrate with ML if missing
            self._hydrate_reading(latest)
                
            return SensorReading(**latest)
        
        # Requirement: API must NEVER return null. Provide zeroed data if no history exists.
        return SensorReading(
            pond_id=pond_id,
            timestamp=datetime.utcnow(),
            temperature=0.0,
            ph=0.0,
            turbidity=0.0,
            light_intensity=0.0,
            water_level=0.0,
            do=0.0,
            nh3=0.0,
            co2=0.0
        )

    async def get_history(
        self,
        pond_id: str,
        start: datetime | None = None,
        end: datetime | None = None,
        limit: int = 200,
    ) -> list[SensorReading]:
        """Gets history from sensor_readings collection. No dummy fallback."""
        query = self._get_pond_query(pond_id)
        if start or end:
            query["timestamp"] = {}
            if start:
                query["timestamp"]["$gte"] = start
            if end:
                query["timestamp"]["$lte"] = end
        
        cursor = sensor_readings_collection().find(query).sort("timestamp", -1).limit(limit)
        results = await cursor.to_list(length=limit)
        
        readings = []
        for r in results:
            r["id"] = str(r.pop("_id"))
            # Map old field names if present for backward compatibility
            if "nh3" not in r and "ammonia" in r:
                r["nh3"] = r["ammonia"]
            if "do" not in r and "dissolved_oxygen" in r:
                r["do"] = r["dissolved_oxygen"]
            
            # Hydrate with ML if missing
            self._hydrate_reading(r)
            
            readings.append(SensorReading(**r))
        return readings

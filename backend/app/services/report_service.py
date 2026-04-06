from datetime import datetime
from app.db.mongo import reports_collection
from app.models.report import ReportInDB

class ReportService:
    async def generate_and_store(self, pond_id: str, user_id: str, sensor_snapshot: dict, alert_id: str = None):
        """Generates a summary report based on sensor data and predictions."""
        
        # Simple rule-based trend analysis (placeholders for more complex logic)
        analysis = "Water quality parameters are being monitored. "
        recommendations = ["Continue regular monitoring."]
        
        do = sensor_snapshot.get("dissolved_oxygen", 0)
        temp = sensor_snapshot.get("temperature", 0)
        
        if do < 5.0:
            analysis += "Critical low Dissolved Oxygen detected. "
            recommendations.append("Increase aeration immediately.")
            recommendations.append("Reduce feeding until DO stabilizes.")
            
        if temp > 32:
            analysis += "High water temperature may stress fish. "
            recommendations.append("Check pond shading or water exchange.")
            
        report = ReportInDB(
            pond_id=pond_id,
            user_id=user_id,
            sensor_snapshot=sensor_snapshot,
            trend_analysis=analysis,
            recommendations=recommendations,
            alert_id=alert_id
        )
        
        # FIX: exclude _id so MongoDB generates it automatically
        result = await reports_collection().insert_one(
            report.model_dump(by_alias=True, exclude={"_id", "id"})
        )
        
        return str(result.inserted_id)
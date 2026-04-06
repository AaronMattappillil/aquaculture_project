import json
import logging
import asyncio
import os
from datetime import datetime
import paho.mqtt.client as mqtt
from bson import ObjectId

from app.db.mongo import sensor_readings_collection, ponds_collection
from app.services.alert_service import AlertService
from app.models.pond import PondInDB
from app.ml.predictor import predict_water_quality

_logger = logging.getLogger(__name__)

class MQTTService:
    def __init__(self, loop: asyncio.AbstractEventLoop):
        self._loop = loop
        # Use callback API version 2 for paho-mqtt 2.0+
        self._client = mqtt.Client(callback_api_version=mqtt.CallbackAPIVersion.VERSION2)
        self._alert_service = AlertService()
        
        # Configuration from environment
        self._broker = os.getenv("MQTT_BROKER", "broker.hivemq.com")
        self._port = int(os.getenv("MQTT_PORT", 1883))
        self._keepalive = int(os.getenv("MQTT_KEEPALIVE", 60))
        self._username = os.getenv("MQTT_USERNAME")
        self._password = os.getenv("MQTT_PASSWORD")
        
        # Setup credentials if provided
        if self._username and self._password:
            self._client.username_pw_set(self._username, self._password)
            
        self._client.on_connect = self._on_connect
        self._client.on_message = self._on_message
        self._client.on_disconnect = self._on_disconnect
        
        # Enable automatic reconnection
        self._client.reconnect_delay_set(min_delay=1, max_delay=120)
        
    def start(self):
        """Starts the MQTT loop in a background thread."""
        try:
            _logger.info(f"Connecting to MQTT broker: {self._broker}:{self._port}")
            self._client.connect(self._broker, self._port, self._keepalive)
            self._client.loop_start()
            _logger.info("MQTT Client background loop started.")
        except Exception as e:
            _logger.error(f"MQTT connection failed: {e}")

    def stop(self):
        """Stops the MQTT loop."""
        try:
            self._client.loop_stop()
            self._client.disconnect()
            _logger.info("MQTT Client disconnected and loop stopped.")
        except Exception as e:
            _logger.error(f"Error during MQTT stop: {e}")

    def _on_connect(self, client, userdata, flags, rc, properties):
        """Callback for when the client receives a CONNACK response."""
        if rc == 0:
            _logger.info(f"Connected to MQTT broker at {self._broker}")
            # Subscribe to tank sensors topic
            topic = "aquaculture/pond/+/sensors"
            client.subscribe(topic)
            _logger.info(f"Subscribed to topic: {topic}")
        else:
            _logger.error(f"MQTT connection failed with result code {rc}")

    def _on_disconnect(self, client, userdata, disconnect_flags, rc, properties):
        """Callback for when the client disconnects from the broker."""
        if rc != 0:
            _logger.warning(f"Unexpected MQTT disconnection (rc={rc}). Will attempt to reconnect.")
        else:
            _logger.info("MQTT Client disconnected gracefully.")

    def _on_message(self, client, userdata, msg: mqtt.MQTTMessage):
        """Callback for when a PUBLISH message is received."""
        try:
            payload_str = msg.payload.decode()
            payload = json.loads(payload_str)
            _logger.debug(f"Received MQTT message on {msg.topic}")
            
            # 1. Validation & Extraction
            topic_parts = msg.topic.split("/")
            if len(topic_parts) < 3:
                _logger.warning(f"Invalid topic format: {msg.topic}")
                return
            
            pond_id = topic_parts[2]

            # Map fields to internal format
            temp = float(payload.get("temperature", 0))
            ph = float(payload.get("ph", 0))
            turbidity = float(payload.get("turbidity", 0))
            water_level = int(payload.get("water_level", 0))
            is_day = bool(payload.get("day", True))
            algae_detected = bool(payload.get("algae_detected", False))

            # 2. Predictive Fallback Logic (ML Integration)
            do_val = float(payload.get("do", 0))
            nh3_val = float(payload.get("ammonia", payload.get("nh3", 0)))
            co2_val = float(payload.get("co2", 0))
            do_status = "SAFE" # Default
            nh3_status = "SAFE"
            prediction_source = "hardware"

            if do_val <= 0 or nh3_val <= 0:
                try:
                    # ML model integration
                    preds = predict_water_quality(temp, ph, turbidity)
                    if do_val <= 0:
                        do_val = preds.get("do", 0)
                        do_status = preds.get("do_status", "SAFE")
                        prediction_source = "ml"
                    
                    if nh3_val <= 0:
                        nh3_val = preds.get("ammonia", 0)
                        nh3_status = preds.get("ammonia_status", "SAFE")
                        prediction_source = "ml"
                        
                    if co2_val <= 0:
                        co2_val = preds.get("co2", 0)
                        
                    _logger.debug(f"Applied ML estimations for pond {pond_id}")
                except Exception as e:
                    _logger.error(f"ML estimation failed: {e}")

            reading_doc = {
                "pond_id": pond_id,
                "temperature": temp,
                "ph": ph,
                "water_level": water_level,
                "turbidity": turbidity,
                "day": is_day,
                "algae_sensor": algae_detected,
                "do": round(do_val, 2),
                "nh3": round(nh3_val, 4),
                "co2": round(co2_val, 2),
                "do_status": do_status,
                "nh3_status": nh3_status,
                "prediction_source": prediction_source,
                "timestamp": datetime.fromisoformat(payload.get("timestamp")) if payload.get("timestamp") else datetime.utcnow()
            }
            
            # 3. Process in main loop
            if self._loop.is_running():
                asyncio.run_coroutine_threadsafe(
                    self._process_reading_async(reading_doc), 
                    self._loop
                )
            else:
                _logger.warning("Event loop is not running. Cannot process MQTT message.")
            
        except Exception as e:
            _logger.error(f"Failed to process MQTT message on {msg.topic}: {e}")

    async def _process_reading_async(self, reading: dict):
        """Asynchronous handler to save data and trigger alerts."""
        try:
            # Store in DB
            await sensor_readings_collection().insert_one(reading)
            _logger.debug(f"Stored MQTT sensor reading for pond {reading['pond_id']}")
            
            # Alert Logic
            pond_id = reading["pond_id"]
            if not ObjectId.is_valid(pond_id):
                return
                
            pond_doc = await ponds_collection().find_one({"_id": ObjectId(pond_id)})
            if not pond_doc:
                return
                
            pond = PondInDB(**pond_doc)
            
            alert_data = {
                "temperature": reading["temperature"],
                "ph": reading["ph"],
                "turbidity": reading["turbidity"],
                "do": reading["do"],
                "nh3": reading["nh3"],
                "co2": reading["co2"],
                "algae_detected": reading["algae_sensor"]
            }
            
            await self._alert_service.process_sensor_alerts(pond, alert_data)
            
        except Exception as e:
            _logger.error(f"Error in async MQTT processing: {e}")

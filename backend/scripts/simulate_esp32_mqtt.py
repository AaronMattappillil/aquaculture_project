import json
import time
import random
from datetime import datetime
import paho.mqtt.client as mqtt

# --- Configuration ---
BROKER = "broker.hivemq.com"
PORT = 1883
# Replace with a real pond UUID from your MongoDB if testing end-to-end
DEFAULT_POND_ID = "65fc1234567890abcdef1234" 
TOPIC_TEMPLATE = "aquaculture/tank1/sensors"

def on_connect(client, userdata, flags, rc, properties=None):
    if rc == 0:
        print(f"Connected to MQTT Broker at {BROKER}")
    else:
        print(f"Failed to connect, return code {rc}")

def simulate_esp32(pond_id=DEFAULT_POND_ID, interval_sec=10):
    """
    Simulates an ESP32 sampling sensors every 'interval_sec' seconds 
    and publishing the averaged/latest values to HiveMQ.
    """
    client = mqtt.Client(callback_api_version=mqtt.CallbackAPIVersion.VERSION2)
    client.on_connect = on_connect
    
    print(f"Connecting to {BROKER}...")
    client.connect(BROKER, PORT, 60)
    client.loop_start()

    topic = TOPIC_TEMPLATE
    print(f"Starting simulation for pond: {pond_id}")
    print(f"Publishing to: {topic}")
    print("Press Ctrl+C to stop.\n")

    try:
        while True:
            # Generate realistic sensor values
            payload = {
                "pond_id": pond_id,
                "temperature": round(27.0 + random.uniform(-0.5, 0.5), 2),
                "ph": round(7.2 + random.uniform(-0.1, 0.1), 2),
                "turbidity": round(10.0 + random.uniform(-2, 2), 1),
                "do": round(6.5 + random.uniform(-0.3, 0.3), 2),
                "ammonia": round(0.02 + random.uniform(0, 0.01), 3),
                "co2": round(5.0 + random.uniform(-0.2, 0.2), 2),
                "timestamp": datetime.utcnow().isoformat()
            }

            result = client.publish(topic, json.dumps(payload))
            status = result[0]
            if status == 0:
                print(f"[{datetime.now().strftime('%H:%M:%S')}] Sent: {payload['temperature']}°C, {payload['do']}mg/L DO")
            else:
                print(f"Failed to send message to topic {topic}")

            time.sleep(interval_sec)
            
    except KeyboardInterrupt:
        print("\nSimulation stopped.")
    finally:
        client.loop_stop()
        client.disconnect()

if __name__ == "__main__":
    import argparse
    parser = argparse.ArgumentParser()
    parser.add_argument("--pond_id", type=str, default=DEFAULT_POND_ID)
    parser.add_argument("--partial", action="store_true")
    args = parser.parse_args()
    
    simulate_esp32(pond_id=args.pond_id)

import os, json, time, signal, sys
from datetime import datetime, timezone
from paho.mqtt import client as mqtt
from pymodbus.client import ModbusSerialClient

SERIAL_PORT = os.getenv("PZEM_SERIAL", "/dev/ttyUSB0")
SLAVE_ID = int(os.getenv("PZEM_SLAVE_ID", "1"))
INTERVAL = float(os.getenv("PZEM_INTERVAL_SEC", "2"))
MQTT_HOST = os.getenv("MQTT_HOST", "mqtt")
MQTT_USER = os.getenv("MQTT_USER")
MQTT_PASS = os.getenv("MQTT_PASS")
MQTT_TOPIC = os.getenv("MQTT_TOPIC", "ac/pzem/metrics")

stop = False
def handle_stop(signum, frame):
    global stop
    stop = True

for s in (signal.SIGINT, signal.SIGTERM):
    signal.signal(s, handle_stop)

def mk_mqtt():
    c = mqtt.Client(client_id="pzem-reader", protocol=mqtt.MQTTv5)
    if MQTT_USER and MQTT_PASS:
        c.username_pw_set(MQTT_USER, MQTT_PASS)
    c.connect(MQTT_HOST, 1883, keepalive=30)
    c.loop_start()
    return c

def read_pzem(client):
    rr = client.read_input_registers(0x0000, 10, slave=SLAVE_ID)
    if rr.isError():
        raise RuntimeError(rr)
    r = rr.registers
    voltage = r[0] / 10.0
    current = (r[1] + (r[2] << 16)) / 1000.0
    power   = (r[3] + (r[4] << 16)) / 10.0
    pf      = r[8] / 100.0
    return voltage, current, power, pf

def main():
    mqttc = mk_mqtt()
    modbus = ModbusSerialClient(
        port=SERIAL_PORT,
        baudrate=9600,
        bytesize=8,
        parity="N",
        stopbits=1,
        timeout=1
    )
    if not modbus.connect():
        print("ERRO: não conectou no serial", file=sys.stderr)
        sys.exit(2)

    while not stop:
        try:
            v, i, p, pf = read_pzem(modbus)
            payload = {
                "ts": datetime.now(timezone.utc).isoformat(),
                "V_RMS": v,
                "I_RMS": i,
                "P": p,
                "PF": pf
            }
            mqttc.publish(MQTT_TOPIC, json.dumps(payload))
        except Exception as e:
            print(f"erro leitura/publicação: {e}", file=sys.stderr)
        time.sleep(INTERVAL)

    modbus.close()
    mqttc.loop_stop()

if __name__ == "__main__":
    main()

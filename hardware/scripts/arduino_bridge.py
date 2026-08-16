"""
Arduino Serial to WebSocket Bridge Script
===========================================
This script reads raw ECG serial data from Arduino USB (COM port)
and relays it over WebSocket to the Chagas Predict Flutter Web App.
"""

import sys
import subprocess

# Auto-install missing packages if needed
def ensure_dependencies():
    missing = []
    try:
        import serial
    except ImportError:
        missing.append("pyserial")

    try:
        import websockets
    except ImportError:
        missing.append("websockets")

    if missing:
        print(f"[Bridge Setup] Installing missing Python packages: {', '.join(missing)}...")
        subprocess.check_call([sys.executable, "-m", "pip", "install"] + missing)

ensure_dependencies()

import asyncio
import argparse
import serial
import websockets

CONNECTED_CLIENTS = set()

async def ws_handler(websocket, path):
    print(f"[WebSocket] Flutter App Connected from {websocket.remote_address}")
    CONNECTED_CLIENTS.add(websocket)
    try:
        await websocket.wait_closed()
    finally:
        CONNECTED_CLIENTS.remove(websocket)
        print("[WebSocket] Flutter App Disconnected")

async def read_serial_and_broadcast(com_port, baud_rate):
    while True:
        try:
            print(f"[Serial] Attempting to open {com_port} at {baud_rate} baud...")
            ser = serial.Serial(com_port, baud_rate, timeout=1)
            print(f"[Serial] 🟢 Successfully connected to Arduino on {com_port}!")
            
            while True:
                if ser.in_waiting > 0:
                    try:
                        line = ser.readline().decode('utf-8', errors='ignore').strip()
                        if line:
                            if CONNECTED_CLIENTS:
                                await asyncio.gather(*[client.send(line) for client in CONNECTED_CLIENTS], return_exceptions=True)
                    except Exception:
                        pass
                await asyncio.sleep(0.001)

        except serial.serialutil.SerialException as se:
            if "Access is denied" in str(se) or "PermissionError" in str(se):
                print(f"\n[⚠️ COM Port Locked] COM port {com_port} is currently locked by another application.")
                print(f"👉 SOLUTION: Please CLOSE the Serial Monitor / Serial Plotter inside Arduino IDE.")
                print(f"retrying connection in 3 seconds...\n")
            else:
                print(f"[Serial Error] Could not connect to {com_port}: {se}")
            await asyncio.sleep(3)
        except Exception as e:
            print(f"[Serial Error] Unexpected error on {com_port}: {e}")
            await asyncio.sleep(3)

async def main():
    parser = argparse.ArgumentParser(description="Arduino Serial to WebSocket Bridge")
    parser.add_argument("--port", default="COM3", help="Serial Port (e.g., COM3, COM4, /dev/ttyUSB0)")
    parser.add_argument("--baud", default=115200, type=int, help="Baud rate (default 115200)")
    parser.add_argument("--ws_port", default=8080, type=int, help="WebSocket Port (default 8080)")
    args = parser.parse_args()

    server = await websockets.serve(ws_handler, "localhost", args.ws_port)
    print(f"[Bridge Ready] WebSocket Server running on ws://localhost:{args.ws_port}")
    print(f"[Bridge Ready] Connected Arduino Port: {args.port} @ {args.baud} baud")

    await read_serial_and_broadcast(args.port, args.baud)

if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        print("\n[Bridge] Stopping server...")
        sys.exit(0)

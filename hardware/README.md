# Hardware & IoT AD8232 ECG Sensor Integration

This directory contains the firmware and python serial bridge for connecting real physical AD8232 Single-Lead ECG sensors to the Chagas Cardiomyopathy AI Prediction System.

## Architecture

- **`arduino_ecg_sensor/`**: Contains `arduino_ecg_sensor.ino` (Arduino firmware sketch).
- **`scripts/`**: Contains `arduino_bridge.py` (Real-time serial data streamer sending sampled ECG signals to FastAPI & Flutter over WebSockets / REST API).

## Setup & Flashing Instructions

1. Connect the **AD8232 ECG Sensor** module to your **Arduino UNO / ESP32**:
   - `OUTPUT` -> Analog Pin `A0`
   - `LO+` -> Digital Pin `10`
   - `LO-` -> Digital Pin `11`
   - `3.3V` -> `3.3V`
   - `GND` -> `GND`
2. Open `arduino_ecg_sensor/arduino_ecg_sensor.ino` in the Arduino IDE and flash to your microcontroller board.
3. Launch the Python serial bridge script:
   ```bash
   python scripts/arduino_bridge.py --port COM3 --baud 9600
   ```

/*
  Arduino AD8232 ECG Sensor Code for Chagas Predict Flutter App
  ==============================================================
  Hardware Setup:
  - AD8232 Sensor OUTPUT -> Arduino Pin A0
  - AD8232 Sensor LO+    -> Arduino Pin 10
  - AD8232 Sensor LO-    -> Arduino Pin 11
  - AD8232 3.3V & GND    -> Arduino 3.3V & GND
  
  Baud Rate: 115200 baud
  Sampling Rate: ~250 Hz (4ms delay)
*/

void setup() {
  // Initialize Serial Communication at 115200 baud
  Serial.begin(115200);
  
  // Set Lead-off detection pins as inputs
  pinMode(10, INPUT); // LO+
  pinMode(11, INPUT); // LO-
}

void loop() {
  // Check if ECG electrodes are properly attached
  if ((digitalRead(10) == 1) || (digitalRead(11) == 1)) {
    Serial.println("LEAD_OFF");
  } else {
    // Read raw analog voltage from AD8232 output pin A0 (0 to 1023)
    int sensorValue = analogRead(A0);
    
    // Print voltage reading to Serial stream
    Serial.println(sensorValue);
  }
  
  // 4ms delay = 250 Hz sample rate
  delay(4);
}

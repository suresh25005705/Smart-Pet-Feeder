#include <ESP32Servo.h>

Servo servo;

void setup() {
  servo.attach(18);
}

void loop() {
  servo.write(0);
  delay(2000);

  servo.write(90);
  delay(2000);
}

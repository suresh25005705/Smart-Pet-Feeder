const int button = 23;

void setup() {
  pinMode(button, INPUT_PULLUP);
  Serial.begin(115200);
}

void loop() {
  if (digitalRead(button) == LOW) {
    Serial.println("Pressed");
  }
}

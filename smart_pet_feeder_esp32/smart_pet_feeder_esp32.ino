#include <PubSubClient.h>

/*
  Smart Pet Feeder - ESP32 + HiveMQ Cloud
  MQTT topic: smartpetfeeder/feeder01/command

  Command:
    FEED

  When FEED is received, the servo opens the feeder and then returns.
*/

#include <WiFi.h>
#include <WiFiClientSecure.h>
#include <PubSubClient.h>
#include <ESP32Servo.h>

// =========================
// Wi-Fi SETTINGS
// =========================
const char* WIFI_SSID = "Suresh- 2.4G";
const char* WIFI_PASSWORD = "00112233";

// =========================
// HIVE-MQTT CLOUD SETTINGS
// =========================
const char* MQTT_BROKER = "e57b208c333749f9b9816d9fa9c6f79d.s1.eu.hivemq.cloud";
const int MQTT_PORT = 8883;

const char* MQTT_USERNAME = "test";
const char* MQTT_PASSWORD = "qwerty123";

const char* MQTT_TOPIC = "smartpetfeeder/feeder01/command";

// =========================
// SERVO SETTINGS
// =========================
// GPIO 18 is a common ESP32 PWM-capable pin.
// Change this if your wiring uses another GPIO.
const int SERVO_PIN = 18;

// Adjust these angles after testing your feeder mechanism.
const int SERVO_CLOSED_ANGLE = 0;
const int SERVO_OPEN_ANGLE = 90;

// Time the feeder remains open.
const unsigned long FEED_OPEN_TIME_MS = 1500;

// =========================
// OBJECTS
// =========================
WiFiClientSecure secureClient;
PubSubClient mqttClient(secureClient);
Servo feederServo;

// =========================
// FUNCTION DECLARATIONS
// =========================
void connectWiFi();
void connectMQTT();
void mqttCallback(char* topic, byte* payload, unsigned int length);
void feedNow();

// =========================
// SETUP
// =========================
void setup() {
  Serial.begin(9600);
  delay(1000);

  Serial.println();
  Serial.println("==============================");
  Serial.println("SMART PET FEEDER - ESP32");
  Serial.println("==============================");

  // Attach servo
  feederServo.setPeriodHertz(50);
  feederServo.attach(SERVO_PIN, 500, 2400);
  feederServo.write(SERVO_CLOSED_ANGLE);

  Serial.println("Servo initialized.");

  // Connect Wi-Fi
  connectWiFi();

  // HiveMQ Cloud uses TLS on port 8883.
  // This accepts the broker certificate without local CA setup.
  // For a student/demo project this keeps setup simple.
  secureClient.setInsecure();

  mqttClient.setServer(MQTT_BROKER, MQTT_PORT);
  mqttClient.setCallback(mqttCallback);
  mqttClient.setKeepAlive(30);
  mqttClient.setBufferSize(512);

  connectMQTT();
}

// =========================
// MAIN LOOP
// =========================
void loop() {
  if (WiFi.status() != WL_CONNECTED) {
    connectWiFi();
  }

  if (!mqttClient.connected()) {
    connectMQTT();
  }

  mqttClient.loop();
}

// =========================
// WIFI CONNECTION
// =========================
void connectWiFi() {
  Serial.println();
  Serial.println("==============================");
  Serial.println("Connecting to Wi-Fi");
  Serial.print("SSID: ");
  Serial.println(WIFI_SSID);

  WiFi.mode(WIFI_STA);
  WiFi.disconnect(true);
  delay(1000);

  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);

  Serial.print("Connecting");

  int attempts = 0;

  while (WiFi.status() != WL_CONNECTED && attempts < 40) {
    delay(500);
    Serial.print(".");
    attempts++;
  }

  Serial.println();

  if (WiFi.status() == WL_CONNECTED) {
    Serial.println("==============================");
    Serial.println("Wi-Fi CONNECTED!");
    Serial.print("IP address: ");
    Serial.println(WiFi.localIP());
    Serial.println("==============================");
  } else {
    Serial.println("==============================");
    Serial.println("Wi-Fi connection FAILED");
    Serial.print("Wi-Fi status: ");
    Serial.println(WiFi.status());
    Serial.println("==============================");
  }
}

// =========================
// MQTT CONNECTION
// =========================
void connectMQTT() {
  if (WiFi.status() != WL_CONNECTED) {
    return;
  }

  Serial.println();
  Serial.println("Connecting to HiveMQ Cloud...");

  // Generate a unique client ID.
  String clientId = "esp32_feeder_";
  clientId += String((uint32_t)ESP.getEfuseMac(), HEX);

  Serial.print("MQTT Client ID: ");
  Serial.println(clientId);

  if (mqttClient.connect(
        clientId.c_str(),
        MQTT_USERNAME,
        MQTT_PASSWORD)) {

    Serial.println("==============================");
    Serial.println("MQTT CONNECTED SUCCESSFULLY");
    Serial.println("==============================");

    if (mqttClient.subscribe(MQTT_TOPIC, 1)) {
      Serial.print("Subscribed to: ");
      Serial.println(MQTT_TOPIC);
    } else {
      Serial.println("MQTT subscription FAILED.");
    }

  } else {
    Serial.print("MQTT connection FAILED. State: ");
    Serial.println(mqttClient.state());

    delay(3000);
  }
}

// =========================
// MQTT MESSAGE RECEIVED
// =========================
void mqttCallback(char* topic, byte* payload, unsigned int length) {
  String message;

  for (unsigned int i = 0; i < length; i++) {
    message += (char)payload[i];
  }

  message.trim();

  Serial.println();
  Serial.println("==============================");
  Serial.println("MQTT MESSAGE RECEIVED");
  Serial.print("Topic: ");
  Serial.println(topic);
  Serial.print("Message: ");
  Serial.println(message);
  Serial.println("==============================");

  if (String(topic) == MQTT_TOPIC && message == "FEED") {
    feedNow();
  }
}

// =========================
// FEED ACTION
// =========================
void feedNow() {
  Serial.println("FEED COMMAND RECEIVED");
  Serial.println("Opening feeder...");

  feederServo.write(SERVO_OPEN_ANGLE);
  delay(FEED_OPEN_TIME_MS);

  Serial.println("Closing feeder...");

  feederServo.write(SERVO_CLOSED_ANGLE);
  delay(500);

  Serial.println("Feeding cycle complete.");
}

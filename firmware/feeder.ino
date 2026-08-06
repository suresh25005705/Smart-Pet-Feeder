/*
-------------------------------------------------------
Smart IoT Pet Feeder
ESP32 + Firebase + Servo
-------------------------------------------------------
*/

#include <WiFi.h>
#include <ESP32Servo.h>

#include <Firebase_ESP_Client.h>

#include <WiFiUdp.h>
#include <NTPClient.h>

// Firebase helper libraries
#include "addons/TokenHelper.h"
#include "addons/RTDBHelper.h"



//============================
// WiFi Credentials
//============================

#define WIFI_SSID "YOUR_WIFI_NAME"
#define WIFI_PASSWORD "YOUR_WIFI_PASSWORD"


//============================
// Firebase Credentials
//============================

#define API_KEY "YOUR_FIREBASE_API_KEY"

#define DATABASE_URL "https://YOUR_PROJECT.firebaseio.com/"


FirebaseData fbdo;
FirebaseAuth auth;
FirebaseConfig config;


//============================
// Pins
//============================

#define SERVO_PIN 18
#define BUTTON_PIN 23
#define LED_PIN 2
#define BUZZER_PIN 4

Servo feederServo;


//============================
// Time
//============================

WiFiUDP ntpUDP;

NTPClient timeClient(ntpUDP, "pool.ntp.org", 19800); // India UTC+5:30


//============================
// Feed Schedule
//============================

String feed1 = "08:00";
String feed2 = "14:00";
String feed3 = "20:00";

bool fedAlready = false;


//============================
// Feed Function
//============================

void dispenseFood()
{

  Serial.println("Dispensing Food...");

  digitalWrite(LED_PIN, HIGH);

  tone(BUZZER_PIN, 1000);

  feederServo.write(90);

  delay(2500);

  feederServo.write(0);

  noTone(BUZZER_PIN);

  digitalWrite(LED_PIN, LOW);

  Firebase.RTDB.pushString(
      &fbdo,
      "/history",
      timeClient.getFormattedTime());

  Serial.println("Done");
}



//============================
// WiFi
//============================

void connectWiFi()
{

  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);

  Serial.print("Connecting");

  while (WiFi.status() != WL_CONNECTED)
  {

    delay(500);

    Serial.print(".");
  }

  Serial.println();

  Serial.println("WiFi Connected");
}



//============================
// Setup
//============================

void setup()
{

  Serial.begin(115200);

  pinMode(BUTTON_PIN, INPUT_PULLUP);

  pinMode(LED_PIN, OUTPUT);

  pinMode(BUZZER_PIN, OUTPUT);

  feederServo.attach(SERVO_PIN);

  feederServo.write(0);

  connectWiFi();

  timeClient.begin();

  config.api_key = API_KEY;

  config.database_url = DATABASE_URL;

  Firebase.begin(&config, &auth);

  Firebase.reconnectWiFi(true);

}



//============================
// Check Schedule
//============================

void checkSchedule()
{

  String currentTime =
      timeClient.getFormattedTime().substring(0,5);

  if(currentTime == feed1 ||
     currentTime == feed2 ||
     currentTime == feed3)
  {

      if(!fedAlready)
      {

        dispenseFood();

        fedAlready = true;

      }

  }
  else
  {

      fedAlready = false;

  }

}



//============================
// Manual Button
//============================

void checkButton()
{

  if(digitalRead(BUTTON_PIN)==LOW)
  {

      dispenseFood();

      delay(1000);

  }

}



//============================
// Firebase Feed Command
//============================

void checkFirebase()
{

  if(Firebase.RTDB.getBool(&fbdo,"/feedNow"))
  {

      if(fbdo.boolData())
      {

          dispenseFood();

          Firebase.RTDB.setBool(
            &fbdo,
            "/feedNow",
            false);

      }

  }

}



//============================
// Main Loop
//============================

void loop()
{

  timeClient.update();

  checkSchedule();

  checkButton();

  checkFirebase();

  delay(200);

}

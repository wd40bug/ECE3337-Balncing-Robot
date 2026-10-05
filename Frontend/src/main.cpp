#include "Arduino.h"
#include "WebServer.h"
#include "WiFi.h"
#include "esp32-hal-gpio.h"

const uint8_t UP_PIN = 26;
const uint8_t DOWN_PIN = 25;
const uint8_t LEFT_PIN = 33;
const uint8_t RIGHT_PIN = 32;

const char *ssid = "BALANCING_ROBOT";
const char *password = "";

WebServer server(80);

String header;

extern const uint8_t index_html_start[] asm("_binary_index_html_start");
extern const uint8_t index_html_end[] asm("_binary_index_html_end");
const uint8_t index_html_size = index_html_end - index_html_start;

void setup() {
  Serial.begin(115200);
  while (!Serial){}
  Serial.println("ESP STARTING!");
  pinMode(UP_PIN, OUTPUT);
  pinMode(DOWN_PIN, OUTPUT);
  pinMode(LEFT_PIN, OUTPUT);
  pinMode(RIGHT_PIN, OUTPUT);

  digitalWrite(UP_PIN, LOW);
  digitalWrite(DOWN_PIN, LOW);
  digitalWrite(LEFT_PIN, LOW);
  digitalWrite(RIGHT_PIN, LOW);
  WiFi.softAP(ssid, password);
  IPAddress IP = WiFi.softAPIP();
  Serial.print("AP IP address: ");
  Serial.println(IP);
  Serial.println("\nConnected to WiFi!");
  server.on("/", []() {
    server.send(200, "text/html", (const char *)index_html_start);
  });
  server.on("/press/up", [](){
    digitalWrite(UP_PIN, HIGH);
    Serial.println("+UP");
    server.send(200);
  });
  server.on("/press/down", [](){
    digitalWrite(DOWN_PIN, HIGH);
    Serial.println("+DOWN");
    server.send(200);
  });
  server.on("/press/left", [](){
    digitalWrite(LEFT_PIN, HIGH);
    Serial.println("+LEFT");
    server.send(200);
  });
  server.on("/press/right", [](){
    digitalWrite(RIGHT_PIN, HIGH);
    Serial.println("+RIGHT");
    server.send(200);
  });
  server.on("/unpress/up", [](){
    digitalWrite(UP_PIN, LOW);
    Serial.println("-UP");
    server.send(200);
  });
  server.on("/unpress/down", [](){
    digitalWrite(DOWN_PIN, LOW);
    Serial.println("-DOWN");
    server.send(200);
  });
  server.on("/unpress/left", [](){
    digitalWrite(LEFT_PIN, LOW);
    Serial.println("-LEFT");
    server.send(200);
  });
  server.on("/unpress/right", [](){
    digitalWrite(RIGHT_PIN, LOW);
    Serial.println("-RIGHT");
    server.send(200);
  });

  server.begin();
}

void loop() {
  server.handleClient();
}

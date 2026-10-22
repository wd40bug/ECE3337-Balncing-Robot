#include "Arduino.h"
#include "ArduinoJson.h"
#include "ESPmDNS.h"
#include "HardwareSerial.h"
#include "WebServer.h"
#include "WiFi.h"
#include "esp32-hal-gpio.h"
#include "http_parser.h"

const char *ssid = "BALANCING_ROBOT";
const char *password = "";

WebServer server(80);

String header;

extern const uint8_t index_html_start[] asm("_binary_index_html_start");
extern const uint8_t index_html_end[] asm("_binary_index_html_end");
const uint8_t index_html_size = index_html_end - index_html_start;

const uint8_t CMD_ON = 0x01;
const uint8_t CMD_OFF = 0x02;
const uint8_t CMD_BTNDOWN = 0x03;
const uint8_t CMD_BTNUP = 0x04;
const uint8_t CMD_PIDS = 0x05;

const uint8_t BTN_UP = 1;
const uint8_t BTN_DOWN = 2;
const uint8_t BTN_LEFT = 3;
const uint8_t BTN_RIGHT = 4;


void setup() {
  Serial.begin(115200);
  while (!Serial) {
  }

  Serial2.begin(115200, SERIAL_8N1, 16, 17);
  while(!Serial2) {
  }

  Serial.println("ESP STARTING!");

  WiFi.softAP(ssid, password);
  IPAddress IP = WiFi.softAPIP();
  Serial.print("AP IP address: ");
  Serial.println(IP);
  Serial.println("\nConnected to WiFi!");

  if (!MDNS.begin("balancing")) {
    Serial.println("Error setting up MDNS!");
    while (1) {
      delay(1000);
    }
  }

  server.on("/", []() {
    server.send(200, "text/html", (const char *)index_html_start);
  });
  server.on("/press/up", []() {
    Serial2.write(CMD_BTNDOWN);
    Serial2.write(BTN_UP);
    Serial.println("+UP");
    server.send(200);
  });
  server.on("/press/down", []() {
    Serial2.write(CMD_BTNDOWN);
    Serial2.write(BTN_DOWN);
    Serial.println("+DOWN");
    server.send(200);
  });
  server.on("/press/left", []() {
    Serial2.write(CMD_BTNDOWN);
    Serial2.write(BTN_LEFT);
    Serial.println("+LEFT");
    server.send(200);
  });
  server.on("/press/right", []() {
    Serial2.write(CMD_BTNDOWN);
    Serial2.write(BTN_RIGHT);
    Serial.println("+RIGHT");
    server.send(200);
  });
  server.on("/unpress/up", []() {
    Serial2.write(CMD_BTNUP);
    Serial2.write(BTN_UP);
    Serial.println("-UP");
    server.send(200);
  });
  server.on("/unpress/down", []() {
    Serial2.write(CMD_BTNUP);
    Serial2.write(BTN_DOWN);
    Serial.println("-DOWN");
    server.send(200);
  });
  server.on("/unpress/left", []() {
    Serial2.write(CMD_BTNUP);
    Serial2.write(BTN_LEFT);
    Serial.println("-LEFT");
    server.send(200);
  });
  server.on("/unpress/right", []() {
    Serial2.write(CMD_BTNUP);
    Serial2.write(BTN_RIGHT);
    Serial.println("-RIGHT");
    server.send(200);
  });

  server.on("/off", []() {
    Serial.println("Turning Off");
    Serial2.write(CMD_OFF);
    server.send(200);
  });

  server.on("/on", []() {
    Serial.println("Turning On");
    Serial2.write(CMD_ON);
    server.send(200);
  });

  server.on("/setPID", HTTP_POST, []() {
    if (server.hasArg("plain") == false) {
      server.send(400, "application/json", "{\"error\":\"Body missing\"}");
      return;
    }

    // 2. Extract the raw string payload
    String body = server.arg("plain");
    Serial.println("Received body: " + body);

    // 3. Allocate the JSON Document (adjust capacity according to your JSON
    // size)
    JsonDocument doc;

    // 4. Deserialize the JSON string
    DeserializationError error = deserializeJson(doc, body);

    if (error) {
      Serial.print("deserializeJson() failed: ");
      Serial.println(error.c_str());
      server.send(400, "application/json", "{\"error\":\"Invalid JSON\"}");
      return;
    }

    uint16_t p_pitch = doc["pitch"]["P"];
    uint16_t i_pitch = doc["pitch"]["I"];
    uint16_t d_pitch = doc["pitch"]["D"];
    uint16_t s_pitch = doc["pitch"]["S"];

    uint16_t p_motor = doc["motor"]["P"];
    uint16_t i_motor = doc["motor"]["I"];
    uint16_t d_motor = doc["motor"]["D"];
    uint16_t s_motor = doc["motor"]["S"];

    // --- Print to serial to verify ---
    Serial.printf("Pitch - P: %u, I: %u, D: %u, S: %u\n", p_pitch, i_pitch,
                  d_pitch, s_pitch);
    Serial.printf("Motor - P: %u, I: %u, D: %u, S: %u\n", p_motor, i_motor,
                  d_motor, s_motor);

    auto send12BitPair = [](HardwareSerial& serial, uint16_t a, uint16_t b) -> void{
      a &= 0x0FFF;
      b &= 0xFFFF;
      
      serial.write((uint8_t)(a >> 4)); // Top byte of a
      serial.write((uint8_t)(a << 4) | (b >> 8)); // Bottom nibble of a, top nibble of b
      serial.write((uint8_t)(b & 0xFF)); // Bottom byte of b
    };

    Serial2.write(CMD_PIDS);
    send12BitPair(Serial2, p_pitch, i_pitch);
    send12BitPair(Serial2, d_pitch, s_pitch);
    send12BitPair(Serial2, p_motor, i_motor);
    send12BitPair(Serial2, d_motor, s_motor);
    server.send(200);
  });

  server.begin();
}

void loop() { server.handleClient(); }

#include "Arduino.h"
#include "ArduinoJson.h"
#include "AsyncWebSocket.h"
#include "ESPAsyncWebServer.h"
#include "ESPmDNS.h"
#include "LittleFS.h"
#include "WiFi.h"

const char *ssid = "BALANCING_ROBOT";
const char *password = "";

AsyncWebServer server(80);
AsyncWebSocket ws("/ws");

const uint8_t CMD_ON = 0x01;
const uint8_t CMD_OFF = 0x02;
const uint8_t CMD_BTNDOWN = 0x03;
const uint8_t CMD_BTNUP = 0x04;
const uint8_t CMD_PIDS = 0x05;

const uint8_t TIME_SIZE = 4;
const uint8_t PITCH_SIZE = 1;

const uint8_t TEL_PITCH = 0x01;
const uint8_t TEL_PITCH_SIZE = TIME_SIZE + PITCH_SIZE;
const size_t TEL_PITCH_TIME_IDX = 0;
const size_t TEL_PITCH_PITCH_IDX = TEL_PITCH_TIME_IDX + TIME_SIZE;

const uint8_t BTN_UP = 1;
const uint8_t BTN_DOWN = 2;
const uint8_t BTN_LEFT = 3;
const uint8_t BTN_RIGHT = 4;

void setup() {
  Serial.begin(115200);
  while (!Serial) {
  }

  Serial2.begin(115200, SERIAL_8N1, 16, 17);
  while (!Serial2) {
  }

  Serial.println("ESP STARTING!");

  if (!LittleFS.begin(true)) {
    Serial.println("An Error has occurred while mounting LittleFS");
    return;
  }

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

  server.serveStatic("/", LittleFS, "/").setDefaultFile("index.html");
  server.onNotFound([](AsyncWebServerRequest *request) {
    request->send(404, "text/plain", "PAGE NOT FOUND!");
  });
  server.on("/press/up", [](AsyncWebServerRequest *request) {
    Serial2.write(CMD_BTNDOWN);
    Serial2.write(BTN_UP);
    Serial.println("+UP");
    request->send(200);
  });
  server.on("/press/down", [](AsyncWebServerRequest *request) {
    Serial2.write(CMD_BTNDOWN);
    Serial2.write(BTN_DOWN);
    Serial.println("+DOWN");
    request->send(200);
  });
  server.on("/press/left", [](AsyncWebServerRequest *request) {
    Serial2.write(CMD_BTNDOWN);
    Serial2.write(BTN_LEFT);
    Serial.println("+LEFT");
    request->send(200);
  });
  server.on("/press/right", [](AsyncWebServerRequest *request) {
    Serial2.write(CMD_BTNDOWN);
    Serial2.write(BTN_RIGHT);
    Serial.println("+RIGHT");
    request->send(200);
  });
  server.on("/unpress/up", [](AsyncWebServerRequest *request) {
    Serial2.write(CMD_BTNUP);
    Serial2.write(BTN_UP);
    Serial.println("-UP");
    request->send(200);
  });
  server.on("/unpress/down", [](AsyncWebServerRequest *request) {
    Serial2.write(CMD_BTNUP);
    Serial2.write(BTN_DOWN);
    Serial.println("-DOWN");
    request->send(200);
  });
  server.on("/unpress/left", [](AsyncWebServerRequest *request) {
    Serial2.write(CMD_BTNUP);
    Serial2.write(BTN_LEFT);
    Serial.println("-LEFT");
    request->send(200);
  });
  server.on("/unpress/right", [](AsyncWebServerRequest *request) {
    Serial2.write(CMD_BTNUP);
    Serial2.write(BTN_RIGHT);
    Serial.println("-RIGHT");
    request->send(200);
  });

  server.on("/off", [](AsyncWebServerRequest *request) {
    Serial.println("Turning Off");
    Serial2.write(CMD_OFF);
    request->send(200);
  });

  server.on("/on", [](AsyncWebServerRequest *request) {
    Serial.println("Turning On");
    Serial2.write(CMD_ON);
    request->send(200);
  });

  server.on("/setPID", HTTP_POST, [](AsyncWebServerRequest *request) {
    if (request->hasArg("plain") == false) {
      request->send(400, "application/json", "{\"error\":\"Body missing\"}");
      return;
    }

    // 2. Extract the raw string payload
    String body = request->arg("plain");
    Serial.println("Received body: " + body);

    // 3. Allocate the JSON Document (adjust capacity according to your JSON
    // size)
    JsonDocument doc;

    // 4. Deserialize the JSON string
    DeserializationError error = deserializeJson(doc, body);

    if (error) {
      Serial.print("deserializeJson() failed: ");
      Serial.println(error.c_str());
      request->send(400, "application/json", "{\"error\":\"Invalid JSON\"}");
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

    auto send12BitPair = [](HardwareSerial &serial, uint16_t a,
                            uint16_t b) -> void {
      a &= 0x0FFF;
      b &= 0xFFFF;

      serial.write((uint8_t)(a >> 4)); // Top byte of a
      serial.write((uint8_t)(a << 4) |
                   (b >> 8));            // Bottom nibble of a, top nibble of b
      serial.write((uint8_t)(b & 0xFF)); // Bottom byte of b
    };

    Serial2.write(CMD_PIDS);
    send12BitPair(Serial2, p_pitch, i_pitch);
    send12BitPair(Serial2, d_pitch, s_pitch);
    send12BitPair(Serial2, p_motor, i_motor);
    send12BitPair(Serial2, d_motor, s_motor);
    request->send(200);
  });

  ws.onEvent([](AsyncWebSocket *socket, AsyncWebSocketClient *client,
                AwsEventType type, void *arg, uint8_t *data, size_t len) {
    switch (type) {
    case WS_EVT_CONNECT:
      Serial.printf("WebSocket client #%u connected from %s\n", client->id(),
                    client->remoteIP().toString().c_str());
      break;
    case WS_EVT_DISCONNECT:
      Serial.printf("WebSocket client #%u disconnected\n", client->id());
      break;
    case WS_EVT_DATA:
      // Handle incoming messages from the browser here if you need to send
      // commands back to the ESP32
      break;
    case WS_EVT_PONG:
    case WS_EVT_ERROR:
      break;
    }
  });

  server.addHandler(&ws);

  server.begin();
}

uint32_t to_u32_big_endian(const uint8_t bytes[4]) {
  return (static_cast<uint32_t>(bytes[0]) << 24) |
         (static_cast<uint32_t>(bytes[1]) << 16) |
         (static_cast<uint32_t>(bytes[2]) << 8) |
         (static_cast<uint32_t>(bytes[3]));
}

uint8_t command = 0;
size_t read_size = 0;
size_t read_counter = 0;
uint8_t read_buffer[10];

void loop() {
  ws.cleanupClients();
  while (Serial2.available()) {
    if (read_size == 0) {
      int read = Serial2.read();
      switch (read) {
      case TEL_PITCH:
        read_size = TEL_PITCH_SIZE;
        command = TEL_PITCH;
        break;
      default:
        Serial.printf("Unknown telemetry code: %d\n", read);
        read_size = 0;
        break;
      }
    } else {
      read_counter += Serial2.readBytes(read_buffer + read_counter,
                                        read_size - read_counter);
      if (read_counter == read_size) {
        JsonDocument doc;
        String JSONString;
        switch (command) {
        case TEL_PITCH:
          doc["time"] = to_u32_big_endian(read_buffer);
          doc["pitch"] = read_buffer[TEL_PITCH_PITCH_IDX];
          serializeJson(doc, JSONString);
          ws.textAll(JSONString);
          break;
        default:
          break;
        }
        read_size = 0;
        read_counter = 0;
      }
    }
  }
}

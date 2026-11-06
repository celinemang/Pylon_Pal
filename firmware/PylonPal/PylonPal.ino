// Pylon Pal — ESP32 firmware (BLE peripheral + WS2812B strip)
// Libraries: FastLED, ESP32 BLE Arduino (bundled with the esp32 board package).
//
// States (1 byte written to the characteristic):
//   0 IDLE        line color, very dim
//   1 APPROACHING bright pulse (1.5 Hz, smooth sine — never faster than 3 Hz)
//   2 STAND_ASIDE bright steady
//   3 BOARDING_OK calm green
//
// If BLE disconnects, the strip keeps showing IDLE so the demo never looks dead.

#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <FastLED.h>

// ---------- Configuration ----------
#define LED_PIN        5          // data pin (via 330 ohm resistor)
#define NUM_LEDS       60         // 60 LEDs/m * 1 m
#define LED_TYPE       WS2812B
#define COLOR_ORDER    GRB

// Metro line color. Placeholder blue; change to the real line color.
const CRGB LINE_COLOR = CRGB(0x00, 0x39, 0xA6);
const CRGB OK_COLOR   = CRGB(0x00, 0xC8, 0x50);   // calm green

const uint8_t  GLOBAL_BRIGHTNESS = 80;
const uint8_t  IDLE_LEVEL        = 20;    // 0-255 scale of LINE_COLOR
const float    PULSE_HZ          = 1.5f;  // must stay <= 3 Hz (accessibility)

#define SERVICE_UUID "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
#define CHAR_UUID    "beb5483e-36e1-4688-b7f5-ea07361b26a8"
#define DEVICE_NAME  "PylonPal"
// -----------------------------------

enum State : uint8_t { IDLE = 0, APPROACHING = 1, STAND_ASIDE = 2, BOARDING_OK = 3 };

CRGB leds[NUM_LEDS];
volatile uint8_t currentState = IDLE;
volatile bool connected = false;
volatile bool restartAdv = false;
uint32_t stateSince = 0;

void setState(uint8_t s) {
  if (s > BOARDING_OK) return;           // ignore invalid payloads
  currentState = s;
  stateSince = millis();
}

class ServerCb : public BLEServerCallbacks {
  void onConnect(BLEServer*) override { connected = true; }
  void onDisconnect(BLEServer*) override {
    connected = false;
    setState(IDLE);                      // never look dead
    restartAdv = true;
  }
};

class WriteCb : public BLECharacteristicCallbacks {
  void onWrite(BLECharacteristic* c) override {
    auto v = c->getValue();
    if (v.length() >= 1) setState((uint8_t)v[0]);
  }
};

void render() {
  switch (currentState) {
    case IDLE: {
      CRGB c = LINE_COLOR; c.nscale8(IDLE_LEVEL);
      fill_solid(leds, NUM_LEDS, c);
      break;
    }
    case APPROACHING: {
      // Smooth sine between ~15% and 100%, PULSE_HZ cycles per second.
      float t = (millis() - stateSince) / 1000.0f;
      float s = 0.5f * (1.0f + sinf(2.0f * PI * PULSE_HZ * t - PI / 2));
      uint8_t level = 40 + (uint8_t)(215.0f * s);
      CRGB c = LINE_COLOR; c.nscale8(level);
      fill_solid(leds, NUM_LEDS, c);
      break;
    }
    case STAND_ASIDE:
      fill_solid(leds, NUM_LEDS, LINE_COLOR);
      break;
    case BOARDING_OK:
      fill_solid(leds, NUM_LEDS, OK_COLOR);
      break;
  }
  FastLED.show();
}

void setup() {
  Serial.begin(115200);

  FastLED.addLeds<LED_TYPE, LED_PIN, COLOR_ORDER>(leds, NUM_LEDS);
  FastLED.setBrightness(GLOBAL_BRIGHTNESS);
  FastLED.setMaxPowerInVoltsAndMilliamps(5, 1500);
  setState(IDLE);
  render();

  BLEDevice::init(DEVICE_NAME);
  BLEServer* server = BLEDevice::createServer();
  server->setCallbacks(new ServerCb());
  BLEService* service = server->createService(SERVICE_UUID);
  BLECharacteristic* ch = service->createCharacteristic(
      CHAR_UUID, BLECharacteristic::PROPERTY_WRITE | BLECharacteristic::PROPERTY_WRITE_NR);
  ch->setCallbacks(new WriteCb());
  service->start();

  BLEAdvertising* adv = BLEDevice::getAdvertising();
  adv->addServiceUUID(SERVICE_UUID);
  adv->setScanResponse(true);
  BLEDevice::startAdvertising();
}

void loop() {
  if (restartAdv) {
    restartAdv = false;
    delay(300);
    BLEDevice::startAdvertising();
  }
  render();
  delay(16);   // ~60 fps; pulse itself is time-based
}

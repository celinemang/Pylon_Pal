# Pylon Pal

HRI 2027 Student Design Competition prototype: a pylon-shaped device inside a subway train that reminds waiting riders to let passengers exit first.

- `firmware/PylonPal/PylonPal.ino` — ESP32 BLE peripheral + WS2812B strip (Arduino, FastLED)
- `ios/` — iPad app (SwiftUI). Generate the project with `brew install xcodegen && cd ios && xcodegen generate`, then open `PylonPal.xcodeproj`.

## States
0 IDLE (dim line color) · 1 APPROACHING (1.5 Hz pulse) · 2 STAND_ASIDE (bright steady) · 3 BOARDING_OK (green).
No flashing faster than 3 Hz anywhere. If BLE drops, the strip keeps showing IDLE.

## Setup
**ESP32:** install the esp32 board package and the FastLED library, open the sketch, flash. Data pin is GPIO 5 (`LED_PIN`), 330 Ω in series, 1000 µF across 5V/GND.

**Pairing:**
1. Pair the Bluetooth speaker in iPad Settings → Bluetooth (A2DP).
2. Power the ESP32 and launch the app. It auto-connects to `PylonPal` over BLE (no manual pairing needed). Settings shows "PylonPal connected".

## Modes
Long-press the top-left corner (1.5 s) to open Settings.
- **Manual mode** (default): triple-tap bottom-right = advance one state; triple-tap bottom-left = run the full sequence (APPROACHING → STAND_ASIDE → BOARDING_OK → IDLE).
- **Motion mode:** not implemented yet (planned step 3: Core Motion + CSV logging, thresholds tuned from real train data).

## Change line color
- Strip: edit `LINE_COLOR` in `PylonPal.ino` and reflash.
- Screen: Settings → "Screen line color (hex)".
Both default to placeholder blue `#0039A6`.

## Change language
Settings → Audio language (English, Español, 中文, Français). Add recordings as `ios/PylonPal/Resources/Audio/message_en|es|zh|fr.mp3` (m4a/wav also work); without them the app uses speech synthesis.

## Robustness
Auto-lock is disabled while the app runs; a near-silent audio loop keeps the speaker awake. Works with Guided Access.

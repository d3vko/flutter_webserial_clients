---
name: marauder-webserial
description: Build and refactor Flutter Web clients for ESP32 Marauder badges (Badge Pwnterrey 2026) with bidirectional Web Serial, terminal CLI, Wigle wardrive, GPS, SPIFFS, NFC, and workflows.
license: MIT
compatibility: Flutter 3.44.4 stable, Dart 3.12.2 stable, Flutter Web, Chrome/Chromium/Edge desktop.
---

# Marauder WebSerial Skill

Use this skill when working on **ESP32 Marauder** clients — especially **Badge Pwnterrey 2026** — in `webserial_flutter_clients`.

## When to use

- Bidirectional serial (send CLI commands + read terminal output)
- Wardrive WigleWifi parsing (`wardrive -serial`)
- GPS telemetry, WiFi AP / BLE tables, SPIFFS storage, NFC emulator commands
- Workflows and system utilities
- Upload with `device_source=pwnterrey marauder`
- Route `/pwnterrey-marauder` and `lib/features/marauder/`

## ESP32-C5 limitations

- **BLE TX:** `blespam`, `spoofat` — supported
- **BLE RX:** `sniffbt`, `btwardrive` — **not available** (single-core); disable in UI with tooltip
- **Wardrive:** use `wardrive -serial`, not bare `wardrive`
- **NFC:** NT3H2111 **tag emulator** — `nfc scan|read|-u|-t|-v|-w`; not a Mifare reader

Official refs: [badge-pwnterrey-2026](https://github.com/ElectronicCats/badge-pwnterrey-2026), [pwnterrey-2026_Firmware](https://github.com/ElectronicCats/pwnterrey-2026_Firmware)

## Difference from `flutter-webserial` skill

| Aspect | LilyGO (`flutter-webserial`) | Marauder (`marauder-webserial`) |
|--------|------------------------------|----------------------------------|
| Serial | Read-only | Read + write (`sendCommand`, `sendRaw`) |
| Protocol | CSV LTE/WiFi/BLE lines | Marauder CLI + WiGLE wardrive rows |
| UI | `WardrivePage` | `MarauderPage` (sidebar + view tabs) |
| Profile | `AppKind.wardriving` | `AppKind.marauder` |

## Key files

```text
lib/features/marauder/
  domain/
    gps_parser.dart
    wifi_ap_parser.dart
    ble_device_parser.dart
    spiffs_parser.dart
    nfc_commands.dart
    marauder_workflows.dart
    wardrive_parser.dart
    wardrive_csv.dart
  presentation/
    marauder_controller.dart   # _processLine routing, SPIFFS, workflows
    marauder_page.dart
    widgets/
      view_tabs.dart, gps_panel.dart, wifi_ap_table.dart
      ble_device_table.dart, storage_panel.dart, nfc_panel.dart
      system_utilities_panel.dart, workflow_dialog.dart
      command_builder.dart, terminal_panel.dart, wardrive_panel.dart
lib/core/config/device_profile.dart   # DeviceProfile.pwnterreyMarauder
lib/features/serial/domain/serial_client.dart
```

## Reference docs and Vue sources

- [`docs/marauder_ui_pro_logic.md`](../../../docs/marauder_ui_pro_logic.md) — hardware matrix, UI↔command table
- Vue reference: `marauder-ui-pro/src/App.vue`, `GpsPanel.vue`, `StoragePanel.vue`, `CommandBuilder.vue`

## Constraints

- Web Serial connection must be triggered by user gesture (button click).
- Use `localhost` in dev; HTTPS in production.
- Never hard-code API tokens; use `--dart-define=WARDRIVE_*` URLs.
- Reuse `wardrive-auth` localStorage key for platform JWT compatibility.
- Protect `/settings.json` on SPIFFS delete.

## Quality gates

```bash
dart format .
dart analyze
flutter test
flutter build web
```

Tests: `test/gps_parser_test.dart`, `test/wifi_ap_parser_test.dart`, `test/spiffs_parser_test.dart`, `test/nfc_commands_test.dart`, `test/marauder_wardrive_parser_test.dart`.

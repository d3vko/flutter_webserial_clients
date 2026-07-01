---
name: magspoof-webserial
description: Build and refactor Flutter Web clients for MagSpoof V5 (Electronic Cats) with bidirectional Web Serial, ISO 7813 track parsing, and local CSV export.
license: MIT
compatibility: Flutter 3.44.4 stable, Dart 3.12.2 stable, Flutter Web, Chrome/Chromium/Edge desktop.
---

# MagSpoof WebSerial Skill

Use this skill when working on **MagSpoof V5** clients in `webserial_flutter_clients`.

## When to use

- Bidirectional serial (send firmware commands + read terminal output)
- ISO 7813 magnetic track parsing (Track 1 / Track 2)
- Route `/magspoof-v5` and `lib/features/magspoof/`
- Local CSV export (masked / full) — no platform upload

## Difference from other skills

| Aspect | LilyGO (`flutter-webserial`) | Marauder (`marauder-webserial`) | MagSpoof (`magspoof-webserial`) |
|--------|------------------------------|----------------------------------|----------------------------------|
| Serial | Read-only | Read + write | Read + write |
| Protocol | CSV LTE/WiFi/BLE | Marauder CLI + WiGLE | Firmware commands + ISO 7813 tracks |
| Backend | Optional JWT upload | JWT upload | None |
| Default baud | 115200 | 115200 | 9600 |

## Key files

```text
lib/features/magspoof/
  domain/magspoof_commands.dart
  domain/track_parser.dart
  domain/group_tracks.dart
  domain/track_csv.dart
  presentation/magspoof_controller.dart
  presentation/magspoof_page.dart
lib/core/config/device_profile.dart   # DeviceProfile.magspoofV5
lib/features/serial/domain/serial_client.dart  # write(), sendCommand()
```

## Reference docs and Vue sources

- [`docs/magspoof_v5_logic.md`](../../../docs/magspoof_v5_logic.md)
- Vue reference: `magspoof_ec_clasic_webclient/src/services/webSerial.js`, `utils/trackParser.js`

## Constraints

- Web Serial connection must be triggered by user gesture (button click).
- Use `localhost` in dev; HTTPS in production.
- Do not mix track parsing with LilyGO `serial_parser.dart` or Marauder `wardrive_parser.dart`.
- No `device_source` or `--dart-define=WARDRIVE_*` for MagSpoof.

## Quality gates

```bash
dart format .
dart analyze
flutter test
flutter build web
```

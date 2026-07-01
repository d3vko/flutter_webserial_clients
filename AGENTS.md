# AGENTS.md — Flutter WebSerial Gateway

## Documentation

- Development (ES): [`docs/DEVELOPMENT.md`](docs/DEVELOPMENT.md)
- Security policy (EN): [`docs/SECURITY.md`](docs/SECURITY.md)
- Upload classification: [`docs/DEVICE_SOURCES.md`](docs/DEVICE_SOURCES.md)

Run `./scripts/check-secrets.sh` before committing.

## Environment baseline

Assume Flutter 3.44.4 stable and Dart 3.12.2 stable are already installed on CachyOS/Arch Linux.
Do not add installation steps unless explicitly requested.

## Mission

Build Flutter apps that connect to serial devices in Flutter Web, parse emitted frames, and forward normalized events to third-party APIs over HTTP or WebSocket.

## Hard constraints

- Keep Web Serial code isolated behind `SerialClient` and conditional imports.
- Never import web-only libraries outside web-specific data layer files.
- Use Chrome/Chromium/Edge desktop, HTTPS or localhost, and a user gesture for connection.
- Do not store API tokens in source code. Use `--dart-define`, environment-specific config, or a secure backend.
- Model serial data as typed domain objects before forwarding.
- Keep colors in `lib/core/theme/app_colors.dart` and assets under `assets/`.

## Feature skills

- `flutter-webserial` — LilyGO wardriving (read-only serial)
- `marauder-webserial` — Badge Pwnterrey / ESP32 Marauder CLI
- `magspoof-webserial` — MagSpoof V5 tracks magnéticos ISO 7813

## Quality gates

```bash
flutter format .
flutter analyze
flutter test
flutter build web
flutter build apk --debug
```

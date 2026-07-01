---
name: flutter-webserial
description: Build and refactor Flutter apps that use Web Serial on Flutter Web, normalize serial frames, and forward them to third-party APIs over HTTP or WebSocket.
license: MIT
compatibility: Flutter 3.44.4 stable, Dart 3.12.2 stable, Flutter Web, Android, Chrome/Chromium/Edge desktop, CachyOS/Arch Linux CLI workflows.
---

# Flutter WebSerial Skill

Use this skill when asked to create, debug, or refactor Flutter apps that connect to serial devices from the browser and resend data to third-party APIs.

## Current environment assumption

Flutter and Dart are already installed:

```text
Flutter 3.44.4 stable
Dart 3.12.2 stable
DevTools 2.57.0
CachyOS / Arch Linux
```

Do not provide installation steps unless the user explicitly asks for them.

## Core workflow

1. Confirm target platform:
   - Web Serial: Flutter Web only.
   - Native Android/iOS: use a separate native serial/BLE/USB abstraction.
2. Keep serial code behind a `SerialClient` interface.
3. Use conditional imports so mobile builds do not import web-only libraries.
4. Parse raw serial bytes into `SerialFrame` or stronger domain objects.
5. Forward normalized data via `http` or `web_socket_channel`.
6. Use centralized theme files for colors and `assets/` for visual resources.
7. Verify with `flutter format .`, `flutter analyze`, `flutter test`, and target builds.

## Web Serial constraints

- Connection must be triggered by a user gesture.
- Development should run on `localhost`; production must use HTTPS.
- Handle disconnects, reader cancellation, writer lock release, and reconnect attempts.
- Keep browser compatibility warnings visible in the UI.
- Never let web-only imports leak into mobile-safe files.

## Forwarding patterns

- HTTP: POST JSON payloads with `content-type: application/json`.
- WebSocket: send normalized JSON events and handle reconnects/backpressure when productionizing.
- For protected third-party APIs, prefer a backend proxy rather than embedding secrets in Flutter Web.

## Security

- Never hard-code third-party API secrets in Flutter Web.
- Prefer a backend proxy for protected APIs.
- Validate payload shape before forwarding.
- Log failures without leaking tokens or PII.

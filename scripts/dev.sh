#!/usr/bin/env bash
set -Eeuo pipefail

cd "$(dirname "$0")/.."

flutter pub get
flutter run -d chrome \
  --web-hostname=localhost \
  --web-port=8085 \
  "$@"

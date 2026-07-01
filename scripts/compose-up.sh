#!/usr/bin/env bash
set -Eeuo pipefail

cd "$(dirname "$0")/.."

if [[ ! -f .env ]]; then
  cp .env.example .env
  echo "Created .env from .env.example — edit WARDRIVE_* URLs before production use."
fi

if command -v podman-compose >/dev/null 2>&1; then
  exec podman-compose up --build -d "$@"
elif command -v docker >/dev/null 2>&1 && docker compose version >/dev/null 2>&1; then
  exec docker compose up --build -d "$@"
elif command -v docker-compose >/dev/null 2>&1; then
  exec docker-compose up --build -d "$@"
else
  echo "Error: install podman-compose or docker compose." >&2
  exit 1
fi

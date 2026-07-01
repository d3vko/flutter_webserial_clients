#!/usr/bin/env bash
# Force a fresh Flutter web image on homelab/NUC (no stale Docker or browser/proxy cache).
set -Eeuo pipefail

cd "$(dirname "$0")/.."

echo "==> Stopping container (if running)"
if command -v podman-compose >/dev/null 2>&1; then
  COMPOSE=(podman-compose)
elif command -v docker >/dev/null 2>&1 && docker compose version >/dev/null 2>&1; then
  COMPOSE=(docker compose)
elif command -v docker-compose >/dev/null 2>&1; then
  COMPOSE=(docker-compose)
else
  echo "Error: install podman-compose or docker compose." >&2
  exit 1
fi

"${COMPOSE[@]}" down --remove-orphans 2>/dev/null || true

echo "==> Rebuilding image without cache"
"${COMPOSE[@]}" build --no-cache --pull

echo "==> Starting container"
"${COMPOSE[@]}" up -d --force-recreate

PORT="${HOST_PORT:-8090}"
echo ""
echo "Deployed. Verify headers (should show no-store):"
echo "  curl -sI http://127.0.0.1:${PORT}/main.dart.js | grep -i cache-control"
echo "  curl -sI http://127.0.0.1:${PORT}/assets/AssetManifest.bin.json | grep -i cache-control"
echo ""
echo "If the browser still shows an old UI, purge reverse-proxy cache (NPM/Traefik/Caddy) or hard-refresh (Ctrl+Shift+R)."

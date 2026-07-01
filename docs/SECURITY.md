# Security Policy — RF Village MX Web Serial Clients

This document describes security expectations for the Flutter Web client, deployment, and responsible use.

## Threat model

| Threat | Impact | Mitigation |
|--------|--------|------------|
| XSS on app origin | JWT theft from `localStorage` (`wardrive-auth`) | CSP headers (nginx), avoid injecting untrusted HTML, keep dependencies updated |
| Secret leakage in git | API exposure, account compromise | `.gitignore`, `check-secrets.sh`, never commit `.env` |
| Secret leakage in Docker image | URLs/tokens baked into layers | Use build args from `.env`, do not embed credentials in source |
| MITM without TLS | Token and CSV interception | HTTPS in production; HSTS at reverse proxy |
| Unauthorized wardriving | Legal and ethical harm | Prohibited use policy below; user gesture for serial |

## Secrets handling

**Never commit:**

- `.env`, `.env.local`, or any file with real API URLs containing credentials
- Private keys (`*.pem`, `*.key`, `*.p12`)
- JWT tokens, passwords, or `credentials.json`

**Do commit:**

- [`.env.example`](../.env.example) with placeholder URLs only

**Build-time configuration:**

- `WARDRIVE_*` URLs are embedded at **build time** via `--dart-define` (Flutter) or Docker build args.
- Changing `.env` requires **rebuilding** the image; restarting the container is not enough.

**Pre-commit check:**

```bash
./scripts/check-secrets.sh
```

## Authentication

- Login uses JWT (`access` + `refresh`) from the wardriving backend.
- Tokens are stored in **`localStorage`** under key `wardrive-auth` (shared by wardriving and marauder on the same origin).
- Logout clears storage.
- On HTTP 401 during upload, the client attempts token refresh once, then fails closed.

**Implication:** Any XSS on this origin can exfiltrate tokens. Treat UI input from serial streams as untrusted data; do not use `innerHTML` or eval on raw device output.

## Transport and Web Serial

- **Production:** serve over **HTTPS** (terminate TLS at nginx or reverse proxy).
- **Development:** `localhost` is a [secure context](https://developer.mozilla.org/en-US/docs/Web/Security/Secure_Contexts) for Web Serial.
- Serving over plain HTTP on a LAN IP may **block Web Serial** in Chrome/Edge.
- Web Serial requires a **user gesture** to connect; do not auto-connect on page load.

## nginx security headers

Production [`docker/nginx.conf`](../docker/nginx.conf) sets:

| Header | Purpose |
|--------|---------|
| `X-Content-Type-Options: nosniff` | Prevent MIME sniffing |
| `X-Frame-Options: DENY` | Clickjacking protection |
| `Referrer-Policy: strict-origin-when-cross-origin` | Limit referrer leakage |
| `Permissions-Policy: serial=(self)` | Restrict Web Serial to same origin |
| `Content-Security-Policy` | Restrict script/style/load sources |

**CSP note:** Flutter Web requires `'unsafe-eval'` and `'wasm-unsafe-eval'` for WASM compilation. This is a known trade-off documented here; do not remove without testing the full app bootstrap.

**CanvasKit CDN:** The default `flutter build web` output loads CanvasKit from `https://www.gstatic.com` at runtime. The CSP therefore allows that origin in `script-src` (for `canvaskit.js`) and `connect-src` (for `canvaskit.wasm` and related assets). Clients must reach `www.gstatic.com`; if the CDN is blocked (corporate firewall, offline use), the app will not render.

**MapLibre / map tiles:** Wardriving maps load MapLibre GL JS from `https://unpkg.com` (`web/index.html`) and fetch styles/tiles from HTTPS hosts such as `americanamap.org`, `tiles.openstreetmap.us`, or `tiles.openfreemap.org`. The CSP allows those origins. If the map works on `http://IP:8090` but fails behind a reverse proxy, check: (1) proxy cache serving an old build that still used `tile.openstreetmap.org`, (2) a stricter CSP added by the proxy, (3) subpath deployment without matching `--base-href`.

**Stricter CSP alternative:** Bundle CanvasKit in the image instead of using the CDN by adding `--no-web-resources-cdn` to the `flutter build web` command in the [`Dockerfile`](../Dockerfile). Then you can remove `https://www.gstatic.com` from the CSP and serve everything from `'self'` only (at the cost of a larger image).

## Docker

- [`.dockerignore`](../.dockerignore) excludes `.env` and secrets from build context.
- Do not publish images built with production API keys to public registries.
- Use `docker-compose.override.yml` for local experiments (gitignored).

## Dependencies

- Review [`pubspec.lock`](../pubspec.lock) when upgrading packages.
- Run `flutter pub outdated` periodically.
- Prefer well-maintained packages for HTTP (`http`) and routing (`go_router`).

## Prohibited use

This software is intended for **authorized** security research, education, and legitimate RF/serial device interaction.

**Do not use** this client to:

- Access networks or devices without explicit permission
- Upload data you are not authorized to collect
- Bypass authentication or rate limits on third-party APIs
- Violate applicable laws (telecommunications, computer fraud, privacy)

Users are responsible for compliance with local regulations.

## Responsible disclosure

If you discover a security vulnerability in this project:

1. **Do not** open a public issue with exploit details.
2. Report privately to the repository maintainer (RF Village / project owner).
3. Include: affected component, reproduction steps, impact assessment, and suggested fix if available.

We aim to acknowledge reports within 7 days and provide a remediation timeline when applicable.

## Related documentation

- Development guide (Spanish): [`DEVELOPMENT.md`](DEVELOPMENT.md)
- Upload classification: [`DEVICE_SOURCES.md`](DEVICE_SOURCES.md)
- Agent constraints: [`AGENTS.md`](../AGENTS.md)

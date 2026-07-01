# RF Village MX — Web Serial Clients

Cliente Flutter Web multi-ruta vía **Web Serial API** para hardware RF Village / Electronic Cats.

| Ruta | Hardware | Modo |
|------|----------|------|
| `/` | Hub | Selector de dispositivos |
| `/tsim7000g` | LilyGO TSIM7000G | Wardriving (solo lectura) |
| `/tsim7600hg` | LilyGO TSIM7600H-G 16 MB | Wardriving (filtros USB) |
| `/pwnterrey-marauder` | Badge Pwnterrey 2026 | Marauder CLI (serial bidireccional) |
| `/magspoof-v5` | MagSpoof V5 | Tracks magnéticos ISO 7813 |

## Documentación

| Documento | Idioma | Contenido |
|-----------|--------|-----------|
| [docs/DEVELOPMENT.md](docs/DEVELOPMENT.md) | ES | Cómo continuar el desarrollo, estructura, tests, Docker |
| [docs/SECURITY.md](docs/SECURITY.md) | EN | Política de seguridad, threat model, headers nginx |
| [docs/DEVICE_SOURCES.md](docs/DEVICE_SOURCES.md) | ES | Clasificación `device_source` por ruta en uploads |
| [AGENTS.md](AGENTS.md) | EN | Restricciones para agentes IA |

## Requisitos

- Flutter 3.44+ (Dart 3.12+)
- Chrome o Edge con soporte Web Serial
- Origen seguro: **localhost** en desarrollo; **HTTPS** en producción

## Desarrollo

```bash
chmod +x scripts/dev.sh
./scripts/dev.sh
```

Abre `http://localhost:8085`.

Backend opcional (`--dart-define=WARDRIVE_*`): ver [docs/DEVELOPMENT.md](docs/DEVELOPMENT.md#backend-opcional-auth--upload).

MagSpoof V5 no requiere URLs de backend (solo export CSV local).

## Producción con Podman/Docker

```bash
cp .env.example .env   # editar WARDRIVE_* según tu API
chmod +x scripts/compose-up.sh
./scripts/compose-up.sh
```

App en `http://localhost:8090`. Tras cambiar `.env`, reconstruir con `--build`.

Variables: [`.env.example`](.env.example). Clasificación de uploads: [docs/DEVICE_SOURCES.md](docs/DEVICE_SOURCES.md).

## Validación

```bash
dart format .
dart analyze
flutter test
flutter build web
./scripts/check-secrets.sh
```

## Arquitectura

```text
lib/
  core/config/          # DeviceProfile, WardriveConfig, BrandingConfig
  features/
    serial/             # WebSerialClient
    wardriving/         # LilyGO
    marauder/           # Badge Pwnterrey
    magspoof/           # MagSpoof V5
  routing/              # go_router
```

## Limitaciones

- Web Serial solo en Flutter Web (stub en otros targets).
- Conexión serial requiere clic del usuario.
- Upload requiere URLs configuradas y sesión JWT.
- Web Serial en HTTP remoto (IP LAN) puede estar bloqueado; usar HTTPS o localhost.

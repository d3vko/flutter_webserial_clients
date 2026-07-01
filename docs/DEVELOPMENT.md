# Guía de desarrollo — RF Village MX Web Serial Clients

Documentación para continuar el desarrollo del cliente Flutter Web standalone.

## Requisitos

- Flutter 3.44+ (Dart 3.12+)
- Chrome o Edge con soporte **Web Serial**
- Opcional: Podman/Docker para despliegue en contenedor

Origen seguro: **localhost** en desarrollo; **HTTPS** en producción remota.

## Arranque rápido

```bash
chmod +x scripts/dev.sh
./scripts/dev.sh
```

Abre `http://localhost:8085`. El hub está en `/`.

### Backend opcional (auth + upload)

```bash
flutter run -d chrome --web-port=8085 \
  --dart-define=WARDRIVE_LOGIN_URL=https://api.example.com/v1/auth/login/ \
  --dart-define=WARDRIVE_REGISTER_URL=https://api.example.com/v1/auth/register/ \
  --dart-define=WARDRIVE_RESET_URL=https://api.example.com/v1/auth/password/reset/ \
  --dart-define=WARDRIVE_UPLOAD_URL=https://api.example.com/v1/files-uploaded/ \
  --dart-define=WARDRIVE_TOKEN_REFRESH_URL=https://api.example.com/v1/auth/token/refresh/
```

Sin URLs configuradas, serial y export CSV local funcionan sin login.

## Estructura del código

```text
lib/
  app.dart                 # MaterialApp + tema
  routing/app_router.dart  # go_router (hub + rutas de dispositivo)
  core/
    config/                # DeviceProfile, WardriveConfig, BrandingConfig
    layout/                # AppBreakpoints
    theme/                 # AppTheme, colores, gradientes
    widgets/               # RfVillageLogo, SiteCreditFooter
  features/
    serial/                # WebSerialClient (imports condicionales)
    wardriving/            # LilyGO TSIM7000G / TSIM7600H-G
    marauder/              # Badge Pwnterrey Marauder
    magspoof/              # MagSpoof V5
test/                      # Tests unitarios de parsers y UI
assets/branding/           # Logos e iconos
web/                       # index.html, manifest, favicon
docker/                    # nginx.conf para producción
scripts/                   # dev.sh, compose-up.sh, check-secrets.sh
docs/                      # Esta documentación
```

## Añadir un dispositivo nuevo

1. **`lib/core/config/device_profile.dart`** — Crear un `DeviceProfile` con `id`, `routePath`, `title`, `appKind`, `deviceSource*` y baud rate.
2. **`lib/routing/app_router.dart`** — Registrar `GoRoute` con la página correspondiente.
3. **`lib/features/wardriving/presentation/device_selector_page.dart`** — El hub lista perfiles vía `DeviceProfile.forKind()`; no requiere cambio si el `appKind` es correcto.
4. **Feature** — Implementar página en `lib/features/<familia>/presentation/`.
5. **Tests** — Añadir tests de parser/UI en `test/`.
6. **Documentación** — Actualizar [`DEVICE_SOURCES.md`](DEVICE_SOURCES.md) si hay upload al backend.

## Branding

Icono del AppBar y logo del hub se configuran en [`lib/core/config/branding_config.dart`](../lib/core/config/branding_config.dart):

```dart
static const appBarIconAsset =
    'assets/branding/rf_village_mx_icon_v1_transparent.png';
```

Tras cambiar assets: **hot restart** (no hot reload).

## Backend y clasificación de uploads

- Variables de entorno: ver [`.env.example`](../.env.example) (Docker) o `--dart-define` (dev).
- Tabla `device_source` por ruta: [`DEVICE_SOURCES.md`](DEVICE_SOURCES.md).
- Auth JWT compartida entre wardriving y marauder (`localStorage`, clave `wardrive-auth`).

## Producción (Docker / Podman)

```bash
cp .env.example .env
./scripts/compose-up.sh
```

App en `http://localhost:8090`. Tras cambiar `.env`, reconstruir con `--build`.

El [`Dockerfile`](../Dockerfile) instala Flutter **3.44.4** desde git (Dart ≥3.12.2). Las imágenes `ghcr.io/cirruslabs/flutter` suelen ir retrasadas respecto al SDK del proyecto.

Detalle en [`README.md`](../README.md#producción-con-podmandocker).

## Quality gates

Ejecutar antes de cada PR o commit importante:

```bash
dart format .
dart analyze
flutter test
flutter build web
```

Opcional (quality gate de agentes): `flutter build apk --debug`

## Tests

- Parsers: `test/*_parser_test.dart`, `test/*_test.dart`
- UI smoke: `test/device_selector_page_test.dart`

Patrón recomendado para parsers: entrada serial de ejemplo → objeto tipado → CSV/export.

## Seguridad antes de commit

```bash
./scripts/check-secrets.sh
```

Ver políticas completas en [`SECURITY.md`](SECURITY.md) (inglés).

## Agentes IA

- [`AGENTS.md`](../AGENTS.md) — Restricciones y quality gates para asistentes.
- [`.cursor/rules/`](../.cursor/rules/) — Reglas por feature (wardriving, marauder, magspoof).
- [`.agents/skills/`](../.agents/skills/) — Skills de referencia.

## Referencias de protocolo (opcional)

Si trabajas dentro del monorepo padre, existen documentos extendidos en `../docs/`:

- LilyGO wardriving — `lilygo_webclients_logic.md`
- Marauder — `marauder_ui_pro_logic.md`
- MagSpoof V5 — `magspoof_v5_logic.md`

Este repositorio **no depende** de esos archivos para compilar ni desplegar.

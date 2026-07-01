# Clasificación de uploads (`device_source`)

Referencia para registrar dispositivos en el backend wardriving y entender qué envía cada ruta al endpoint de file-upload.

## Endpoint

Configurado con `WARDRIVE_UPLOAD_URL` (`.env` / `--dart-define`), por ejemplo:

`POST https://api.example.com/v1/files-uploaded/`

## Formato del request

```http
POST /v1/files-uploaded/ HTTP/1.1
Authorization: Bearer <access_token JWT>
Content-Type: multipart/form-data

device_source=<string>
files=<archivo CSV>
```

| Campo | Descripción |
|-------|-------------|
| `Authorization` | JWT obtenido en login (`WARDRIVE_LOGIN_URL`) |
| `device_source` | Clasifica el origen del CSV en el backend |
| `files` | Un archivo CSV por request |

Los valores de `device_source` están **fijos en código** ([`device_profile.dart`](../lib/core/config/device_profile.dart)), no son variables de entorno.

## Por ruta / aplicación

| Ruta | Hardware | Login | Upload | `device_source` |
|------|----------|-------|--------|---------------|
| `/tsim7000g` | LilyGO TSIM7000G | Sí | WiFi, BLE, LTE (3 CSV separados) | `rf custom firmware wifi` (WiFi/BLE) |
| | | | | `rf custom firmware lte` (LTE) |
| `/tsim7600hg` | LilyGO TSIM7600H-G | Sí | WiFi, BLE, LTE (3 CSV separados) | `rf custom firmware wifi` (WiFi/BLE) |
| | | | | `rf custom firmware lte` (LTE) |
| `/pwnterrey-marauder` | Badge Pwnterrey 2026 | Sí | Wardrive WiGLE CSV | `pwnterrey marauder` |
| `/oficial-marauder` | ESP32 Marauder oficial | Sí | Wardrive WiGLE CSV | `pwnterrey marauder` |
| `/magspoof-v5` | MagSpoof V5 | No | — | — (solo export CSV local) |

## Contenido de los CSV

### LilyGO (wardriving)

**WiFi** — columnas: Timestamp, Lat, Long, SSID, BSSID, Canal, Señal, Seguridad  
**BLE** — columnas: Timestamp, Lat, Long, Dirección, RSSI, Nombre  
**LTE** — columnas: Timestamp, Tecnología, TipoCelda, Estado, MCC, MNC, LAC, CellID, eNodeB, Sector, PCI, Banda, EARFCN, FreqDL_MHz, FreqUL_MHz, RSSI, RSRP, RSRQ, SINR, Operador, Longitud, Latitud

Nombre de archivo: `lilygo_{wifi|ble|lte}_YYYYMMDD_HHMMSS.csv`

WiFi y BLE comparten el mismo `device_source` (`rf custom firmware wifi`); el backend distingue por estructura del CSV.

### Marauder (wardrive)

Formato **WigleWifi 1.4**:

1. Meta: `WigleWifi-1.4,appRelease=PwnterreyESP32Marauder` (Pwnterrey) o `ESP32Marauder` (oficial, fallback si el dialecto serial no trae `appRelease`)
2. Cabecera: MAC, SSID, AuthMode, FirstSeen, Channel, RSSI, CurrentLatitude, CurrentLongitude, AltitudeMeters, AccuracyMeters, Type (+ LastSeen, Frequency opcionales)
3. Filas de APs capturados

Nombre de archivo: `wardrive_YYYY-MM-DDTHH-MM-SS.csv`

## Auth compartida

Wardriving y Marauder usan la misma sesión JWT en `localStorage` (clave `wardrive-auth`). Un login en cualquiera de las dos apps habilita upload en ambas **en la misma origin**.

## Backend

Registrar cada `device_source` en `SourceDevice.AVAILABLE_CHOICES` (o equivalente) del API wardriving antes de aceptar uploads.

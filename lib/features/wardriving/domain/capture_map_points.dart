import 'models.dart';

class CaptureMapPoint {
  const CaptureMapPoint({
    required this.scanType,
    required this.latitude,
    required this.longitude,
    required this.label,
  });

  final ScanType scanType;
  final double latitude;
  final double longitude;
  final String label;
}

bool hasUsableMapCoordinates(String latitude, String longitude) {
  final lat = double.tryParse(latitude.trim());
  final lng = double.tryParse(longitude.trim());
  if (lat == null || lng == null) return false;
  if (lat == 0 && lng == 0) return false;
  return true;
}

List<CaptureMapPoint> captureMapPoints({
  required List<LteRecord> lteRows,
  required List<WifiRecord> wifiRows,
  required List<BleRecord> bleRows,
}) {
  final points = <CaptureMapPoint>[];

  for (final row in lteRows) {
    if (!hasUsableMapCoordinates(row.latitude, row.longitude)) continue;
    final label = row.operator.isNotEmpty
        ? '${row.operator} · ${row.technology}'
        : row.technology;
    points.add(
      CaptureMapPoint(
        scanType: ScanType.lte,
        latitude: double.parse(row.latitude),
        longitude: double.parse(row.longitude),
        label: label,
      ),
    );
  }

  for (final row in wifiRows) {
    if (!hasUsableMapCoordinates(row.latitude, row.longitude)) continue;
    final ssid = row.ssid.isEmpty ? '(hidden)' : row.ssid;
    points.add(
      CaptureMapPoint(
        scanType: ScanType.wifi,
        latitude: double.parse(row.latitude),
        longitude: double.parse(row.longitude),
        label: '$ssid · ${row.bssid}',
      ),
    );
  }

  for (final row in bleRows) {
    if (!hasUsableMapCoordinates(row.latitude, row.longitude)) continue;
    final name = row.name.isEmpty ? 'Unknown' : row.name;
    points.add(
      CaptureMapPoint(
        scanType: ScanType.ble,
        latitude: double.parse(row.latitude),
        longitude: double.parse(row.longitude),
        label: '$name · ${row.address}',
      ),
    );
  }

  return points;
}

/// Default map center (CDMX) when there are no captures yet.
const defaultMapLatitude = 19.432608;
const defaultMapLongitude = -99.133209;
const defaultMapZoom = 13.0;

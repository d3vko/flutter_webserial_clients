import '../../../core/theme/app_colors.dart';
import '../../wardriving/domain/capture_map_points.dart';
import '../../wardriving/domain/models.dart';
import 'marauder_models.dart';

List<CaptureMapPoint> marauderMapPoints({
  required List<WardriveEntry> wardriveEntries,
  required GpsTelemetry gpsTelemetry,
  bool includeWardrive = true,
  bool includeGpsFix = true,
}) {
  final points = <CaptureMapPoint>[];

  if (includeWardrive) {
    for (final entry in wardriveEntries) {
      if (!hasUsableMapCoordinates(entry.latitude, entry.longitude)) continue;
      final isBle = entry.type.toUpperCase().contains('BLE');
      final scanType = isBle ? ScanType.ble : ScanType.wifi;
      final ssid = entry.ssid.isEmpty ? '(hidden)' : entry.ssid;
      points.add(
        CaptureMapPoint(
          scanType: scanType,
          latitude: double.parse(entry.latitude.trim()),
          longitude: double.parse(entry.longitude.trim()),
          label: '$ssid · ${entry.mac}',
        ),
      );
    }
  }

  if (includeGpsFix &&
      gpsTelemetry.fix == true &&
      gpsTelemetry.lat != null &&
      gpsTelemetry.lon != null &&
      hasUsableMapCoordinates(gpsTelemetry.lat!, gpsTelemetry.lon!)) {
    points.add(
      CaptureMapPoint(
        scanType: ScanType.lte,
        latitude: double.parse(gpsTelemetry.lat!.trim()),
        longitude: double.parse(gpsTelemetry.lon!.trim()),
        label: 'GPS fix · ${gpsTelemetry.sats ?? '?'} sats',
        color: AppColors.villageCyan,
        isGpsFix: true,
      ),
    );
  }

  return points;
}

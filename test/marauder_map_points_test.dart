import 'package:flutter_test/flutter_test.dart';
import 'package:lilygo_wardriving_web/features/marauder/domain/marauder_map_points.dart';
import 'package:lilygo_wardriving_web/features/marauder/domain/marauder_models.dart';
import 'package:lilygo_wardriving_web/features/wardriving/domain/models.dart';

void main() {
  const entry = WardriveEntry(
    mac: '02:00:00:00:00:01',
    ssid: 'TestNet',
    security: '[WPA2]',
    firstSeen: '2026-01-01',
    lastSeen: '',
    channel: '6',
    frequency: '',
    rssi: '-55',
    latitude: '19.4326',
    longitude: '-99.1332',
    altitude: '0',
    accuracy: '5',
    type: 'WIFI',
    sourceFormat: '',
    sourceVersion: '',
  );

  test('marauderMapPoints includes wardrive WiFi entries', () {
    final points = marauderMapPoints(
      wardriveEntries: const [entry],
      gpsTelemetry: const GpsTelemetry(),
    );

    expect(points, hasLength(1));
    expect(points.first.scanType, ScanType.wifi);
    expect(points.first.label, contains('TestNet'));
  });

  test('marauderMapPoints includes live GPS fix', () {
    final points = marauderMapPoints(
      wardriveEntries: const [],
      gpsTelemetry: const GpsTelemetry(
        fix: true,
        lat: '19.5000',
        lon: '-99.2000',
        sats: 8,
      ),
      includeWardrive: false,
    );

    expect(points, hasLength(1));
    expect(points.first.isGpsFix, isTrue);
    expect(points.first.scanType, ScanType.lte);
  });

  test('marauderMapPoints classifies BLE wardrive rows', () {
    const bleEntry = WardriveEntry(
      mac: '02:00:00:00:00:02',
      ssid: 'AirTag',
      security: '',
      firstSeen: '2026-01-01',
      lastSeen: '',
      channel: '-',
      frequency: '',
      rssi: '-70',
      latitude: '19.4326',
      longitude: '-99.1332',
      altitude: '0',
      accuracy: '5',
      type: 'BLE',
      sourceFormat: '',
      sourceVersion: '',
    );

    final points = marauderMapPoints(
      wardriveEntries: const [bleEntry],
      gpsTelemetry: const GpsTelemetry(),
    );

    expect(points.first.scanType, ScanType.ble);
  });
}

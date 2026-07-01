import 'package:flutter_test/flutter_test.dart';
import 'package:lilygo_wardriving_web/features/marauder/domain/marauder_models.dart';
import 'package:lilygo_wardriving_web/features/marauder/domain/wardrive_csv.dart';
import 'package:lilygo_wardriving_web/features/marauder/domain/wardrive_parser.dart';
import 'package:lilygo_wardriving_web/features/marauder/domain/wardrive_schema.dart';

void main() {
  const wifiMac = '02:00:00:00:00:01';
  const bleMac = '02:00:00:00:00:02';
  const bleNamedMac = '02:00:00:00:00:03';
  const bleUnicodeMac = '02:00:00:00:00:04';

  const row =
      '$wifiMac,TestNetwork,[WPA2_PSK],2026-01-01 00:00:00,6,-55,0.0000000,0.0000000,0.00,5,WIFI';

  test('strips terminal HTML before parsing', () {
    final htmlRow = '<span class="text-green-500">$row</span>';
    expect(normalizeWardriveLine(htmlRow), row);
    expect(parseWardriveRow(htmlRow)?.mac, wifiMac);
  });

  test('detects WigleWifi-1.4 meta-line', () {
    final result = parseWardriveMetaLine(
      'WigleWifi-1.4,appRelease=SyntheticFirmware',
    );
    expect(result?.sourceVersion, '1.4');
    expect(result?.appRelease, 'SyntheticFirmware');
  });

  test('detects legacy WiGLE format via netid header', () {
    final result = parseWardriveMetaLine(
      'netid,ssid,wep,trilat,trilong,firsttime,channel,freenet,carrier',
    );
    expect(result?.sourceFormat, 'WigleLegacy');
    expect(result?.sourceVersion, 'legacy');
  });

  test('resolves standard WigleWifi-1.4 column header', () {
    final mapping = parseWardriveColumnHeader(
      'MAC,SSID,AuthMode,FirstSeen,Channel,RSSI,'
      'CurrentLatitude,CurrentLongitude,AltitudeMeters,AccuracyMeters,Type',
    );
    expect(mapping, isNotNull);
    expect(mapping!.indexByCanonical['mac'], 0);
    expect(mapping.indexByCanonical['security'], 2);
  });

  test('parses classic WiFi row to canonical fields', () {
    final entry = parseWardriveRow(row);
    expect(entry?.mac, wifiMac);
    expect(entry?.ssid, 'TestNetwork');
    expect(entry?.security, '[WPA2_PSK]');
    expect(entry?.type, 'WIFI');
  });

  test('parses serial counter rows', () {
    expect(parseWardriveRow('15 | $row')?.mac, wifiMac);
  });

  test('parses classic direct BLE rows', () {
    final entry = parseWardriveRow(
      '$bleMac,,[BLE],,0,-54,0.0000000,0.0000000,0.00,63.75,BLE',
    );
    expect(entry?.mac, bleMac);
    expect(entry?.type, 'BLE');
  });

  test('parses BLE rows with ASCII name glued to the MAC', () {
    final entry = parseWardriveRow(
      'Synthetic BLE Device$bleNamedMac,,[BLE],,0,-54,0.0000000,0.0000000,0.00,63.75,BLE',
    );
    expect(entry?.mac, bleNamedMac);
    expect(entry?.ssid, 'Synthetic BLE Device');
  });

  test('parses BLE rows with Unicode name glued to the MAC', () {
    final entry = parseWardriveRow(
      'Dispositivo de prueba Ñ$bleUnicodeMac,,[BLE],,0,-53,0.0000000,0.0000000,0.00,63.75,BLE',
    );
    expect(entry?.mac, bleUnicodeMac);
    expect(entry?.ssid, 'Dispositivo de prueba Ñ');
  });

  test('ignores firmware errors and non-csv lines', () {
    expect(parseWardriveRow('[BUF/CLOSE]AP config set error...'), isNull);
    expect(parseWardriveRow('StartingWardrive...'), isNull);
    expect(parseWardriveRow('marauder>'), isNull);
  });

  test('creates one stable key for visible and buffered duplicate rows', () {
    final visible = parseWardriveRow('1 | $row');
    final buffered = parseWardriveRow('[BUF/BEGIN]$row');
    expect(wardriveEntryKey(visible!), wardriveEntryKey(buffered!));
  });

  test(
    'round-trip parse buildWardriveCsvString re-parse yields same entries',
    () {
      final entries = [
        parseWardriveRow(row)!,
        parseWardriveRow(
          '$wifiMac,,[OPEN],2026-01-01 00:00:00,1,-70,0.0000000,0.0000000,0.00,0,WIFI',
        )!,
      ];

      final csv = buildWardriveCsvString(
        entries,
        const WardriveDialect(
          sourceFormat: 'WigleWifi',
          sourceVersion: '1.4',
          appRelease: 'TestRig',
        ),
      );
      final csvLines = csv.split('\n');

      final metaResult = parseWardriveMetaLine(csvLines[0]);
      expect(metaResult?.sourceVersion, '1.4');
      expect(metaResult?.appRelease, 'TestRig');

      final headerMapping = parseWardriveColumnHeader(csvLines[1]);
      expect(headerMapping, isNotNull);

      final reparsed = csvLines
          .skip(2)
          .map((line) => parseWardriveRow(line, headerMapping))
          .whereType()
          .toList();
      expect(reparsed.length, entries.length);
      expect(reparsed[0].mac, entries[0].mac);
      expect(reparsed[0].ssid, entries[0].ssid);
    },
  );

  test('parses extended header with LastSeen and Frequency', () {
    final mapping = buildColumnMapping(
      'MAC,SSID,Capabilities,FirstSeen,LastSeen,Channel,Frequency,RSSI,'
      'CurrentLatitude,CurrentLongitude,AltitudeMeters,AccuracyMeters,Type',
    );
    const extRow =
        '$wifiMac,TestNet,[WPA2],2026-01-01 00:00:00,2026-01-01 00:01:00,6,2437,-60,1.0000000,2.0000000,10.0,5,WIFI';
    final entry = parseWardriveRow(extRow, mapping);
    expect(entry?.lastSeen, '2026-01-01 00:01:00');
    expect(entry?.frequency, '2437');
  });
}

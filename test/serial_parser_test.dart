import 'package:lilygo_wardriving_web/features/wardriving/domain/models.dart';
import 'package:lilygo_wardriving_web/features/wardriving/domain/serial_parser.dart';
import 'package:test/test.dart';

const capturedAt = '2026-04-10T23:52:01.000Z';

void main() {
  group('parseSerialLine', () {
    test('detects LTE, WiFi, and BLE headers', () {
      expect(
        parseSerialLine(lteHeader, capturedAt: capturedAt),
        isA<HeaderEvent>()
            .having((e) => e.scanType, 'scanType', ScanType.lte)
            .having((e) => e.line, 'line', lteHeader),
      );
      expect(
        parseSerialLine(lteExtendedHeader, capturedAt: capturedAt),
        isA<HeaderEvent>()
            .having((e) => e.scanType, 'scanType', ScanType.lte)
            .having((e) => e.line, 'line', lteExtendedHeader),
      );
      expect(
        parseSerialLine(wifiHeader, capturedAt: capturedAt),
        isA<HeaderEvent>()
            .having((e) => e.scanType, 'scanType', ScanType.wifi)
            .having((e) => e.line, 'line', wifiHeader),
      );
      expect(
        parseSerialLine(bleHeader, capturedAt: capturedAt),
        isA<HeaderEvent>()
            .having((e) => e.scanType, 'scanType', ScanType.ble)
            .having((e) => e.line, 'line', bleHeader),
      );
    });

    test('parses a valid LTE legacy row', () {
      const line =
          'lte,,LTE,0,334,020,1201,390112,3,-73,-101,-10,9,Telcel,-99.1332090,19.4326080';
      final event = parseSerialLine(line, capturedAt: capturedAt);

      expect(event, isA<LteEvent>());
      final lte = event as LteEvent;
      expect(lte.line, line);
      expect(lte.record.operator, 'Telcel');
      expect(lte.record.longitude, '-99.1332090');
      expect(lte.record.latitude, '19.4326080');
      expect(lte.record.capturedAt, capturedAt);
      expect(lte.record.cellType, '');
      expect(lte.record.eNodeB, '');
      expect(lte.record.pci, '');
    });

    test('parses a valid LTE extended row', () {
      const line =
          'lte,,LTE,FDD-LTE,0,334,020,1201,390112,6095,2,123,3,1300,2115.0,1920.0,-73,-101,-10,9,Telcel,-99.1332090,19.4326080';
      final event = parseSerialLine(line, capturedAt: capturedAt);

      expect(event, isA<LteEvent>());
      final lte = event as LteEvent;
      expect(lte.record.technology, 'LTE');
      expect(lte.record.cellType, 'FDD-LTE');
      expect(lte.record.mcc, '334');
      expect(lte.record.cellId, '390112');
      expect(lte.record.eNodeB, '6095');
      expect(lte.record.sector, '2');
      expect(lte.record.pci, '123');
      expect(lte.record.band, '3');
      expect(lte.record.earfcn, '1300');
      expect(lte.record.freqDlMhz, '2115.0');
      expect(lte.record.freqUlMhz, '1920.0');
      expect(lte.record.rssi, '-73');
      expect(lte.record.rsrp, '-101');
      expect(lte.record.rsrq, '-10');
      expect(lte.record.sinr, '9');
      expect(lte.record.operator, 'Telcel');
      expect(lte.record.longitude, '-99.1332090');
      expect(lte.record.latitude, '19.4326080');
      expect(lte.record.capturedAt, capturedAt);
    });

    test('parses a valid WiFi row with an empty SSID', () {
      const line =
          'wifi,,19.4326080,-99.1332090,,A2:31:DB:A0:CC:C6,7,-73,WPA2_PSK';
      final event = parseSerialLine(line, capturedAt: capturedAt);

      expect(event, isA<WifiEvent>());
      final wifi = event as WifiEvent;
      expect(wifi.record.ssid, '');
      expect(wifi.record.bssid, 'A2:31:DB:A0:CC:C6');
      expect(wifi.record.security, 'WPA2_PSK');
    });

    test('parses a valid BLE row', () {
      const line = 'ble,,19.4326080,-99.1332090,80:E1:26:76:33:64,-65,d3vnull0';
      final event = parseSerialLine(line, capturedAt: capturedAt);

      expect(event, isA<BleEvent>());
      final ble = event as BleEvent;
      expect(ble.record.address, '80:E1:26:76:33:64');
      expect(ble.record.name, 'd3vnull0');
    });

    test('rejects zero-coordinate rows for every scan type', () {
      expect(
        parseSerialLine(
          'lte,,LTE,0,0,0,0,0,0,0,0,0,0,,0.0000000,0.0000000',
          capturedAt: capturedAt,
        ),
        isA<IgnoredInvalidCoordinatesEvent>().having(
          (e) => e.scanType,
          'scanType',
          ScanType.lte,
        ),
      );
      expect(
        parseSerialLine(
          'lte,,LTE,FDD-LTE,0,0,0,0,0,0,0,0,0,0,0.0,0.0,0,0,0,0,,0.0000000,0.0000000',
          capturedAt: capturedAt,
        ),
        isA<IgnoredInvalidCoordinatesEvent>().having(
          (e) => e.scanType,
          'scanType',
          ScanType.lte,
        ),
      );
      expect(
        parseSerialLine(
          'wifi,,0.0000000,0.0000000,Home,18:A6:F7:BF:71:72,2,-57,WPA_WPA2_PSK',
          capturedAt: capturedAt,
        ),
        isA<IgnoredInvalidCoordinatesEvent>().having(
          (e) => e.scanType,
          'scanType',
          ScanType.wifi,
        ),
      );
      expect(
        parseSerialLine(
          'ble,,0.0000000,0.0000000,80:E1:26:76:33:64,-65,d3vnull0',
          capturedAt: capturedAt,
        ),
        isA<IgnoredInvalidCoordinatesEvent>().having(
          (e) => e.scanType,
          'scanType',
          ScanType.ble,
        ),
      );
    });

    test('classifies status and ESP warning lines as logs', () {
      expect(
        parseSerialLine('[modem] AT sync OK', capturedAt: capturedAt),
        isA<LogEvent>().having((e) => e.line, 'line', '[modem] AT sync OK'),
      );
      expect(
        parseSerialLine(
          '[ 18793][W][sd_diskio.cpp:104] sdWait(): Wait Failed',
          capturedAt: capturedAt,
        ),
        isA<LogEvent>().having(
          (e) => e.line,
          'line',
          '[ 18793][W][sd_diskio.cpp:104] sdWait(): Wait Failed',
        ),
      );
    });
  });

  group('parseSerialChunk', () {
    test('buffers partial lines across chunks', () {
      final first = parseSerialChunk(
        'wifi,,19.4326080,-99.1332090,Network',
        capturedAt: capturedAt,
      );
      expect(first.events, isEmpty);
      expect(first.carry, 'wifi,,19.4326080,-99.1332090,Network');

      final second = parseSerialChunk(
        ',AA:BB:CC:DD:EE:FF,11,-53,WPA2_PSK\n[ble] logged 1 devices\n',
        carry: first.carry,
        capturedAt: capturedAt,
      );
      expect(second.carry, '');
      expect(second.events.map((event) => event.runtimeType), [
        WifiEvent,
        LogEvent,
      ]);
    });
  });
}

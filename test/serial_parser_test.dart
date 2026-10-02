import 'package:lilygo_wardriving_web/features/wardriving/domain/models.dart';
import 'package:lilygo_wardriving_web/features/wardriving/domain/serial_parser.dart';
import 'package:test/test.dart';

const capturedAt = '2026-04-10T23:52:01.000Z';

void main() {
  group('parseSerialLine', () {
    test('detects LTE, WiFi, BLE legacy, and unified radio headers', () {
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
      expect(
        parseSerialLine(radioUnifiedHeader, capturedAt: capturedAt),
        isA<HeaderEvent>()
            .having((e) => e.scanType, 'scanType', ScanType.wifi)
            .having((e) => e.line, 'line', radioUnifiedHeader),
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

    test('parses a valid legacy WiFi row with an empty SSID', () {
      const line =
          'wifi,,19.4326080,-99.1332090,,A2:31:DB:A0:CC:C6,7,-73,WPA2_PSK';
      final event = parseSerialLine(line, capturedAt: capturedAt);

      expect(event, isA<WifiEvent>());
      final wifi = event as WifiEvent;
      expect(wifi.record.ssid, '');
      expect(wifi.record.bssid, 'A2:31:DB:A0:CC:C6');
      expect(wifi.record.security, 'WPA2_PSK');
      expect(wifi.record.radioType, 'WIFI');
    });

    test('parses a valid legacy BLE row', () {
      const line = 'ble,,19.4326080,-99.1332090,80:E1:26:76:33:64,-65,d3vnull0';
      final event = parseSerialLine(line, capturedAt: capturedAt);

      expect(event, isA<BleEvent>());
      final ble = event as BleEvent;
      expect(ble.record.address, '80:E1:26:76:33:64');
      expect(ble.record.ssid, 'd3vnull0');
      expect(ble.record.name, 'd3vnull0');
    });

    test('parses unified WiFi and BLE rows after unified header', () {
      final parser = SerialStreamParser();
      parser.parseLine(radioUnifiedHeader, capturedAt);

      const wifiLine =
          'wifi,AA:BB:CC:DD:EE:FF,RedCasa,WPA2_PSK,2026-07-02 12:00:00,6,-65,19.4326000,-99.1332000,2240.00,5.00,WIFI';
      final wifiEvent = parser.parseLine(wifiLine, capturedAt);
      expect(wifiEvent, isA<WifiEvent>());
      final wifi = wifiEvent as WifiEvent;
      expect(wifi.record.bssid, 'AA:BB:CC:DD:EE:FF');
      expect(wifi.record.ssid, 'RedCasa');
      expect(wifi.record.security, 'WPA2_PSK');
      expect(wifi.record.timestamp, '2026-07-02 12:00:00');
      expect(wifi.record.channel, '6');
      expect(wifi.record.signal, '-65');
      expect(wifi.record.altitudeMeters, '2240.00');
      expect(wifi.record.accuracyMeters, '5.00');
      expect(wifi.record.radioType, 'WIFI');

      const bleLine =
          'ble,11:22:33:44:55:66,,BLE,2026-07-02 12:00:00,0,-72,19.4326000,-99.1332000,2240.00,5.00,BLE';
      final bleEvent = parser.parseLine(bleLine, capturedAt);
      expect(bleEvent, isA<BleEvent>());
      final ble = bleEvent as BleEvent;
      expect(ble.record.address, '11:22:33:44:55:66');
      expect(ble.record.ssid, '');
      expect(ble.record.security, 'BLE');
      expect(ble.record.channel, '0');
      expect(ble.record.rssi, '-72');
      expect(ble.record.radioType, 'BLE');
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

  group('SerialStreamParser', () {
    test('buffers partial lines across chunks', () {
      final parser = SerialStreamParser();
      final first = parseSerialChunk(
        'wifi,,19.4326080,-99.1332090,Network',
        parser: parser,
        capturedAt: capturedAt,
      );
      expect(first.events, isEmpty);
      expect(first.carry, 'wifi,,19.4326080,-99.1332090,Network');

      final second = parseSerialChunk(
        ',AA:BB:CC:DD:EE:FF,11,-53,WPA2_PSK\n[ble] logged 1 devices\n',
        parser: parser,
        capturedAt: capturedAt,
      );
      expect(second.carry, '');
      expect(second.events.map((event) => event.runtimeType), [
        WifiEvent,
        LogEvent,
      ]);
    });

    test('switches between legacy and unified formats within one stream', () {
      final parser = SerialStreamParser();
      parser.parseLine(wifiHeader, capturedAt);
      final legacy = parser.parseLine(
        'wifi,,19.4326080,-99.1332090,LegacyNet,AA:BB:CC:DD:EE:FF,6,-65,WPA2_PSK',
        capturedAt,
      );
      expect(legacy, isA<WifiEvent>());
      expect((legacy as WifiEvent).record.ssid, 'LegacyNet');

      parser.parseLine(radioUnifiedHeader, capturedAt);
      final unified = parser.parseLine(
        'wifi,AA:BB:CC:DD:EE:FF,RedCasa,WPA2_PSK,2026-07-02 12:00:00,6,-65,19.4326000,-99.1332000,2240.00,5.00,WIFI',
        capturedAt,
      );
      expect(unified, isA<WifiEvent>());
      expect((unified as WifiEvent).record.ssid, 'RedCasa');
      expect(unified.record.altitudeMeters, '2240.00');
    });
  });

  group('Minino WigleWifi-1.4', () {
    const wigleMeta =
        'WigleWifi-1.4,appRelease=1.0.0,model=MININO,release=1.0.0,'
        'device=MININO,display=SH1106 OLED,board=ESP32C6,brand=RFVillageMx,'
        'star=Sol,body=3,subBody=0';
    const wigleColumns =
        'MAC,SSID,AuthMode,FirstSeen,Channel,Frequency,RSSI,'
        'CurrentLatitude,CurrentLongitude,AltitudeMeters,AccuracyMeters,'
        'RCOIs,MfgrId,Type';

    test('ignores hash diag lines and parses #GPS backend status', () {
      expect(
        parseSerialLine(
          '#custom_minino_wardriving — @d3v.k0 / RF Village',
          capturedAt: capturedAt,
        ),
        isA<LogEvent>(),
      );
      expect(
        parseSerialLine(
          'W (6271) wardrive: Wardrive WiFi+BLE ready (SD=no)',
          capturedAt: capturedAt,
        ),
        isA<LogEvent>(),
      );
      expect(
        parseSerialLine(
          '#GPS switch NEO6M baud=9600 J2 RX=17 TX=16 (ATGM power OFF)',
          capturedAt: capturedAt,
        ),
        isA<LogEvent>(),
      );

      final gps = parseSerialLine(
        '#GPS backend=ATGM status=waiting fix=0 sats=0 bytes=128 nmea=4 '
        'ts=2000-01-01 00:00:00 lat=0.0000000 lon=0.0000000',
        capturedAt: capturedAt,
      );
      expect(gps, isA<GpsDiagEvent>());
      final diag = gps as GpsDiagEvent;
      expect(diag.source, 'ATGM');
      expect(diag.status, 'waiting');
      expect(diag.fix, 0);
      expect(diag.sats, 0);
      expect(diag.hasFix, isFalse);
      expect(diag.timestamp, '2000-01-01 00:00:00');
      expect(diag.latitude, '0.0000000');
      expect(diag.longitude, '0.0000000');
    });

    test('parses #GPS backend ready with synthetic fix coords', () {
      final gps = parseSerialLine(
        '#GPS backend=NEO6M status=ready fix=1 sats=9 bytes=256 nmea=4 '
        'ts=2026-10-02 03:21:16 lat=1.2345678 lon=-9.8765432',
        capturedAt: capturedAt,
      );
      expect(gps, isA<GpsDiagEvent>());
      final diag = gps as GpsDiagEvent;
      expect(diag.source, 'NEO6M');
      expect(diag.status, 'ready');
      expect(diag.fix, 1);
      expect(diag.sats, 9);
      expect(diag.hasFix, isTrue);
      expect(diag.latitude, '1.2345678');
      expect(diag.longitude, '-9.8765432');
    });

    test('parses Minino Wigle WIFI and BLE rows including zero GPS', () {
      final parser = SerialStreamParser();
      expect(parser.parseLine(wigleMeta, capturedAt), isA<LogEvent>());
      expect(
        parser.parseLine(wigleColumns, capturedAt),
        isA<HeaderEvent>().having((e) => e.scanType, 'scanType', ScanType.wifi),
      );

      const wifiLine =
          'aa:bb:cc:dd:ee:ff,DemoAP,WPA2_PSK,2026-10-02 01:35:35,6,2437,-61,'
          '1.2345678,-9.8765432,100.00,5.00,,,WIFI';
      final wifiEvent = parser.parseLine(wifiLine, capturedAt);
      expect(wifiEvent, isA<WifiEvent>());
      final wifi = wifiEvent as WifiEvent;
      expect(wifi.record.bssid, 'aa:bb:cc:dd:ee:ff');
      expect(wifi.record.ssid, 'DemoAP');
      expect(wifi.record.security, 'WPA2_PSK');
      expect(wifi.record.channel, '6');
      expect(wifi.record.signal, '-61');
      expect(wifi.record.latitude, '1.2345678');
      expect(wifi.record.longitude, '-9.8765432');
      expect(wifi.record.radioType, 'WIFI');

      const bleLine =
          'AA:BB:CC:DD:EE:FF,,BLE,2026-10-02 01:35:36,0,0,-80,'
          '0.0000000,0.0000000,0.00,0.00,,,BLE';
      final bleEvent = parser.parseLine(bleLine, capturedAt);
      expect(bleEvent, isA<BleEvent>());
      final ble = bleEvent as BleEvent;
      expect(ble.record.address, 'AA:BB:CC:DD:EE:FF');
      expect(ble.record.security, 'BLE');
      expect(ble.record.rssi, '-80');
      expect(ble.record.latitude, '0.0000000');
      expect(ble.record.longitude, '0.0000000');
      expect(ble.record.radioType, 'BLE');
    });

    test('parses Wigle WIFI mid-stream without prior header', () {
      final parser = SerialStreamParser();
      // Firmware already printed WigleWifi + column header before connect.
      const wifiLine =
          'b4:04:18:00:5b:d9,ActionCam_b40418005b89,WPA2_PSK,'
          '2026-10-02 03:56:17,11,2462,-92,1.2345678,-9.8765432,100.00,5.00,,WIFI';
      final event = parser.parseLine(wifiLine, capturedAt);
      expect(event, isA<WifiEvent>());
      final wifi = event as WifiEvent;
      expect(wifi.record.bssid, 'b4:04:18:00:5b:d9');
      expect(wifi.record.ssid, 'ActionCam_b40418005b89');
      expect(wifi.record.channel, '11');
      expect(wifi.record.signal, '-92');
      expect(wifi.record.latitude, '1.2345678');
      expect(wifi.record.longitude, '-9.8765432');
      expect(wifi.record.radioType, 'WIFI');
    });
  });
}

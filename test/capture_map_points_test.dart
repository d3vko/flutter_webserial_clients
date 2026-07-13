import 'package:lilygo_wardriving_web/features/wardriving/domain/capture_map_points.dart';
import 'package:lilygo_wardriving_web/features/wardriving/domain/models.dart';
import 'package:test/test.dart';

void main() {
  group('captureMapPoints', () {
    test('hasUsableMapCoordinates rejects zero coordinates', () {
      expect(hasUsableMapCoordinates('0', '0'), isFalse);
      expect(hasUsableMapCoordinates('19.43', '-99.13'), isTrue);
    });

    test('builds points from LTE WiFi and BLE rows', () {
      const lte = LteRecord(
        timestamp: '',
        technology: 'LTE',
        cellType: '',
        status: '0',
        mcc: '334',
        mnc: '020',
        lac: '1201',
        cellId: '390112',
        eNodeB: '',
        sector: '',
        pci: '',
        band: '3',
        earfcn: '',
        freqDlMhz: '',
        freqUlMhz: '',
        rssi: '-73',
        rsrp: '-101',
        rsrq: '-10',
        sinr: '9',
        operator: 'Telcel',
        longitude: '-99.1332090',
        latitude: '19.4326080',
        capturedAt: '',
      );
      const wifi = WifiRecord(
        timestamp: '',
        latitude: '19.4350000',
        longitude: '-99.1300000',
        ssid: 'CafeNet',
        bssid: 'AA:BB:CC:DD:EE:FF',
        channel: '6',
        signal: '-65',
        security: 'WPA2_PSK',
        capturedAt: '',
      );
      const ble = BleRecord(
        timestamp: '',
        latitude: '19.4370000',
        longitude: '-99.1270000',
        address: 'FE:DC:BA:98:76:54',
        rssi: '-61',
        ssid: 'Beacon',
        capturedAt: '',
      );

      final points = captureMapPoints(
        lteRows: [lte],
        wifiRows: [wifi],
        bleRows: [ble],
      );

      expect(points, hasLength(3));
      expect(points[0].scanType, ScanType.lte);
      expect(points[1].scanType, ScanType.wifi);
      expect(points[2].scanType, ScanType.ble);
      expect(points[0].label, contains('Telcel'));
    });
  });
}

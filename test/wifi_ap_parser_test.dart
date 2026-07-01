import 'package:flutter_test/flutter_test.dart';
import 'package:lilygo_wardriving_web/features/marauder/domain/marauder_models.dart';
import 'package:lilygo_wardriving_web/features/marauder/domain/wifi_ap_parser.dart';

void main() {
  group('parseWifiLine', () {
    test('parses scan result RSSI BSSID ESSID', () {
      final update = parseWifiLine(
        'RSSI: -45 Ch: 6 BSSID: AA:BB:CC:DD:EE:FF ESSID: TestNetwork',
      );
      expect(update, isNotNull);
      expect(update!.kind, AccessPointUpdateKind.scanResult);
      expect(update.rssi, -45);
      expect(update.channel, 6);
      expect(update.bssid, 'AA:BB:CC:DD:EE:FF');
      expect(update.essid, 'TestNetwork');
    });

    test('parses list entry', () {
      final update = parseWifiLine('[0][CH:11] MySSID (selected)');
      expect(update, isNotNull);
      expect(update!.kind, AccessPointUpdateKind.listEntry);
      expect(update.index, 0);
      expect(update.channel, 11);
      expect(update.essid, 'MySSID');
      expect(update.isSelected, isTrue);
    });
  });

  group('applyAccessPointUpdate', () {
    test('accumulates scan and list data', () {
      var aps = <String, AccessPoint>{};
      final scan = parseWifiLine(
        'RSSI: -60 Ch: 1 BSSID: 11:22:33:44:55:66 ESSID: Cafe',
      )!;
      aps = applyAccessPointUpdate(aps, scan);
      expect(aps.length, 1);
      expect(aps.values.first.essid, 'Cafe');

      final list = parseWifiLine('[0][CH:1] Cafe')!;
      aps = applyAccessPointUpdate(aps, list);
      expect(aps.values.first.index, 0);
    });
  });
}

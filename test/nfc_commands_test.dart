import 'package:flutter_test/flutter_test.dart';
import 'package:lilygo_wardriving_web/features/marauder/domain/nfc_commands.dart';

void main() {
  group('nfc commands', () {
    test('scan and read', () {
      expect(nfcScanCommand(), 'nfc scan');
      expect(nfcReadCommand(), 'nfc read');
    });

    test('url text vcard wifi', () {
      expect(
        nfcUrlCommand('https://example.com'),
        'nfc -u https://example.com',
      );
      expect(nfcTextCommand('hola'), 'nfc -t "hola"');
      expect(
        nfcVcardCommand('Name', '555', 'a@b.com'),
        'nfc -v "Name,555,a@b.com"',
      );
      expect(nfcWifiCommand('SSID', 'pass', 'WPA2'), 'nfc -w "SSID,pass,WPA2"');
    });
  });
}

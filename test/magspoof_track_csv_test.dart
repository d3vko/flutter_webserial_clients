import 'package:flutter_test/flutter_test.dart';
import 'package:lilygo_wardriving_web/features/magspoof/domain/track_csv.dart';
import 'package:lilygo_wardriving_web/features/magspoof/domain/track_models.dart';

void main() {
  test('maskPan keeps first 6 and last 4 digits', () {
    expect(maskPan('1234567890123456'), '123456******3456');
  });

  test('maskTrackRaw masks pan inside track string', () {
    final masked = maskTrackRaw(
      '%B1234567890123456^TEST/USER^300112300000000000?',
    );
    expect(masked.contains('123456******3456'), isTrue);
    expect(masked.contains('T***'), isTrue);
  });

  test('rowsToCsv masks sensitive fields in masked mode', () {
    final csv = rowsToCsv(
      [
        {
          'pan': '1234567890123456',
          'cardholder_name': 'TEST USER',
          'raw_value': ';1234567890123456=300112300000?',
        },
      ],
      const ['pan', 'cardholder_name', 'raw_value'],
      mode: MagspoofExportMode.masked,
    );

    expect(csv, contains('123456******3456'));
    expect(csv, contains('T***'));
    expect(csv.split('\r\n'), hasLength(2));
  });

  test('rowsToCsv keeps full values in full mode', () {
    final csv = rowsToCsv(
      [
        {'pan': '1234567890123456', 'cardholder_name': 'TEST USER'},
      ],
      const ['pan', 'cardholder_name'],
      mode: MagspoofExportMode.full,
    );

    expect(csv, contains('1234567890123456'));
    expect(csv, contains('TEST USER'));
  });
}

import 'package:lilygo_wardriving_web/features/wardriving/presentation/widgets/scan_table_formatters.dart';
import 'package:test/test.dart';

void main() {
  group('scan_table_formatters', () {
    test('dashIfEmpty returns em dash for empty values', () {
      expect(dashIfEmpty(''), emptyDash);
      expect(dashIfEmpty('123'), '123');
    });

    test('unknownIfEmpty returns Unknown for empty values', () {
      expect(unknownIfEmpty(''), 'Unknown');
      expect(unknownIfEmpty('Telcel'), 'Telcel');
    });

    test('hiddenSsid returns (hidden) for empty SSID', () {
      expect(hiddenSsid(''), '(hidden)');
      expect(hiddenSsid('CafeNet'), 'CafeNet');
    });

    test(
      'formatCapturedTime formats ISO timestamps to full local datetime',
      () {
        final formatted = formatCapturedTime('2026-04-10T23:52:01.000Z');
        expect(formatted, isNot(equals('')));
        expect(formatted, contains('2026'));
        expect(formatted, contains(':'));
        expect(formatCapturedTime(''), emptyDash);
        expect(formatCapturedTime('not-a-date'), 'not-a-date');
      },
    );
  });
}

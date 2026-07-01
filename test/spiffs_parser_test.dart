import 'package:flutter_test/flutter_test.dart';
import 'package:lilygo_wardriving_web/features/marauder/domain/marauder_models.dart';
import 'package:lilygo_wardriving_web/features/marauder/domain/spiffs_parser.dart';

void main() {
  group('parseSpiffsLine listing', () {
    test('parses file rows and total used', () {
      final file = parseSpiffsLine(
        '/wardrive.csv\t1234',
        SpiffsParseMode.listing,
      );
      expect(file?.fileName, '/wardrive.csv');
      expect(file?.fileSize, 1234);

      final total = parseSpiffsLine(
        'Total used: 5000 / 100000 bytes',
        SpiffsParseMode.listing,
      );
      expect(total?.isListComplete, isTrue);
      expect(total?.usedBytes, 5000);
      expect(total?.totalBytes, 100000);
    });
  });

  group('parseSpiffsLine reading', () {
    test('parses begin end and chunks', () {
      final begin = parseSpiffsLine('[SPIFFS/BEGIN]', SpiffsParseMode.reading);
      expect(begin?.isReadBegin, isTrue);

      final chunk = parseSpiffsLine('line content', SpiffsParseMode.reading);
      expect(chunk?.chunk, 'line content');

      final end = parseSpiffsLine('[SPIFFS/END]', SpiffsParseMode.reading);
      expect(end?.isReadEnd, isTrue);
    });
  });

  group('formatSpiffsSize', () {
    test('formats bytes KB MB', () {
      expect(formatSpiffsSize(512), '512 B');
      expect(formatSpiffsSize(2048), '2.0 KB');
      expect(formatSpiffsSize(2 * 1024 * 1024), '2.0 MB');
    });
  });
}

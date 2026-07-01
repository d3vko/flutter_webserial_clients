import 'package:flutter_test/flutter_test.dart';

import 'package:lilygo_wardriving_web/features/wardriving/domain/csv_exporter.dart';
import 'package:lilygo_wardriving_web/features/wardriving/domain/models.dart';
import 'package:lilygo_wardriving_web/features/wardriving/domain/serial_parser.dart';

void main() {
  test('parser and csv exporter smoke test', () {
    const line =
        'lte,,LTE,0,334,020,1201,390112,3,-73,-101,-10,9,Telcel,-99.1332090,19.4326080';
    final event = parseSerialLine(line);
    expect(event, isA<LteEvent>());

    final lte = (event as LteEvent).record;
    final csv = buildCsv(ScanType.lte, [lte]);
    expect(csv.split('\n').length, 2);
  });
}

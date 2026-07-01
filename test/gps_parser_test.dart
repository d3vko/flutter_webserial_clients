import 'package:flutter_test/flutter_test.dart';
import 'package:lilygo_wardriving_web/features/marauder/domain/gps_parser.dart';
import 'package:lilygo_wardriving_web/features/marauder/domain/marauder_models.dart';

void main() {
  group('parseGpsTelemetryLine', () {
    test('parses fix and satellites', () {
      final fix = parseGpsTelemetryLine('Good Fix: Yes');
      expect(fix?.fix, isTrue);

      final sats = parseGpsTelemetryLine('Sats: 8');
      expect(sats?.sats, 8);
    });

    test('parses lat lon alt accuracy datetime', () {
      final lat = parseGpsTelemetryLine('Lat: 25.6866');
      expect(lat?.lat, '25.6866');

      final lon = parseGpsTelemetryLine('Lon: -100.3161');
      expect(lon?.lon, '-100.3161');

      final alt = parseGpsTelemetryLine('Alt: 540.2');
      expect(alt?.alt, '540.2');

      final acc = parseGpsTelemetryLine('Accuracy: 3.5');
      expect(acc?.accuracy, '3.5');

      final dt = parseGpsTelemetryLine('Date/Time: 2026-06-29 12:00:00');
      expect(dt?.datetime, '2026-06-29 12:00:00');
    });

    test('strips HTML tags', () {
      final result = parseGpsTelemetryLine('<span>Fix: No</span>');
      expect(result?.fix, isFalse);
    });
  });

  group('mergeGpsTelemetry', () {
    test('merges partial updates', () {
      const base = GpsTelemetry(fix: true, sats: 5);
      final merged = mergeGpsTelemetry(
        base,
        const GpsTelemetry(lat: '1.0', lon: '2.0'),
      );
      expect(merged.fix, isTrue);
      expect(merged.sats, 5);
      expect(merged.lat, '1.0');
      expect(merged.lon, '2.0');
    });
  });

  group('isGpsLogLine', () {
    test('matches NMEA and telemetry prefixes', () {
      expect(isGpsLogLine('Fix: Yes'), isTrue);
      expect(isGpsLogLine('\$GPGGA,123519,4807.038,N'), isTrue);
      expect(isGpsLogLine('random log line'), isFalse);
    });
  });
}

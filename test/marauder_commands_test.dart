import 'package:flutter_test/flutter_test.dart';
import 'package:lilygo_wardriving_web/features/marauder/domain/marauder_commands.dart';

void main() {
  group('isContinuousCommand', () {
    test('detects scanap as continuous', () {
      expect(isContinuousCommand('scanap'), isTrue);
    });

    test('detects gps tracker as continuous', () {
      expect(isContinuousCommand('gps -t'), isTrue);
    });

    test('stopscan is not continuous', () {
      expect(isContinuousCommand('stopscan'), isFalse);
    });

    test('list -a is not continuous', () {
      expect(isContinuousCommand('list -a'), isFalse);
    });
  });

  group('isCommandFailure', () {
    test('detects GPS not found', () {
      expect(isCommandFailure('GPS Not Found'), isTrue);
    });

    test('ignores normal output', () {
      expect(isCommandFailure('Starting AP scan'), isFalse);
    });
  });
}

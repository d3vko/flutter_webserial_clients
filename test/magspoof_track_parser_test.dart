import 'package:flutter_test/flutter_test.dart';
import 'package:lilygo_wardriving_web/features/magspoof/domain/track_models.dart';
import 'package:lilygo_wardriving_web/features/magspoof/domain/track_parser.dart';

void main() {
  const track1 = '%B1234567890123456^TEST/USER^300112300000000000?';
  const track2 = ';1234567890123456=300112300000?';

  test('parses valid track 1 line', () {
    final record = parseTrackLine(track1, sourceCommand: 'track_1_editor');
    expect(record, isNotNull);
    expect(record!.trackType, TrackType.track1);
    expect(record.pan, '1234567890123456');
    expect(record.cardholderName, 'TEST / USER');
    expect(record.expiration, '3001');
    expect(record.serviceCode, '123');
    expect(record.parseStatus, ParseStatus.valid);
  });

  test('parses valid track 2 line', () {
    final record = parseTrackLine(track2);
    expect(record, isNotNull);
    expect(record!.trackType, TrackType.track2);
    expect(record.pan, '1234567890123456');
    expect(record.parseStatus, ParseStatus.valid);
  });

  test('marks partial track as invalid', () {
    final record = parseTrackLine('%B1234567890123456^TEST');
    expect(record, isNotNull);
    expect(record!.parseStatus, ParseStatus.invalid);
  });

  test('parseSerialChunk extracts track from stream', () {
    final result = parseSerialChunk(
      'prefix $track1 suffix',
      '',
      sourceCommand: 'd',
    );
    expect(result.records, hasLength(1));
    expect(result.records.first.pan, '1234567890123456');
    expect(result.buffer, ' suffix');
  });

  test('parseSerialChunk keeps partial buffer', () {
    final result = parseSerialChunk('%B123456', '', sourceCommand: '');
    expect(result.records, isEmpty);
    expect(result.buffer, '%B123456');
  });

  test('parseBufferedLine parses remaining buffer', () {
    final records = parseBufferedLine(track2, sourceCommand: 'e');
    expect(records, hasLength(1));
    expect(records.first.trackType, TrackType.track2);
  });
}

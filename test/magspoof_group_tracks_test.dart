import 'package:flutter_test/flutter_test.dart';
import 'package:lilygo_wardriving_web/features/magspoof/domain/group_tracks.dart';
import 'package:lilygo_wardriving_web/features/magspoof/domain/track_models.dart';

void main() {
  final createdAt = DateTime.utc(2026, 1, 1);

  test('groups track 1 and track 2 by pan', () {
    final records = [
      TrackRecord(
        id: '1',
        trackType: TrackType.track1,
        pan: '1234567890123456',
        cardholderName: 'TEST / USER',
        expiration: '3001',
        serviceCode: '123',
        discretionaryData: '',
        rawValue: '%B1234567890123456^TEST/USER^300112300000000000?',
        sourceCommand: 'track_1_editor',
        parseStatus: ParseStatus.valid,
        createdAt: createdAt,
      ),
      TrackRecord(
        id: '2',
        trackType: TrackType.track2,
        pan: '1234567890123456',
        cardholderName: '',
        expiration: '3001',
        serviceCode: '123',
        discretionaryData: '',
        rawValue: ';1234567890123456=300112300000?',
        sourceCommand: 'track_2_editor',
        parseStatus: ParseStatus.valid,
        createdAt: createdAt,
      ),
    ];

    final grouped = groupTrackRecords(records);
    expect(grouped, hasLength(1));
    expect(grouped.first.pan, '1234567890123456');
    expect(grouped.first.track1RawValue, records[0].rawValue);
    expect(grouped.first.track2RawValue, records[1].rawValue);
    expect(grouped.first.sourceCommand, 'track_1_editor; track_2_editor');
  });
}

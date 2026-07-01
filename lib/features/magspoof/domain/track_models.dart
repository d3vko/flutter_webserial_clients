enum TrackType { track1, track2 }

enum ParseStatus { valid, invalid }

enum MagspoofTableView { tracks, grouped }

enum MagspoofExportMode { masked, full }

class TrackRecord {
  TrackRecord({
    required this.id,
    required this.trackType,
    required this.pan,
    required this.cardholderName,
    required this.expiration,
    required this.serviceCode,
    required this.discretionaryData,
    required this.rawValue,
    required this.sourceCommand,
    required this.parseStatus,
    required this.createdAt,
  });

  final String id;
  final TrackType trackType;
  final String pan;
  final String cardholderName;
  final String expiration;
  final String serviceCode;
  final String discretionaryData;
  final String rawValue;
  final String sourceCommand;
  final ParseStatus parseStatus;
  final DateTime createdAt;

  String get trackTypeLabel =>
      trackType == TrackType.track1 ? 'track_1' : 'track_2';

  String get parseStatusLabel =>
      parseStatus == ParseStatus.valid ? 'valid' : 'invalid';

  Map<String, String> toTrackRow() => {
    'track_type': trackTypeLabel,
    'parse_status': parseStatusLabel,
    'pan': pan,
    'cardholder_name': cardholderName,
    'expiration': expiration,
    'service_code': serviceCode,
    'discretionary_data': discretionaryData,
    'raw_value': rawValue,
    'source_command': sourceCommand,
    'created_at': createdAt.toIso8601String(),
  };
}

class GroupedTrackRecord {
  GroupedTrackRecord({
    required this.pan,
    required this.cardholderName,
    required this.expiration,
    required this.serviceCode,
    required this.track1RawValue,
    required this.track2RawValue,
    required this.track1Status,
    required this.track2Status,
    required this.sourceCommand,
    required this.createdAt,
  });

  final String pan;
  final String cardholderName;
  final String expiration;
  final String serviceCode;
  final String track1RawValue;
  final String track2RawValue;
  final String track1Status;
  final String track2Status;
  final String sourceCommand;
  final DateTime createdAt;

  Map<String, String> toGroupedRow() => {
    'pan': pan,
    'cardholder_name': cardholderName,
    'expiration': expiration,
    'service_code': serviceCode,
    'track_1_raw_value': track1RawValue,
    'track_2_raw_value': track2RawValue,
    'track_1_status': track1Status,
    'track_2_status': track2Status,
    'source_command': sourceCommand,
    'created_at': createdAt.toIso8601String(),
  };
}

import 'track_models.dart';

List<GroupedTrackRecord> groupTrackRecords(List<TrackRecord> records) {
  final groups = <String, GroupedTrackRecord>{};

  for (final record in records) {
    final key = record.pan.isNotEmpty ? record.pan : 'invalid:${record.id}';
    final existing = groups[key];
    final base =
        existing ??
        GroupedTrackRecord(
          pan: record.pan,
          cardholderName: '',
          expiration: '',
          serviceCode: '',
          track1RawValue: '',
          track2RawValue: '',
          track1Status: '',
          track2Status: '',
          sourceCommand: '',
          createdAt: record.createdAt,
        );

    var next = base;
    if (record.trackType == TrackType.track1) {
      next = GroupedTrackRecord(
        pan: record.pan.isNotEmpty ? record.pan : base.pan,
        cardholderName: record.cardholderName.isNotEmpty
            ? record.cardholderName
            : base.cardholderName,
        expiration: record.expiration.isNotEmpty
            ? record.expiration
            : base.expiration,
        serviceCode: record.serviceCode.isNotEmpty
            ? record.serviceCode
            : base.serviceCode,
        track1RawValue: record.rawValue,
        track2RawValue: base.track2RawValue,
        track1Status: record.parseStatusLabel,
        track2Status: base.track2Status,
        sourceCommand: _mergeCommands(base.sourceCommand, record.sourceCommand),
        createdAt: base.createdAt,
      );
    } else {
      next = GroupedTrackRecord(
        pan: record.pan.isNotEmpty ? record.pan : base.pan,
        cardholderName: base.cardholderName,
        expiration: record.expiration.isNotEmpty
            ? record.expiration
            : base.expiration,
        serviceCode: record.serviceCode.isNotEmpty
            ? record.serviceCode
            : base.serviceCode,
        track1RawValue: base.track1RawValue,
        track2RawValue: record.rawValue,
        track1Status: base.track1Status,
        track2Status: record.parseStatusLabel,
        sourceCommand: _mergeCommands(base.sourceCommand, record.sourceCommand),
        createdAt: base.createdAt,
      );
    }

    groups[key] = next;
  }

  return groups.values.toList();
}

String _mergeCommands(String current, String next) {
  if (next.isEmpty) return current;
  if (current.isEmpty) return next;
  return current.contains(next) ? current : '$current; $next';
}

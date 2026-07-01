import 'track_models.dart';

final _track1Re = RegExp(
  r'%B([0-9]{1,19})\^([^^?]*)\^([0-9]{4})([0-9]{3})([^?]*)\?',
);
final _track1GlobalRe = RegExp(
  r'%B([0-9]{1,19})\^([^^?]*)\^([0-9]{4})([0-9]{3})([^?]*)\?',
  multiLine: true,
);
final _track1PartialRe = RegExp(r'%B[^?]*');
final _track2Re = RegExp(r';([0-9]{1,19})=([0-9]{4})([0-9]{3})([^?]*)\?');
final _track2GlobalRe = RegExp(
  r';([0-9]{1,19})=([0-9]{4})([0-9]{3})([^?]*)\?',
  multiLine: true,
);
final _track2PartialRe = RegExp(r';[0-9]{1,19}=[^?]*');

int _recordId = 0;

String _nextId() => 'track-${++_recordId}';

TrackRecord? parseTrackLine(String line, {String sourceCommand = ''}) {
  final clean = line.trim();
  if (clean.isEmpty) return null;

  final track1 = _track1Re.firstMatch(clean);
  if (track1 != null) {
    return _validTrack1(track1, sourceCommand);
  }

  final track2 = _track2Re.firstMatch(clean);
  if (track2 != null) {
    return _validTrack2(track2, sourceCommand);
  }

  final partial1 = _track1PartialRe.firstMatch(clean);
  if (partial1 != null) {
    return _invalidRow(TrackType.track1, partial1.group(0)!, sourceCommand);
  }

  final partial2 = _track2PartialRe.firstMatch(clean);
  if (partial2 != null) {
    return _invalidRow(TrackType.track2, partial2.group(0)!, sourceCommand);
  }

  return null;
}

class SerialChunkParseResult {
  const SerialChunkParseResult({required this.records, required this.buffer});

  final List<TrackRecord> records;
  final String buffer;
}

SerialChunkParseResult parseSerialChunk(
  String chunk,
  String buffer, {
  String sourceCommand = '',
}) {
  final combined = '$buffer$chunk';
  final parsed = _parseTrackText(combined, sourceCommand);

  if (parsed.records.isNotEmpty) {
    return SerialChunkParseResult(
      records: parsed.records,
      buffer: _keepRelevantBuffer(combined.substring(parsed.lastTrackEnd)),
    );
  }

  final lines = combined.split(RegExp(r'\r?\n'));
  final nextBuffer = lines.isEmpty ? '' : lines.removeLast();
  final invalidRecords = <TrackRecord>[];
  for (final line in lines) {
    final record = parseTrackLine(line, sourceCommand: sourceCommand);
    if (record != null) invalidRecords.add(record);
  }

  return SerialChunkParseResult(
    records: invalidRecords,
    buffer: _keepRelevantBuffer(nextBuffer),
  );
}

List<TrackRecord> parseBufferedLine(
  String buffer, {
  String sourceCommand = '',
}) {
  final parsed = _parseTrackText(buffer, sourceCommand);
  if (parsed.records.isNotEmpty) return parsed.records;
  final single = parseTrackLine(buffer, sourceCommand: sourceCommand);
  return single == null ? [] : [single];
}

class _TrackTextParseResult {
  const _TrackTextParseResult({
    required this.records,
    required this.lastTrackEnd,
  });

  final List<TrackRecord> records;
  final int lastTrackEnd;
}

_TrackTextParseResult _parseTrackText(String text, String sourceCommand) {
  final matches = <_TrackMatch>[
    ..._findMatches(text, _track1GlobalRe, TrackType.track1, sourceCommand),
    ..._findMatches(text, _track2GlobalRe, TrackType.track2, sourceCommand),
  ]..sort((a, b) => a.index.compareTo(b.index));

  final seen = <String>{};
  final records = <TrackRecord>[];
  var lastTrackEnd = 0;

  for (final match in matches) {
    final dedupeKey = '${match.record.trackTypeLabel}:${match.record.rawValue}';
    lastTrackEnd = match.end > lastTrackEnd ? match.end : lastTrackEnd;
    if (seen.contains(dedupeKey)) continue;
    seen.add(dedupeKey);
    records.add(match.record);
  }

  return _TrackTextParseResult(records: records, lastTrackEnd: lastTrackEnd);
}

class _TrackMatch {
  const _TrackMatch({
    required this.index,
    required this.end,
    required this.record,
  });

  final int index;
  final int end;
  final TrackRecord record;
}

List<_TrackMatch> _findMatches(
  String text,
  RegExp regex,
  TrackType trackType,
  String sourceCommand,
) {
  return regex.allMatches(text).map((match) {
    final record = trackType == TrackType.track1
        ? _validTrack1(match, sourceCommand)
        : _validTrack2(match, sourceCommand);
    return _TrackMatch(index: match.start, end: match.end, record: record);
  }).toList();
}

TrackRecord _validTrack1(RegExpMatch match, String sourceCommand) {
  return TrackRecord(
    id: _nextId(),
    trackType: TrackType.track1,
    pan: match.group(1)!,
    cardholderName: _normalizeName(match.group(2)!),
    expiration: match.group(3)!,
    serviceCode: match.group(4)!,
    discretionaryData: match.group(5) ?? '',
    rawValue: match.group(0)!,
    sourceCommand: sourceCommand,
    parseStatus: ParseStatus.valid,
    createdAt: DateTime.now().toUtc(),
  );
}

TrackRecord _validTrack2(RegExpMatch match, String sourceCommand) {
  return TrackRecord(
    id: _nextId(),
    trackType: TrackType.track2,
    pan: match.group(1)!,
    cardholderName: '',
    expiration: match.group(2)!,
    serviceCode: match.group(3)!,
    discretionaryData: match.group(4) ?? '',
    rawValue: match.group(0)!,
    sourceCommand: sourceCommand,
    parseStatus: ParseStatus.valid,
    createdAt: DateTime.now().toUtc(),
  );
}

TrackRecord _invalidRow(
  TrackType trackType,
  String rawValue,
  String sourceCommand,
) {
  return TrackRecord(
    id: _nextId(),
    trackType: trackType,
    pan: '',
    cardholderName: '',
    expiration: '',
    serviceCode: '',
    discretionaryData: '',
    rawValue: rawValue,
    sourceCommand: sourceCommand,
    parseStatus: ParseStatus.invalid,
    createdAt: DateTime.now().toUtc(),
  );
}

String _keepRelevantBuffer(String value) {
  final partialTrack1Index = value.lastIndexOf('%B');
  final partialTrack2Index = value.lastIndexOf(';');
  final partialStart = partialTrack1Index > partialTrack2Index
      ? partialTrack1Index
      : partialTrack2Index;
  if (partialStart >= 0) return value.substring(partialStart);
  return value;
}

String _normalizeName(String value) {
  return value.trim().replaceAll('/', ' / ');
}

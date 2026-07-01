import 'marauder_models.dart';
import 'wardrive_schema.dart';

const baseAppRelease = 'PwnterreyESP32Marauder';

List<String> _extendedKeys(List<WardriveEntry> entries) {
  const candidates = ['last_seen', 'frequency'];
  return candidates
      .where(
        (key) => entries.any((entry) {
          final value = key == 'last_seen' ? entry.lastSeen : entry.frequency;
          return value.trim().isNotEmpty;
        }),
      )
      .toList();
}

String _metaLine(WardriveDialect? dialect) {
  final release = (dialect?.appRelease.isNotEmpty ?? false)
      ? dialect!.appRelease
      : baseAppRelease;
  return 'WigleWifi-1.4,appRelease=$release';
}

String _columnHeader(List<String> extKeys) {
  const base = [
    'MAC',
    'SSID',
    'AuthMode',
    'FirstSeen',
    'Channel',
    'RSSI',
    'CurrentLatitude',
    'CurrentLongitude',
    'AltitudeMeters',
    'AccuracyMeters',
    'Type',
  ];
  final extended = extKeys.map((k) => canonicalToColumn14[k] ?? k).toList();
  return [...base, ...extended].join(',');
}

String _entryRow(WardriveEntry entry, List<String> extKeys) {
  final base = [
    entry.mac,
    entry.ssid,
    entry.security,
    entry.firstSeen,
    entry.channel,
    entry.rssi,
    entry.latitude,
    entry.longitude,
    entry.altitude,
    entry.accuracy,
    entry.type,
  ];
  final extended = extKeys.map((key) {
    return switch (key) {
      'last_seen' => entry.lastSeen,
      'frequency' => entry.frequency,
      _ => '',
    };
  });
  return [...base, ...extended].join(',');
}

String buildWardriveCsvString(
  List<WardriveEntry> entries, [
  WardriveDialect? dialect,
]) {
  final extKeys = _extendedKeys(entries);
  final lines = <String>[
    _metaLine(dialect),
    _columnHeader(extKeys),
    ...entries.map((entry) => _entryRow(entry, extKeys)),
  ];
  return lines.join('\n');
}

String wardriveCsvFileName() {
  final stamp = DateTime.now()
      .toIso8601String()
      .substring(0, 19)
      .replaceAll(':', '-');
  return 'wardrive_$stamp.csv';
}

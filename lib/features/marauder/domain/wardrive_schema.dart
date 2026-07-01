import 'marauder_models.dart';

const headerAliases = <String, List<String>>{
  'mac': ['MAC', 'BSSID', 'netid'],
  'ssid': ['SSID', 'ssid'],
  'security': ['AuthMode', 'Capabilities', 'Encryption', 'AuthType', 'wep'],
  'first_seen': ['FirstSeen', 'firsttime'],
  'last_seen': ['LastSeen'],
  'channel': ['Channel', 'channel'],
  'frequency': ['Frequency', 'freq'],
  'rssi': ['RSSI', 'Signal'],
  'latitude': ['CurrentLatitude', 'Latitude', 'trilat'],
  'longitude': ['CurrentLongitude', 'Longitude', 'trilong'],
  'altitude': ['AltitudeMeters', 'Altitude'],
  'accuracy': ['AccuracyMeters', 'Accuracy'],
  'type': ['Type', 'RadioType'],
};

const canonicalToColumn14 = <String, String>{
  'mac': 'MAC',
  'ssid': 'SSID',
  'security': 'AuthMode',
  'first_seen': 'FirstSeen',
  'last_seen': 'LastSeen',
  'channel': 'Channel',
  'frequency': 'Frequency',
  'rssi': 'RSSI',
  'latitude': 'CurrentLatitude',
  'longitude': 'CurrentLongitude',
  'altitude': 'AltitudeMeters',
  'accuracy': 'AccuracyMeters',
  'type': 'Type',
};

final _aliasToCanonical = <String, String>{
  for (final entry in headerAliases.entries)
    for (final alias in entry.value) alias: entry.key,
};

final _wigleMetaRe = RegExp(
  r'^WigleWifi-(\d+\.\d+)(?:,(.*))?$',
  caseSensitive: false,
);
final _wigleLegacyColumnsRe = RegExp(r'^netid,ssid', caseSensitive: false);

WardriveDialect? detectMetaLine(String line) {
  final wigleMatch = _wigleMetaRe.firstMatch(line);
  if (wigleMatch != null) {
    final version = wigleMatch.group(1)!;
    final rest = wigleMatch.group(2) ?? '';
    final releaseMatch = RegExp(r'appRelease=([^,]+)').firstMatch(rest);
    return WardriveDialect(
      sourceFormat: 'WigleWifi',
      sourceVersion: version,
      appRelease: releaseMatch?.group(1) ?? '',
      metaLine: line,
    );
  }

  if (_wigleLegacyColumnsRe.hasMatch(line)) {
    return const WardriveDialect(
      sourceFormat: 'WigleLegacy',
      sourceVersion: 'legacy',
      metaLine: 'netid,ssid,...',
    );
  }

  return null;
}

WardriveColumnMapping? buildColumnMapping(String headerRow) {
  final columns = headerRow.split(',').map((c) => c.trim()).toList();
  final indexByCanonical = <String, int>{};

  for (var i = 0; i < columns.length; i++) {
    final canonical = _aliasToCanonical[columns[i]];
    if (canonical != null && !indexByCanonical.containsKey(canonical)) {
      indexByCanonical[canonical] = i;
    }
  }

  if (!indexByCanonical.containsKey('mac')) {
    return null;
  }

  return WardriveColumnMapping(
    columns: columns,
    indexByCanonical: indexByCanonical,
  );
}

final defaultMapping14 = buildColumnMapping(
  'MAC,SSID,AuthMode,FirstSeen,Channel,RSSI,'
  'CurrentLatitude,CurrentLongitude,AltitudeMeters,AccuracyMeters,Type',
)!;

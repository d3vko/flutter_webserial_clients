import 'marauder_models.dart';
import 'wardrive_schema.dart';

final _macRe = RegExp(r'^([0-9a-fA-F]{2}:){5}[0-9a-fA-F]{2}$');
final _macInTextRe = RegExp(r'([0-9a-fA-F]{2}:){5}[0-9a-fA-F]{2}');
final _serialCounterRe = RegExp(r'^\d+\s*\|\s*');
final _bufferMarkerRe = RegExp(
  r'^\s*\[BUF\/(?:BEGIN|CLOSE)\]\s*',
  caseSensitive: false,
);

String normalizeWardriveLine(String line) {
  var normalized = (line).replaceAll(RegExp(r'<[^>]+>'), '').trim();

  while (_bufferMarkerRe.hasMatch(normalized)) {
    normalized = normalized.replaceFirst(_bufferMarkerRe, '').trim();
  }

  normalized = normalized.replaceFirst(_serialCounterRe, '').trim();

  while (_bufferMarkerRe.hasMatch(normalized)) {
    normalized = normalized.replaceFirst(_bufferMarkerRe, '').trim();
    normalized = normalized.replaceFirst(_serialCounterRe, '').trim();
  }

  return normalized;
}

WardriveDialect? parseWardriveMetaLine(String line) {
  final plain = normalizeWardriveLine(line);
  if (plain.isEmpty) return null;
  return detectMetaLine(plain);
}

WardriveColumnMapping? parseWardriveColumnHeader(String line) {
  final plain = normalizeWardriveLine(line);
  if (plain.isEmpty) return null;
  return buildColumnMapping(plain);
}

WardriveEntry? parseWardriveRow(
  String line, [
  WardriveColumnMapping? mapping,
  WardriveDialect? dialect,
]) {
  final plain = normalizeWardriveLine(line);
  if (plain.isEmpty) return null;

  final activeMapping = mapping ?? defaultMapping14;
  final indexByCanonical = activeMapping.indexByCanonical;

  final parts = plain.split(',');
  if (parts.length < 2) return null;

  final isBle = _isBleRow(parts, indexByCanonical);

  final rawMac = _get(parts, indexByCanonical['mac'], '');
  final resolved = _resolveMac(rawMac, isBle);
  final mac = resolved.mac;

  if (!_macRe.hasMatch(mac)) return null;

  final rawSsid = _get(parts, indexByCanonical['ssid'], '');
  final ssid = resolved.ssid ?? rawSsid;

  final typeValue = _get(parts, indexByCanonical['type'], '').trim();
  final type = typeValue.isNotEmpty ? typeValue : (isBle ? 'BLE' : 'WIFI');

  return WardriveEntry(
    mac: mac,
    ssid: ssid,
    security: _get(parts, indexByCanonical['security'], ''),
    firstSeen: _get(parts, indexByCanonical['first_seen'], ''),
    lastSeen: _get(parts, indexByCanonical['last_seen'], ''),
    channel: _get(parts, indexByCanonical['channel'], '').isEmpty
        ? '-'
        : _get(parts, indexByCanonical['channel'], ''),
    frequency: _get(parts, indexByCanonical['frequency'], ''),
    rssi: _get(parts, indexByCanonical['rssi'], ''),
    latitude: _get(parts, indexByCanonical['latitude'], ''),
    longitude: _get(parts, indexByCanonical['longitude'], ''),
    altitude: _get(parts, indexByCanonical['altitude'], ''),
    accuracy: _get(parts, indexByCanonical['accuracy'], ''),
    type: type,
    sourceFormat: dialect?.sourceFormat ?? '',
    sourceVersion: dialect?.sourceVersion ?? '',
  );
}

String wardriveEntryKey(WardriveEntry entry) {
  return [
    entry.mac.toLowerCase(),
    entry.firstSeen,
    entry.channel,
    entry.rssi,
    entry.latitude,
    entry.longitude,
    entry.altitude,
    entry.accuracy,
    entry.type,
  ].join('|');
}

String _get(List<String> parts, int? idx, String fallback) {
  if (idx == null) return fallback;
  if (idx < 0 || idx >= parts.length) return fallback;
  return parts[idx];
}

bool _isBleRow(List<String> parts, Map<String, int> indexByCanonical) {
  final secVal = _get(parts, indexByCanonical['security'], '').trim();
  final typeVal = _get(
    parts,
    indexByCanonical['type'],
    '',
  ).trim().toUpperCase();
  return secVal == '[BLE]' || typeVal == 'BLE';
}

({String mac, String? ssid}) _resolveMac(String rawMac, bool isBle) {
  final trimmed = rawMac.trim();

  if (_macRe.hasMatch(trimmed)) {
    return (mac: trimmed, ssid: null);
  }

  if (isBle) {
    final matches = _macInTextRe.allMatches(trimmed).toList();
    if (matches.isNotEmpty) {
      final last = matches.last;
      final mac = last.group(0)!;
      var prefix = trimmed.substring(0, last.start);
      if (prefix.toLowerCase() == mac.toLowerCase()) {
        prefix = '';
      }
      return (mac: mac, ssid: prefix.isEmpty ? null : prefix);
    }
  }

  return (mac: trimmed, ssid: null);
}

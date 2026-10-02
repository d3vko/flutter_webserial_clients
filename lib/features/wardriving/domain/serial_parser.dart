import 'models.dart';

const lteHeader =
    'Source,Timestamp,Tecnología,Estado,MCC,MNC,LAC,CellID,Banda,RSSI,RSRP,RSRQ,SINR,Operador,Longitud,Latitud';
const lteExtendedHeader =
    'Source,Timestamp,Tecnología,TipoCelda,Estado,MCC,MNC,LAC,CellID,eNodeB,Sector,PCI,Banda,EARFCN,FreqDL_MHz,FreqUL_MHz,RSSI,RSRP,RSRQ,SINR,Operador,Longitud,Latitud';
const wifiHeader = 'Source,Timestamp,Lat,Long,SSID,BSSID,Canal,Señal,Seguridad';
const bleHeader = 'Source,Timestamp,Lat,Long,Dirección,RSSI,Nombre';
const radioUnifiedHeader =
    'Source,MAC,SSID,AuthMode,FirstSeen,Channel,RSSI,CurrentLatitude,'
    'CurrentLongitude,AltitudeMeters,AccuracyMeters,Type';

final _lteHeaders = {lteHeader, lteExtendedHeader};

const _legacyHeaderByType = <ScanType, String>{
  ScanType.wifi: wifiHeader,
  ScanType.ble: bleHeader,
};

enum RadioRowFormat { legacySpanish, wigleUnified, wigleWifi14 }

final _wigleMetaRe = RegExp(r'^WigleWifi-(\d+\.\d+)', caseSensitive: false);
final _macRe = RegExp(r'^([0-9a-fA-F]{2}:){5}[0-9a-fA-F]{2}$');
final _gpsKvRe = RegExp(r'(\w+)=((?:(?!\s+\w+=).)+)');
final _espIdfLogRe = RegExp(r'^[WEIDV]\s+\(\d+\)\s');
final _wigleTypeTailRe = RegExp(r',(WIFI|BLE|BT)\s*$', caseSensitive: false);

/// Minino custom RF Village column layout (matches USB_CSV_CONTRACT).
const _defaultMininoWigleHeader =
    'MAC,SSID,AuthMode,FirstSeen,Channel,Frequency,RSSI,'
    'CurrentLatitude,CurrentLongitude,AltitudeMeters,AccuracyMeters,'
    'RCOIs,MfgrId,Type';

/// Compact layout when firmware omits MfgrId (Type is last field).
const _mininoWigleHeaderNoMfgr =
    'MAC,SSID,AuthMode,FirstSeen,Channel,Frequency,RSSI,'
    'CurrentLatitude,CurrentLongitude,AltitudeMeters,AccuracyMeters,'
    'RCOIs,Type';


const _wigleHeaderAliases = <String, List<String>>{
  'mac': ['MAC', 'BSSID', 'netid'],
  'ssid': ['SSID', 'ssid'],
  'security': ['AuthMode', 'Capabilities', 'Encryption', 'AuthType', 'wep'],
  'first_seen': ['FirstSeen', 'firsttime'],
  'channel': ['Channel', 'channel'],
  'frequency': ['Frequency', 'freq'],
  'rssi': ['RSSI', 'Signal'],
  'latitude': ['CurrentLatitude', 'Latitude', 'trilat'],
  'longitude': ['CurrentLongitude', 'Longitude', 'trilong'],
  'altitude': ['AltitudeMeters', 'Altitude'],
  'accuracy': ['AccuracyMeters', 'Accuracy'],
  'type': ['Type', 'RadioType'],
};

final _aliasToCanonical = <String, String>{
  for (final entry in _wigleHeaderAliases.entries)
    for (final alias in entry.value) alias.toLowerCase(): entry.key,
};

/// Stateful parser that tracks active WiFi/BLE row format across a serial stream.
class SerialStreamParser {
  RadioRowFormat wifiFormat = RadioRowFormat.legacySpanish;
  RadioRowFormat bleFormat = RadioRowFormat.legacySpanish;
  String carry = '';
  Map<String, int>? wigleColumnIndex;
  bool wigleMode = false;

  List<ParsedSerialEvent> parseChunk(String chunk, {String capturedAt = ''}) {
    final effectiveCapturedAt = _effectiveCapturedAt(capturedAt);
    final normalized = '$carry$chunk'
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n');
    final parts = normalized.split('\n');
    carry = parts.isNotEmpty ? parts.removeLast() : '';

    return parts.map((line) => parseLine(line, effectiveCapturedAt)).toList();
  }

  List<ParsedSerialEvent> flush({String capturedAt = ''}) {
    if (carry.isEmpty) return [];
    final event = parseLine(carry, _effectiveCapturedAt(capturedAt));
    carry = '';
    return [event];
  }

  ParsedSerialEvent parseLine(String line, String capturedAt) {
    final trimmed = line.trim();

    if (trimmed.isEmpty) {
      return LogEvent(line: line);
    }

    if (trimmed.startsWith('#')) {
      return _parseHashDiag(trimmed);
    }

    if (_espIdfLogRe.hasMatch(trimmed)) {
      return LogEvent(line: trimmed);
    }

    if (_wigleMetaRe.hasMatch(trimmed)) {
      wigleMode = true;
      wigleColumnIndex ??= _columnIndexFromHeader(_defaultMininoWigleHeader);
      wifiFormat = RadioRowFormat.wigleWifi14;
      bleFormat = RadioRowFormat.wigleWifi14;
      return LogEvent(line: trimmed);
    }

    final wigleHeader = _tryBuildWigleColumnIndex(trimmed);
    if (wigleHeader != null) {
      wigleColumnIndex = wigleHeader;
      wigleMode = true;
      wifiFormat = RadioRowFormat.wigleWifi14;
      bleFormat = RadioRowFormat.wigleWifi14;
      return HeaderEvent(scanType: ScanType.wifi, line: trimmed);
    }

    final headerType = _headerForLine(trimmed);
    if (headerType != null) {
      _applyHeaderFormat(headerType, trimmed);
      return HeaderEvent(scanType: headerType, line: trimmed);
    }

    // Mid-stream connect: firmware already printed the header. Detect Wigle
    // rows by MAC + trailing Type=WIFI|BLE and parse with a default map.
    if (_looksLikeWigleDataRow(trimmed)) {
      wigleMode = true;
      wigleColumnIndex ??= _inferWigleColumnIndex(trimmed);
      wifiFormat = RadioRowFormat.wigleWifi14;
      bleFormat = RadioRowFormat.wigleWifi14;
      final wigleEvent = _parseWigleWifi14Row(trimmed, capturedAt);
      if (wigleEvent != null) return wigleEvent;
    }

    if (wigleMode && wigleColumnIndex != null) {
      final wigleEvent = _parseWigleWifi14Row(trimmed, capturedAt);
      if (wigleEvent != null) return wigleEvent;
    }

    final fields = parseCsvLine(trimmed);
    final source = fields.isNotEmpty ? fields.first.toLowerCase() : '';

    return switch (source) {
      'lte' => _parseLte(fields, trimmed, capturedAt),
      'wifi' => _parseWifi(fields, trimmed, capturedAt),
      'ble' => _parseBle(fields, trimmed, capturedAt),
      _ => LogEvent(line: line),
    };
  }

  ParsedSerialEvent _parseHashDiag(String trimmed) {
    if (!trimmed.startsWith('#GPS ')) {
      return LogEvent(line: trimmed);
    }

    // Firmware switch notice: "#GPS switch NEO6M baud=9600 ..."
    if (trimmed.startsWith('#GPS switch ')) {
      return LogEvent(line: trimmed);
    }

    final kv = <String, String>{
      for (final match in _gpsKvRe.allMatches(trimmed))
        match.group(1)!: match.group(2)!,
    };

    // Status lines need fix=…; otherwise keep as terminal log.
    if (!kv.containsKey('fix')) {
      return LogEvent(line: trimmed);
    }

    return GpsDiagEvent(
      line: trimmed,
      source: kv['backend'] ?? kv['src'] ?? '',
      status: kv['status'] ?? '',
      fix: int.tryParse(kv['fix'] ?? '') ?? 0,
      sats: int.tryParse(kv['sats'] ?? '') ?? 0,
      latitude: kv['lat'] ?? '',
      longitude: kv['lon'] ?? '',
      timestamp: kv['ts'] ?? '',
    );
  }

  void _applyHeaderFormat(ScanType scanType, String line) {
    if (line == radioUnifiedHeader) {
      wifiFormat = RadioRowFormat.wigleUnified;
      bleFormat = RadioRowFormat.wigleUnified;
      wigleMode = false;
      wigleColumnIndex = null;
      return;
    }

    if (scanType == ScanType.wifi) {
      wifiFormat = RadioRowFormat.legacySpanish;
      wigleMode = false;
      wigleColumnIndex = null;
    } else if (scanType == ScanType.ble) {
      bleFormat = RadioRowFormat.legacySpanish;
    }
  }

  RadioRowFormat _wifiFormatFor(List<String> fields) {
    if (fields.length >= 12) return RadioRowFormat.wigleUnified;
    return wifiFormat;
  }

  RadioRowFormat _bleFormatFor(List<String> fields) {
    if (fields.length >= 12) return RadioRowFormat.wigleUnified;
    return bleFormat;
  }

  ParsedSerialEvent _parseLte(
    List<String> fields,
    String line,
    String capturedAt,
  ) {
    if (fields.length >= 20) {
      return _parseLteExtended(fields, line, capturedAt);
    }
    return _parseLteLegacy(fields, line, capturedAt);
  }

  ParsedSerialEvent _parseWifi(
    List<String> fields,
    String line,
    String capturedAt,
  ) {
    return switch (_wifiFormatFor(fields)) {
      RadioRowFormat.wigleUnified => _parseWifiUnified(
        fields,
        line,
        capturedAt,
      ),
      RadioRowFormat.legacySpanish => _parseWifiLegacy(
        fields,
        line,
        capturedAt,
      ),
      RadioRowFormat.wigleWifi14 => _parseWifiUnified(
        fields,
        line,
        capturedAt,
      ),
    };
  }

  ParsedSerialEvent _parseBle(
    List<String> fields,
    String line,
    String capturedAt,
  ) {
    return switch (_bleFormatFor(fields)) {
      RadioRowFormat.wigleUnified => _parseBleUnified(fields, line, capturedAt),
      RadioRowFormat.legacySpanish => _parseBleLegacy(fields, line, capturedAt),
      RadioRowFormat.wigleWifi14 => _parseBleUnified(fields, line, capturedAt),
    };
  }

  ParsedSerialEvent _parseLteLegacy(
    List<String> fields,
    String line,
    String capturedAt,
  ) {
    final longitude = fields.length > 14 ? fields[14] : '';
    final latitude = fields.length > 15 ? fields[15] : '';

    if (!_hasUsableCoordinates(latitude, longitude)) {
      return _invalidCoordinates(ScanType.lte, line);
    }

    return LteEvent(
      line: line,
      record: LteRecord(
        timestamp: fields.length > 1 ? fields[1] : '',
        technology: fields.length > 2 ? fields[2] : '',
        cellType: '',
        status: fields.length > 3 ? fields[3] : '',
        mcc: fields.length > 4 ? fields[4] : '',
        mnc: fields.length > 5 ? fields[5] : '',
        lac: fields.length > 6 ? fields[6] : '',
        cellId: fields.length > 7 ? fields[7] : '',
        eNodeB: '',
        sector: '',
        pci: '',
        band: fields.length > 8 ? fields[8] : '',
        earfcn: '',
        freqDlMhz: '',
        freqUlMhz: '',
        rssi: fields.length > 9 ? fields[9] : '',
        rsrp: fields.length > 10 ? fields[10] : '',
        rsrq: fields.length > 11 ? fields[11] : '',
        sinr: fields.length > 12 ? fields[12] : '',
        operator: fields.length > 13 ? fields[13] : '',
        longitude: longitude,
        latitude: latitude,
        capturedAt: capturedAt,
      ),
    );
  }

  ParsedSerialEvent _parseLteExtended(
    List<String> fields,
    String line,
    String capturedAt,
  ) {
    final longitude = fields.length > 21 ? fields[21] : '';
    final latitude = fields.length > 22 ? fields[22] : '';

    if (!_hasUsableCoordinates(latitude, longitude)) {
      return _invalidCoordinates(ScanType.lte, line);
    }

    return LteEvent(
      line: line,
      record: LteRecord(
        timestamp: fields.length > 1 ? fields[1] : '',
        technology: fields.length > 2 ? fields[2] : '',
        cellType: fields.length > 3 ? fields[3] : '',
        status: fields.length > 4 ? fields[4] : '',
        mcc: fields.length > 5 ? fields[5] : '',
        mnc: fields.length > 6 ? fields[6] : '',
        lac: fields.length > 7 ? fields[7] : '',
        cellId: fields.length > 8 ? fields[8] : '',
        eNodeB: fields.length > 9 ? fields[9] : '',
        sector: fields.length > 10 ? fields[10] : '',
        pci: fields.length > 11 ? fields[11] : '',
        band: fields.length > 12 ? fields[12] : '',
        earfcn: fields.length > 13 ? fields[13] : '',
        freqDlMhz: fields.length > 14 ? fields[14] : '',
        freqUlMhz: fields.length > 15 ? fields[15] : '',
        rssi: fields.length > 16 ? fields[16] : '',
        rsrp: fields.length > 17 ? fields[17] : '',
        rsrq: fields.length > 18 ? fields[18] : '',
        sinr: fields.length > 19 ? fields[19] : '',
        operator: fields.length > 20 ? fields[20] : '',
        longitude: longitude,
        latitude: latitude,
        capturedAt: capturedAt,
      ),
    );
  }

  ParsedSerialEvent _parseWifiLegacy(
    List<String> fields,
    String line,
    String capturedAt,
  ) {
    final latitude = fields.length > 2 ? fields[2] : '';
    final longitude = fields.length > 3 ? fields[3] : '';

    if (!_hasUsableCoordinates(latitude, longitude)) {
      return _invalidCoordinates(ScanType.wifi, line);
    }

    return WifiEvent(
      line: line,
      record: WifiRecord(
        timestamp: fields.length > 1 ? fields[1] : '',
        latitude: latitude,
        longitude: longitude,
        ssid: fields.length > 4 ? fields[4] : '',
        bssid: fields.length > 5 ? fields[5] : '',
        channel: fields.length > 6 ? fields[6] : '',
        signal: fields.length > 7 ? fields[7] : '',
        security: fields.length > 8 ? fields[8] : '',
        capturedAt: capturedAt,
        radioType: 'WIFI',
      ),
    );
  }

  ParsedSerialEvent _parseWifiUnified(
    List<String> fields,
    String line,
    String capturedAt,
  ) {
    final latitude = fields.length > 7 ? fields[7] : '';
    final longitude = fields.length > 8 ? fields[8] : '';

    if (!_hasUsableCoordinates(latitude, longitude)) {
      return _invalidCoordinates(ScanType.wifi, line);
    }

    return WifiEvent(
      line: line,
      record: WifiRecord(
        timestamp: fields.length > 4 ? fields[4] : '',
        latitude: latitude,
        longitude: longitude,
        ssid: fields.length > 2 ? fields[2] : '',
        bssid: fields.length > 1 ? fields[1] : '',
        channel: fields.length > 5 ? fields[5] : '',
        signal: fields.length > 6 ? fields[6] : '',
        security: fields.length > 3 ? fields[3] : '',
        capturedAt: capturedAt,
        altitudeMeters: fields.length > 9 ? fields[9] : '',
        accuracyMeters: fields.length > 10 ? fields[10] : '',
        radioType: fields.length > 11 ? fields[11] : 'WIFI',
      ),
    );
  }

  ParsedSerialEvent _parseBleLegacy(
    List<String> fields,
    String line,
    String capturedAt,
  ) {
    final latitude = fields.length > 2 ? fields[2] : '';
    final longitude = fields.length > 3 ? fields[3] : '';

    if (!_hasUsableCoordinates(latitude, longitude)) {
      return _invalidCoordinates(ScanType.ble, line);
    }

    final name = fields.length > 6 ? fields[6] : '';

    return BleEvent(
      line: line,
      record: BleRecord(
        timestamp: fields.length > 1 ? fields[1] : '',
        latitude: latitude,
        longitude: longitude,
        address: fields.length > 4 ? fields[4] : '',
        rssi: fields.length > 5 ? fields[5] : '',
        ssid: name,
        capturedAt: capturedAt,
        radioType: 'BLE',
      ),
    );
  }

  ParsedSerialEvent _parseBleUnified(
    List<String> fields,
    String line,
    String capturedAt,
  ) {
    final latitude = fields.length > 7 ? fields[7] : '';
    final longitude = fields.length > 8 ? fields[8] : '';

    if (!_hasUsableCoordinates(latitude, longitude)) {
      return _invalidCoordinates(ScanType.ble, line);
    }

    return BleEvent(
      line: line,
      record: BleRecord(
        timestamp: fields.length > 4 ? fields[4] : '',
        latitude: latitude,
        longitude: longitude,
        address: fields.length > 1 ? fields[1] : '',
        rssi: fields.length > 6 ? fields[6] : '',
        ssid: fields.length > 2 ? fields[2] : '',
        channel: fields.length > 5 ? fields[5] : '',
        security: fields.length > 3 ? fields[3] : '',
        capturedAt: capturedAt,
        altitudeMeters: fields.length > 9 ? fields[9] : '',
        accuracyMeters: fields.length > 10 ? fields[10] : '',
        radioType: fields.length > 11 ? fields[11] : 'BLE',
      ),
    );
  }

  ParsedSerialEvent? _parseWigleWifi14Row(String line, String capturedAt) {
    final index = wigleColumnIndex;
    if (index == null) return null;

    final fields = parseCsvLine(line);
    if (fields.length < 2) return null;

    final mac = _getByCanonical(fields, index, 'mac');
    if (!_macRe.hasMatch(mac)) return null;

    var type = _getByCanonical(fields, index, 'type').trim().toUpperCase();
    // Firmware sometimes omits MfgrId so Type sits one column earlier / last.
    if (type.isEmpty && fields.isNotEmpty) {
      final tail = fields.last.trim().toUpperCase();
      if (tail == 'WIFI' || tail == 'BLE' || tail == 'BT') {
        type = tail;
      }
    }

    final security = _getByCanonical(fields, index, 'security');
    final isBle = type == 'BLE' || security == '[BLE]' || security == 'BLE';
    var latitude = _getByCanonical(fields, index, 'latitude');
    var longitude = _getByCanonical(fields, index, 'longitude');
    var activeIndex = index;

    // If header map is misaligned (missing MfgrId), recover with compact layout.
    if (!_hasParseableCoordinates(latitude, longitude) &&
        fields.length >= 10 &&
        type.isNotEmpty) {
      final compact = _inferWigleColumnIndex(line);
      final compactLat = _getByCanonical(fields, compact, 'latitude');
      final compactLon = _getByCanonical(fields, compact, 'longitude');
      if (_hasParseableCoordinates(compactLat, compactLon)) {
        activeIndex = compact;
        latitude = compactLat;
        longitude = compactLon;
        wigleColumnIndex = compact;
      }
    }

    // Wigle rows may legitimately use 0.0 when GPS has no fix.
    if (!_hasParseableCoordinates(latitude, longitude)) {
      return _invalidCoordinates(isBle ? ScanType.ble : ScanType.wifi, line);
    }

    if (isBle) {
      return BleEvent(
        line: line,
        record: BleRecord(
          timestamp: _getByCanonical(fields, activeIndex, 'first_seen'),
          latitude: latitude,
          longitude: longitude,
          address: mac,
          rssi: _getByCanonical(fields, activeIndex, 'rssi'),
          ssid: _getByCanonical(fields, activeIndex, 'ssid'),
          channel: _getByCanonical(fields, activeIndex, 'channel'),
          security: security,
          capturedAt: capturedAt,
          altitudeMeters: _getByCanonical(fields, activeIndex, 'altitude'),
          accuracyMeters: _getByCanonical(fields, activeIndex, 'accuracy'),
          radioType: type.isEmpty ? 'BLE' : type,
        ),
      );
    }

    return WifiEvent(
      line: line,
      record: WifiRecord(
        timestamp: _getByCanonical(fields, activeIndex, 'first_seen'),
        latitude: latitude,
        longitude: longitude,
        ssid: _getByCanonical(fields, activeIndex, 'ssid'),
        bssid: mac,
        channel: _getByCanonical(fields, activeIndex, 'channel'),
        signal: _getByCanonical(fields, activeIndex, 'rssi'),
        security: security,
        capturedAt: capturedAt,
        altitudeMeters: _getByCanonical(fields, activeIndex, 'altitude'),
        accuracyMeters: _getByCanonical(fields, activeIndex, 'accuracy'),
        radioType: type.isEmpty ? 'WIFI' : type,
      ),
    );
  }
}

ParsedSerialEvent parseSerialLine(String line, {String capturedAt = ''}) {
  return SerialStreamParser().parseLine(
    line,
    capturedAt.isEmpty ? DateTime.now().toUtc().toIso8601String() : capturedAt,
  );
}

({List<ParsedSerialEvent> events, String carry}) parseSerialChunk(
  String chunk, {
  SerialStreamParser? parser,
  String carry = '',
  String capturedAt = '',
}) {
  final activeParser = parser ?? SerialStreamParser();
  if (parser == null) {
    activeParser.carry = carry;
  }
  final events = activeParser.parseChunk(chunk, capturedAt: capturedAt);
  return (events: events, carry: activeParser.carry);
}

List<ParsedSerialEvent> flushSerialCarry(
  String carry, {
  SerialStreamParser? parser,
  String capturedAt = '',
}) {
  final activeParser = parser ?? SerialStreamParser()
    ..carry = carry;
  if (parser != null) {
    activeParser.carry = carry;
  }
  return activeParser.flush(capturedAt: capturedAt);
}

List<String> parseCsvLine(String line) {
  final fields = <String>[];
  var current = '';
  var inQuotes = false;

  for (var index = 0; index < line.length; index++) {
    final char = line[index];
    final next = index + 1 < line.length ? line[index + 1] : null;

    if (char == '"' && inQuotes && next == '"') {
      current += '"';
      index++;
      continue;
    }

    if (char == '"') {
      inQuotes = !inQuotes;
      continue;
    }

    if (char == ',' && !inQuotes) {
      fields.add(current);
      current = '';
      continue;
    }

    current += char;
  }

  fields.add(current);
  return fields;
}

ScanType? _headerForLine(String line) {
  final normalized = line.trim();
  if (_lteHeaders.contains(normalized)) return ScanType.lte;
  if (normalized == radioUnifiedHeader) return ScanType.wifi;
  for (final entry in _legacyHeaderByType.entries) {
    if (entry.value == normalized) return entry.key;
  }
  return null;
}

String _effectiveCapturedAt(String capturedAt) {
  return capturedAt.isEmpty
      ? DateTime.now().toUtc().toIso8601String()
      : capturedAt;
}

IgnoredInvalidCoordinatesEvent _invalidCoordinates(
  ScanType scanType,
  String line,
) {
  return IgnoredInvalidCoordinatesEvent(
    scanType: scanType,
    line: line,
    reason: 'Latitude and longitude are missing, invalid, or both zero.',
  );
}

bool _hasUsableCoordinates(String latitude, String longitude) {
  final lat = double.tryParse(latitude);
  final lon = double.tryParse(longitude);

  if (lat == null || lon == null) {
    return false;
  }

  return !(lat == 0 && lon == 0);
}

bool _hasParseableCoordinates(String latitude, String longitude) {
  return double.tryParse(latitude) != null &&
      double.tryParse(longitude) != null;
}

String _getByCanonical(
  List<String> fields,
  Map<String, int> index,
  String canonical,
) {
  final idx = index[canonical];
  if (idx == null || idx < 0 || idx >= fields.length) return '';
  return fields[idx];
}

bool _looksLikeWigleColumnHeader(String line) {
  final lower = line.toLowerCase();
  return lower.startsWith('mac,') && lower.contains('type');
}

Map<String, int> _columnIndexFromHeader(String headerRow) {
  final columns = parseCsvLine(headerRow).map((c) => c.trim()).toList();
  final indexByCanonical = <String, int>{};

  for (var i = 0; i < columns.length; i++) {
    final canonical = _aliasToCanonical[columns[i].toLowerCase()];
    if (canonical != null && !indexByCanonical.containsKey(canonical)) {
      indexByCanonical[canonical] = i;
    }
  }

  return indexByCanonical;
}

Map<String, int>? _tryBuildWigleColumnIndex(String line) {
  if (!_looksLikeWigleColumnHeader(line)) return null;

  final indexByCanonical = _columnIndexFromHeader(line);
  if (!indexByCanonical.containsKey('mac') ||
      !indexByCanonical.containsKey('type')) {
    return null;
  }

  return indexByCanonical;
}

bool _looksLikeWigleDataRow(String line) {
  if (!_wigleTypeTailRe.hasMatch(line)) return false;
  final fields = parseCsvLine(line);
  if (fields.length < 8) return false;
  return _macRe.hasMatch(fields.first.trim());
}

/// Pick a default Minino column map from the row width when the CSV header
/// was already emitted before WebSerial connected.
Map<String, int> _inferWigleColumnIndex(String line) {
  final fields = parseCsvLine(line);
  // 13 fields → RCOIs + Type (no MfgrId). 14+ → full contract header.
  if (fields.length <= 13) {
    return _columnIndexFromHeader(_mininoWigleHeaderNoMfgr);
  }
  return _columnIndexFromHeader(_defaultMininoWigleHeader);
}

import 'models.dart';

const lteHeader =
    'Source,Timestamp,Tecnología,Estado,MCC,MNC,LAC,CellID,Banda,RSSI,RSRP,RSRQ,SINR,Operador,Longitud,Latitud';
const lteExtendedHeader =
    'Source,Timestamp,Tecnología,TipoCelda,Estado,MCC,MNC,LAC,CellID,eNodeB,Sector,PCI,Banda,EARFCN,FreqDL_MHz,FreqUL_MHz,RSSI,RSRP,RSRQ,SINR,Operador,Longitud,Latitud';
const wifiHeader = 'Source,Timestamp,Lat,Long,SSID,BSSID,Canal,Señal,Seguridad';
const bleHeader = 'Source,Timestamp,Lat,Long,Dirección,RSSI,Nombre';

final _lteHeaders = {lteHeader, lteExtendedHeader};

const _headerByType = <ScanType, String>{
  ScanType.lte: lteHeader,
  ScanType.wifi: wifiHeader,
  ScanType.ble: bleHeader,
};

ParsedSerialEvent parseSerialLine(String line, {String capturedAt = ''}) {
  final effectiveCapturedAt = capturedAt.isEmpty
      ? DateTime.now().toUtc().toIso8601String()
      : capturedAt;
  final trimmed = line.trim();

  if (trimmed.isEmpty) {
    return LogEvent(line: line);
  }

  final headerType = _headerForLine(trimmed);
  if (headerType != null) {
    return HeaderEvent(scanType: headerType, line: trimmed);
  }

  final fields = parseCsvLine(trimmed);
  final source = fields.isNotEmpty ? fields.first.toLowerCase() : '';

  return switch (source) {
    'lte' => _parseLte(fields, trimmed, effectiveCapturedAt),
    'wifi' => _parseWifi(fields, trimmed, effectiveCapturedAt),
    'ble' => _parseBle(fields, trimmed, effectiveCapturedAt),
    _ => LogEvent(line: line),
  };
}

({List<ParsedSerialEvent> events, String carry}) parseSerialChunk(
  String chunk, {
  String carry = '',
  String capturedAt = '',
}) {
  final effectiveCapturedAt = capturedAt.isEmpty
      ? DateTime.now().toUtc().toIso8601String()
      : capturedAt;
  final normalized = '${carry}$chunk'
      .replaceAll('\r\n', '\n')
      .replaceAll('\r', '\n');
  final parts = normalized.split('\n');
  final nextCarry = parts.isNotEmpty ? parts.removeLast() : '';

  return (
    events: parts
        .map((line) => parseSerialLine(line, capturedAt: effectiveCapturedAt))
        .toList(),
    carry: nextCarry,
  );
}

List<ParsedSerialEvent> flushSerialCarry(
  String carry, {
  String capturedAt = '',
}) {
  if (carry.isEmpty) return [];
  return [parseSerialLine(carry, capturedAt: capturedAt)];
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
  for (final entry in _headerByType.entries) {
    if (entry.value == normalized) return entry.key;
  }
  return null;
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

ParsedSerialEvent _parseWifi(
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
    ),
  );
}

ParsedSerialEvent _parseBle(
  List<String> fields,
  String line,
  String capturedAt,
) {
  final latitude = fields.length > 2 ? fields[2] : '';
  final longitude = fields.length > 3 ? fields[3] : '';

  if (!_hasUsableCoordinates(latitude, longitude)) {
    return _invalidCoordinates(ScanType.ble, line);
  }

  return BleEvent(
    line: line,
    record: BleRecord(
      timestamp: fields.length > 1 ? fields[1] : '',
      latitude: latitude,
      longitude: longitude,
      address: fields.length > 4 ? fields[4] : '',
      rssi: fields.length > 5 ? fields[5] : '',
      name: fields.length > 6 ? fields[6] : '',
      capturedAt: capturedAt,
    ),
  );
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

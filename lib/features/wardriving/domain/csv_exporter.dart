import 'models.dart';

const _radioExportColumns = [
  'Source',
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

const _exportHeaders = <ScanType, List<String>>{
  ScanType.lte: [
    'Timestamp',
    'Tecnología',
    'TipoCelda',
    'Estado',
    'MCC',
    'MNC',
    'LAC',
    'CellID',
    'eNodeB',
    'Sector',
    'PCI',
    'Banda',
    'EARFCN',
    'FreqDL_MHz',
    'FreqUL_MHz',
    'RSSI',
    'RSRP',
    'RSRQ',
    'SINR',
    'Operador',
    'Longitud',
    'Latitud',
  ],
  ScanType.wifi: _radioExportColumns,
  ScanType.ble: _radioExportColumns,
};

String buildCsv(ScanType type, List<Object> rows) {
  final header = _exportHeaders[type]!;
  final body = rows
      .map((row) => _rowToCsvValues(row).map(escapeCsvValue).join(','))
      .toList();
  return [header.map(escapeCsvValue).join(','), ...body].join('\n');
}

String makeCsvFilename(ScanType type, [DateTime? date]) {
  final effectiveDate = date ?? DateTime.now();
  return 'lilygo_${type.name}_${formatTimestamp(effectiveDate)}.csv';
}

String escapeCsvValue(String value) {
  if (RegExp(r'[",\n\r]').hasMatch(value)) {
    return '"${value.replaceAll('"', '""')}"';
  }
  return value;
}

String formatTimestamp(DateTime date) {
  String pad(int value) => value.toString().padLeft(2, '0');
  return '${date.year}${pad(date.month)}${pad(date.day)}_'
      '${pad(date.hour)}${pad(date.minute)}${pad(date.second)}';
}

List<String> _rowToCsvValues(Object row) {
  if (row is LteRecord) {
    return [
      row.timestamp,
      row.technology,
      row.cellType,
      row.status,
      row.mcc,
      row.mnc,
      row.lac,
      row.cellId,
      row.eNodeB,
      row.sector,
      row.pci,
      row.band,
      row.earfcn,
      row.freqDlMhz,
      row.freqUlMhz,
      row.rssi,
      row.rsrp,
      row.rsrq,
      row.sinr,
      row.operator,
      row.longitude,
      row.latitude,
    ];
  }

  if (row is WifiRecord) {
    return _radioRowValues(
      source: 'wifi',
      mac: row.bssid,
      ssid: row.ssid,
      authMode: row.security,
      firstSeen: row.timestamp,
      channel: row.channel,
      rssi: row.signal,
      latitude: row.latitude,
      longitude: row.longitude,
      altitudeMeters: row.altitudeMeters,
      accuracyMeters: row.accuracyMeters,
      type: row.radioType.isEmpty ? 'WIFI' : row.radioType,
    );
  }

  if (row is BleRecord) {
    return _radioRowValues(
      source: 'ble',
      mac: row.address,
      ssid: row.ssid,
      authMode: row.security.isEmpty ? 'BLE' : row.security,
      firstSeen: row.timestamp,
      channel: row.channel.isEmpty ? '0' : row.channel,
      rssi: row.rssi,
      latitude: row.latitude,
      longitude: row.longitude,
      altitudeMeters: row.altitudeMeters,
      accuracyMeters: row.accuracyMeters,
      type: row.radioType.isEmpty ? 'BLE' : row.radioType,
    );
  }

  throw ArgumentError('Unsupported row type: ${row.runtimeType}');
}

List<String> _radioRowValues({
  required String source,
  required String mac,
  required String ssid,
  required String authMode,
  required String firstSeen,
  required String channel,
  required String rssi,
  required String latitude,
  required String longitude,
  required String altitudeMeters,
  required String accuracyMeters,
  required String type,
}) {
  return [
    source,
    mac,
    ssid,
    authMode,
    firstSeen,
    channel,
    rssi,
    latitude,
    longitude,
    altitudeMeters,
    accuracyMeters,
    type,
  ];
}

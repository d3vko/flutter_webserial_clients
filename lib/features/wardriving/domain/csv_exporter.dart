import 'models.dart';

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
  ScanType.wifi: [
    'Timestamp',
    'Lat',
    'Long',
    'SSID',
    'BSSID',
    'Canal',
    'Señal',
    'Seguridad',
  ],
  ScanType.ble: ['Timestamp', 'Lat', 'Long', 'Dirección', 'RSSI', 'Nombre'],
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
    return [
      row.timestamp,
      row.latitude,
      row.longitude,
      row.ssid,
      row.bssid,
      row.channel,
      row.signal,
      row.security,
    ];
  }

  if (row is BleRecord) {
    return [
      row.timestamp,
      row.latitude,
      row.longitude,
      row.address,
      row.rssi,
      row.name,
    ];
  }

  throw ArgumentError('Unsupported row type: ${row.runtimeType}');
}

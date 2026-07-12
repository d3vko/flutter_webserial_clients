enum ScanType { lte, wifi, ble }

class RawLogLine {
  const RawLogLine({
    required this.id,
    required this.text,
    required this.receivedAt,
  });

  final int id;
  final String text;
  final String receivedAt;
}

class LteRecord {
  const LteRecord({
    required this.timestamp,
    required this.technology,
    required this.cellType,
    required this.status,
    required this.mcc,
    required this.mnc,
    required this.lac,
    required this.cellId,
    required this.eNodeB,
    required this.sector,
    required this.pci,
    required this.band,
    required this.earfcn,
    required this.freqDlMhz,
    required this.freqUlMhz,
    required this.rssi,
    required this.rsrp,
    required this.rsrq,
    required this.sinr,
    required this.operator,
    required this.longitude,
    required this.latitude,
    required this.capturedAt,
  });

  final String timestamp;
  final String technology;
  final String cellType;
  final String status;
  final String mcc;
  final String mnc;
  final String lac;
  final String cellId;
  final String eNodeB;
  final String sector;
  final String pci;
  final String band;
  final String earfcn;
  final String freqDlMhz;
  final String freqUlMhz;
  final String rssi;
  final String rsrp;
  final String rsrq;
  final String sinr;
  final String operator;
  final String longitude;
  final String latitude;
  final String capturedAt;

  ScanType get source => ScanType.lte;
}

class WifiRecord {
  const WifiRecord({
    required this.timestamp,
    required this.latitude,
    required this.longitude,
    required this.ssid,
    required this.bssid,
    required this.channel,
    required this.signal,
    required this.security,
    required this.capturedAt,
    this.altitudeMeters = '',
    this.accuracyMeters = '',
    this.radioType = '',
  });

  final String timestamp;
  final String latitude;
  final String longitude;
  final String ssid;
  final String bssid;
  final String channel;
  final String signal;
  final String security;
  final String capturedAt;
  final String altitudeMeters;
  final String accuracyMeters;
  final String radioType;

  ScanType get source => ScanType.wifi;
}

class BleRecord {
  const BleRecord({
    required this.timestamp,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.rssi,
    required this.ssid,
    required this.capturedAt,
    this.channel = '',
    this.security = '',
    this.altitudeMeters = '',
    this.accuracyMeters = '',
    this.radioType = '',
  });

  final String timestamp;
  final String latitude;
  final String longitude;
  final String address;
  final String rssi;
  final String ssid;
  final String capturedAt;
  final String channel;
  final String security;
  final String altitudeMeters;
  final String accuracyMeters;
  final String radioType;

  String get name => ssid;

  ScanType get source => ScanType.ble;
}

typedef ScanRecord = Object;

sealed class ParsedSerialEvent {
  const ParsedSerialEvent();
}

class LteEvent extends ParsedSerialEvent {
  const LteEvent({required this.record, required this.line});

  final LteRecord record;
  final String line;
}

class WifiEvent extends ParsedSerialEvent {
  const WifiEvent({required this.record, required this.line});

  final WifiRecord record;
  final String line;
}

class BleEvent extends ParsedSerialEvent {
  const BleEvent({required this.record, required this.line});

  final BleRecord record;
  final String line;
}

class HeaderEvent extends ParsedSerialEvent {
  const HeaderEvent({required this.scanType, required this.line});

  final ScanType scanType;
  final String line;
}

class IgnoredInvalidCoordinatesEvent extends ParsedSerialEvent {
  const IgnoredInvalidCoordinatesEvent({
    required this.scanType,
    required this.line,
    required this.reason,
  });

  final ScanType scanType;
  final String line;
  final String reason;
}

class LogEvent extends ParsedSerialEvent {
  const LogEvent({required this.line});

  final String line;
}

String lineForEvent(ParsedSerialEvent event) {
  return switch (event) {
    LteEvent(:final line) => line,
    WifiEvent(:final line) => line,
    BleEvent(:final line) => line,
    HeaderEvent(:final line) => line,
    IgnoredInvalidCoordinatesEvent(:final line) => line,
    LogEvent(:final line) => line,
  };
}

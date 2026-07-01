import 'package:flutter/foundation.dart';

enum TerminalLineType { normal, success, error, command }

enum MarauderView { ap, bt, gps, wardrive, storage, nfc }

enum SpiffsParseMode { none, listing, reading }

enum MarauderUploadPhase { idle, uploading, ok, error }

enum AccessPointUpdateKind { listEntry, scanResult, stationLink }

@immutable
class TerminalLine {
  const TerminalLine({
    required this.id,
    required this.text,
    required this.type,
  });

  final int id;
  final String text;
  final TerminalLineType type;
}

@immutable
class WardriveDialect {
  const WardriveDialect({
    this.sourceFormat = '',
    this.sourceVersion = '',
    this.appRelease = '',
    this.metaLine = '',
  });

  final String sourceFormat;
  final String sourceVersion;
  final String appRelease;
  final String metaLine;
}

@immutable
class WardriveColumnMapping {
  const WardriveColumnMapping({
    required this.columns,
    required this.indexByCanonical,
  });

  final List<String> columns;
  final Map<String, int> indexByCanonical;
}

@immutable
class WardriveEntry {
  const WardriveEntry({
    required this.mac,
    required this.ssid,
    required this.security,
    required this.firstSeen,
    required this.lastSeen,
    required this.channel,
    required this.frequency,
    required this.rssi,
    required this.latitude,
    required this.longitude,
    required this.altitude,
    required this.accuracy,
    required this.type,
    required this.sourceFormat,
    required this.sourceVersion,
  });

  final String mac;
  final String ssid;
  final String security;
  final String firstSeen;
  final String lastSeen;
  final String channel;
  final String frequency;
  final String rssi;
  final String latitude;
  final String longitude;
  final String altitude;
  final String accuracy;
  final String type;
  final String sourceFormat;
  final String sourceVersion;
}

@immutable
class GpsTelemetry {
  const GpsTelemetry({
    this.fix,
    this.sats,
    this.lat,
    this.lon,
    this.alt,
    this.accuracy,
    this.datetime,
  });

  final bool? fix;
  final int? sats;
  final String? lat;
  final String? lon;
  final String? alt;
  final String? accuracy;
  final String? datetime;
}

@immutable
class WifiStation {
  const WifiStation({required this.id, required this.mac, this.lastSeen});

  final int id;
  final String mac;
  final DateTime? lastSeen;
}

@immutable
class AccessPoint {
  const AccessPoint({
    required this.index,
    required this.channel,
    required this.essid,
    required this.bssid,
    this.rssi,
    this.isHidden = false,
    this.isSelected = false,
    required this.lastSeen,
    this.stations = const [],
  });

  final int index;
  final int channel;
  final String essid;
  final String bssid;
  final int? rssi;
  final bool isHidden;
  final bool isSelected;
  final DateTime lastSeen;
  final List<WifiStation> stations;

  AccessPoint copyWith({
    int? index,
    int? channel,
    String? essid,
    String? bssid,
    int? rssi,
    bool? isHidden,
    bool? isSelected,
    DateTime? lastSeen,
    List<WifiStation>? stations,
  }) {
    return AccessPoint(
      index: index ?? this.index,
      channel: channel ?? this.channel,
      essid: essid ?? this.essid,
      bssid: bssid ?? this.bssid,
      rssi: rssi ?? this.rssi,
      isHidden: isHidden ?? this.isHidden,
      isSelected: isSelected ?? this.isSelected,
      lastSeen: lastSeen ?? this.lastSeen,
      stations: stations ?? this.stations,
    );
  }
}

@immutable
class AccessPointUpdate {
  const AccessPointUpdate({
    required this.key,
    required this.kind,
    this.index,
    this.channel,
    this.essid,
    this.bssid,
    this.rssi,
    this.isHidden,
    this.isSelected,
    this.apBssid,
    this.station,
  });

  final String key;
  final AccessPointUpdateKind kind;
  final int? index;
  final int? channel;
  final String? essid;
  final String? bssid;
  final int? rssi;
  final bool? isHidden;
  final bool? isSelected;
  final String? apBssid;
  final WifiStation? station;
}

@immutable
class BluetoothDeviceEntry {
  const BluetoothDeviceEntry({
    required this.index,
    required this.mac,
    required this.name,
    this.rssi,
    this.vendor,
    required this.lastSeen,
  });

  final int index;
  final String mac;
  final String name;
  final int? rssi;
  final String? vendor;
  final DateTime lastSeen;

  BluetoothDeviceEntry copyWith({
    int? index,
    String? mac,
    String? name,
    int? rssi,
    String? vendor,
    DateTime? lastSeen,
  }) {
    return BluetoothDeviceEntry(
      index: index ?? this.index,
      mac: mac ?? this.mac,
      name: name ?? this.name,
      rssi: rssi ?? this.rssi,
      vendor: vendor ?? this.vendor,
      lastSeen: lastSeen ?? this.lastSeen,
    );
  }
}

@immutable
class SpiffsFile {
  const SpiffsFile({required this.name, required this.size});

  final String name;
  final int size;
}

@immutable
class SpiffsParseResult {
  const SpiffsParseResult._({
    this.fileName,
    this.fileSize,
    this.usedBytes,
    this.totalBytes,
    this.chunk,
    this.isReadBegin = false,
    this.isReadEnd = false,
    this.isListComplete = false,
  });

  factory SpiffsParseResult.fileEntry({
    required String name,
    required int size,
  }) => SpiffsParseResult._(fileName: name, fileSize: size);

  factory SpiffsParseResult.listComplete({
    required int usedBytes,
    required int totalBytes,
  }) => SpiffsParseResult._(
    usedBytes: usedBytes,
    totalBytes: totalBytes,
    isListComplete: true,
  );

  factory SpiffsParseResult.readBegin() =>
      const SpiffsParseResult._(isReadBegin: true);

  factory SpiffsParseResult.readEnd() =>
      const SpiffsParseResult._(isReadEnd: true);

  factory SpiffsParseResult.readChunk(String chunk) =>
      SpiffsParseResult._(chunk: chunk);

  final String? fileName;
  final int? fileSize;
  final int? usedBytes;
  final int? totalBytes;
  final String? chunk;
  final bool isReadBegin;
  final bool isReadEnd;
  final bool isListComplete;
}

@immutable
class WorkflowStep {
  const WorkflowStep({
    required this.command,
    this.description = '',
    this.requiresInput = false,
    this.inputLabel = '',
    this.placeholder = '',
    this.requiresSecondInput = false,
    this.secondInputLabel = '',
    this.secondPlaceholder = '',
    this.requiresSerialPayload = false,
    this.serialPayloadLabel = '',
    this.payloadDelayMs = 200,
  });

  final String command;
  final String description;
  final bool requiresInput;
  final String inputLabel;
  final String placeholder;
  final bool requiresSecondInput;
  final String secondInputLabel;
  final String secondPlaceholder;
  final bool requiresSerialPayload;
  final String serialPayloadLabel;
  final int payloadDelayMs;

  String resolveCommand({String? input, String? secondInput}) {
    var resolved = command;
    if (requiresInput && input != null) {
      resolved = resolved.replaceAll('{targets}', input);
      resolved = resolved.replaceAll('{index}', input);
      resolved = resolved.replaceAll('{apTargets}', input);
      resolved = resolved.replaceAll('{staTargets}', input);
      resolved = resolved.replaceAll('{type}', input);
      resolved = resolved.replaceAll('{value}', input);
      resolved = resolved.replaceAll('{source}', input);
    }
    if (requiresSecondInput && secondInput != null) {
      resolved = resolved.replaceAll('{password}', secondInput);
      resolved = resolved.replaceAll('{dest}', secondInput);
    }
    return resolved;
  }
}

@immutable
class MarauderWorkflow {
  const MarauderWorkflow({
    required this.id,
    required this.name,
    required this.description,
    required this.steps,
  });

  final String id;
  final String name;
  final String description;
  final List<WorkflowStep> steps;
}

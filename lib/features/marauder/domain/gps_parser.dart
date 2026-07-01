import 'marauder_models.dart';

final _fixRe = RegExp(r'(?:Good )?Fix:\s*(Yes|No)', caseSensitive: false);
final _satsRe = RegExp(r'(?:Satellites|Sats):\s*(\d+)', caseSensitive: false);
final _latRe = RegExp(r'Lat(?:itude)?:\s*(-?[\d.]+)', caseSensitive: false);
final _lonRe = RegExp(r'Lon(?:gitude)?:\s*(-?[\d.]+)', caseSensitive: false);
final _altRe = RegExp(r'Alt(?:itude)?:\s*(-?[\d.]+)', caseSensitive: false);
final _accRe = RegExp(r'Accuracy:\s*(-?[\d.]+)', caseSensitive: false);
final _dtRe = RegExp(r'Date(?:\/Time|time):\s*(.+)', caseSensitive: false);
final _gpsLogRe = RegExp(
  r'^(Fix:|Sats:|Lat:|Lon:|Alt:|Accuracy:|Date|Good Fix|Satellites|Latitude|Longitude|Altitude|Datetime|====|\$G[NPLAQIB]|NMEA|Text:)',
  caseSensitive: false,
);

GpsTelemetry? parseGpsTelemetryLine(String line) {
  final plain = line.replaceAll(RegExp(r'<[^>]+>'), '').trim();
  if (plain.isEmpty) return null;

  var updated = false;
  bool? fix;
  int? sats;
  String? lat;
  String? lon;
  String? alt;
  String? accuracy;
  String? datetime;

  final fixMatch = _fixRe.firstMatch(plain);
  if (fixMatch != null) {
    fix = fixMatch.group(1)!.toLowerCase() == 'yes';
    updated = true;
  }

  final satsMatch = _satsRe.firstMatch(plain);
  if (satsMatch != null) {
    sats = int.tryParse(satsMatch.group(1)!);
    updated = true;
  }

  final latMatch = _latRe.firstMatch(plain);
  if (latMatch != null) {
    lat = latMatch.group(1);
    updated = true;
  }

  final lonMatch = _lonRe.firstMatch(plain);
  if (lonMatch != null) {
    lon = lonMatch.group(1);
    updated = true;
  }

  final altMatch = _altRe.firstMatch(plain);
  if (altMatch != null) {
    alt = altMatch.group(1);
    updated = true;
  }

  final accMatch = _accRe.firstMatch(plain);
  if (accMatch != null) {
    accuracy = accMatch.group(1);
    updated = true;
  }

  final dtMatch = _dtRe.firstMatch(plain);
  if (dtMatch != null) {
    datetime = dtMatch.group(1)!.trim();
    updated = true;
  }

  if (!updated) return null;

  return GpsTelemetry(
    fix: fix,
    sats: sats,
    lat: lat,
    lon: lon,
    alt: alt,
    accuracy: accuracy,
    datetime: datetime,
  );
}

bool isGpsLogLine(String line) {
  final plain = line.replaceAll(RegExp(r'<[^>]+>'), '').trim();
  return _gpsLogRe.hasMatch(plain);
}

GpsTelemetry mergeGpsTelemetry(GpsTelemetry current, GpsTelemetry update) {
  return GpsTelemetry(
    fix: update.fix ?? current.fix,
    sats: update.sats ?? current.sats,
    lat: update.lat ?? current.lat,
    lon: update.lon ?? current.lon,
    alt: update.alt ?? current.alt,
    accuracy: update.accuracy ?? current.accuracy,
    datetime: update.datetime ?? current.datetime,
  );
}

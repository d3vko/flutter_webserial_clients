import 'marauder_models.dart';

final _listApRe = RegExp(r'^\[(\d+)\]\[CH:(\d+)\]\s+(.+)$');
final _scanApRe = RegExp(
  r'RSSI:\s(-?\d+)\sCh:\s(\d+)\sBSSID:\s([a-fA-F0-9:]+)\sESSID:\s(.+)',
);
final _stationRe = RegExp(
  r'(\d+):\s(ap|sta):\s([a-fA-F0-9:]+)\s->\s(sta|ap):\s([a-fA-F0-9:]+)',
);

String cleanEssid(String essid) {
  return essid
      .replaceAll(RegExp(r'[\uFFFD]'), '')
      .replaceAll(RegExp(r'\s*\(selected\)\s*$'), '')
      .trim();
}

String apKey(int channel, String essid) => '$channel-$essid';

AccessPointUpdate? parseWifiLine(String line) {
  final plain = line.replaceAll(RegExp(r'<[^>]+>'), '');

  final listMatch = _listApRe.firstMatch(plain);
  if (listMatch != null) {
    final index = int.parse(listMatch.group(1)!);
    final channel = int.parse(listMatch.group(2)!);
    final essid = cleanEssid(listMatch.group(3)!);
    return AccessPointUpdate(
      key: apKey(channel, essid),
      index: index,
      channel: channel,
      essid: essid,
      isSelected: plain.contains('(selected)'),
      kind: AccessPointUpdateKind.listEntry,
    );
  }

  if (plain.contains('RSSI:')) {
    final match = _scanApRe.firstMatch(plain);
    if (match != null) {
      final rssi = int.parse(match.group(1)!);
      final channel = int.parse(match.group(2)!);
      final bssid = match.group(3)!;
      final essid = cleanEssid(match.group(4)!);
      return AccessPointUpdate(
        key: apKey(channel, essid),
        rssi: rssi,
        channel: channel,
        bssid: bssid,
        essid: essid,
        isHidden: essid == bssid,
        kind: AccessPointUpdateKind.scanResult,
      );
    }
  }

  final stationMatch = _stationRe.firstMatch(plain);
  if (stationMatch != null) {
    final index = int.parse(stationMatch.group(1)!);
    final firstType = stationMatch.group(2)!;
    final firstMac = stationMatch.group(3)!;
    final secondMac = stationMatch.group(5)!;
    final apMac = firstType == 'ap' ? firstMac : secondMac;
    final staMac = firstType == 'sta' ? firstMac : secondMac;
    return AccessPointUpdate(
      key: '',
      apBssid: apMac,
      station: WifiStation(id: index, mac: staMac),
      kind: AccessPointUpdateKind.stationLink,
    );
  }

  return null;
}

Map<String, AccessPoint> applyAccessPointUpdate(
  Map<String, AccessPoint> current,
  AccessPointUpdate update,
) {
  final next = Map<String, AccessPoint>.from(current);
  final now = DateTime.now();

  switch (update.kind) {
    case AccessPointUpdateKind.listEntry:
      final existing = next[update.key];
      next[update.key] = AccessPoint(
        index: update.index ?? existing?.index ?? 0,
        channel: update.channel ?? existing?.channel ?? 0,
        essid: update.essid ?? existing?.essid ?? '',
        bssid: existing?.bssid ?? 'Unknown',
        rssi: existing?.rssi,
        isHidden: existing?.isHidden ?? false,
        isSelected: update.isSelected ?? existing?.isSelected ?? false,
        lastSeen: now,
        stations: existing?.stations ?? const [],
      );
    case AccessPointUpdateKind.scanResult:
      final existing = next[update.key];
      next[update.key] = AccessPoint(
        index: existing?.index ?? 0,
        channel: update.channel!,
        essid: update.essid!,
        bssid: update.bssid!,
        rssi: update.rssi,
        isHidden: update.isHidden ?? false,
        isSelected: existing?.isSelected ?? false,
        lastSeen: now,
        stations: existing?.stations ?? const [],
      );
    case AccessPointUpdateKind.stationLink:
      if (update.apBssid == null || update.station == null) break;
      for (final entry in next.entries) {
        if (entry.value.bssid == update.apBssid) {
          final stations = List<WifiStation>.from(entry.value.stations);
          final idx = stations.indexWhere((s) => s.mac == update.station!.mac);
          if (idx >= 0) {
            stations[idx] = WifiStation(
              id: update.station!.id,
              mac: update.station!.mac,
              lastSeen: now,
            );
          } else {
            stations.add(
              WifiStation(
                id: update.station!.id,
                mac: update.station!.mac,
                lastSeen: now,
              ),
            );
          }
          stations.sort((a, b) => a.id.compareTo(b.id));
          next[entry.key] = entry.value.copyWith(stations: stations);
          break;
        }
      }
  }

  return next;
}

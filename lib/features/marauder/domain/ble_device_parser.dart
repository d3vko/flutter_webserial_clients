import 'marauder_models.dart';

final _bleDeviceRe = RegExp(r'(-?\d+)\s+Device:\s*((?:(?!-?\d+\s+Device:).)+)');
final _macRe = RegExp(r'^([0-9a-fA-F]{2}:){5}[0-9a-fA-F]{2}$');

List<BluetoothDeviceEntry> parseBleDevicesLine(
  String line,
  Map<String, BluetoothDeviceEntry> existing,
) {
  final plain = line.replaceAll(RegExp(r'<[^>]+>'), '').trim();
  if (plain.isEmpty) return const [];

  final results = <BluetoothDeviceEntry>[];
  final working = Map<String, BluetoothDeviceEntry>.from(existing);

  for (final match in _bleDeviceRe.allMatches(plain)) {
    final rssi = int.parse(match.group(1)!);
    final device = match.group(2)!.trim();
    final isMac = _macRe.hasMatch(device);

    var mac = '-';
    var name = '-';
    var key = device;

    if (isMac) {
      mac = device;
      for (final d in working.values) {
        if (d.mac == mac) {
          name = d.name;
          key = d.mac.isNotEmpty ? d.mac : mac;
          break;
        }
      }
    } else {
      name = device;
      for (final d in working.values) {
        if (d.name == name) {
          mac = d.mac;
          key = d.name.isNotEmpty ? d.name : name;
          break;
        }
      }
    }

    final entry = BluetoothDeviceEntry(
      index: 0,
      mac: mac,
      name: name,
      rssi: rssi,
      lastSeen: DateTime.now(),
    );
    working[key] = entry;
    results.add(entry);
  }

  if (results.isEmpty) return const [];

  var idx = 1;
  for (final key in working.keys.toList()..sort()) {
    working[key] = working[key]!.copyWith(index: idx++);
  }

  return working.values.toList();
}

const continuousCommands = {
  'scanap',
  'scanall',
  'sniffbeacon',
  'sniffdeauth',
  'sniffpmkid',
  'sniffpwn',
  'sniffraw',
  'sniffbt',
  'sniffskim',
  'sniffmultissid',
  'sniffpinescan',
  'sniffsae',
  'mactrack',
  'packetcount',
  'attack',
  'sigmon',
  'pingscan',
  'portscan',
  'gpsdata',
  'nmea',
  'wardrive',
  'btwardrive',
  'gpspoi',
  'gpstracker',
  'karma',
};

const failurePatterns = [
  'GPS Module not detected',
  'GPS not supported',
  'GPS Not Found',
  'Could not detect GPS baudrate',
  'Bluetooth not supported',
  'SD card is not connected',
  'SD card support disabled',
  'You did not provide a valid argument',
  'You did not provide a valid flag',
];

bool isContinuousCommand(String command) {
  final trimmed = command.trim();
  if (trimmed.isEmpty) return false;

  final base = trimmed.split(RegExp(r'\s+')).first;
  if (base == 'gps' && trimmed.contains('-t')) {
    return true;
  }
  if (base == 'gpstracker') {
    return true;
  }
  return continuousCommands.contains(base);
}

bool isCommandFailure(String line) {
  final lower = line.toLowerCase();
  for (final pattern in failurePatterns) {
    if (lower.contains(pattern.toLowerCase())) {
      return true;
    }
  }
  return false;
}

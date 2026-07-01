import 'package:flutter/material.dart';

enum AppKind { wardriving, marauder, magspoof }

enum SerialConnectMode { none, target, usbFallback, all }

class UsbSerialFilter {
  const UsbSerialFilter({this.usbVendorId, this.usbProductId});

  final int? usbVendorId;
  final int? usbProductId;
}

@immutable
class MarauderCapabilities {
  const MarauderCapabilities({
    required this.brandingAsset,
    required this.baseAppRelease,
    required this.supportsBleSniff,
    required this.supportsBtWardrive,
    required this.supportsNfc,
    required this.wifiWardriveCommand,
    required this.gpsTrackerStartCommand,
    this.btWardriveCommand,
    this.wifiStationWardriveCommand,
    this.btWardriveContinuousCommand,
    this.gpsTrackerStopCommand,
    this.showEsp32C5Warning = false,
  });

  final String brandingAsset;
  final String baseAppRelease;
  final bool supportsBleSniff;
  final bool supportsBtWardrive;
  final bool supportsNfc;
  final String wifiWardriveCommand;
  final String? btWardriveCommand;
  final String? wifiStationWardriveCommand;
  final String? btWardriveContinuousCommand;
  final String gpsTrackerStartCommand;
  final String? gpsTrackerStopCommand;
  final bool showEsp32C5Warning;

  static const pwnterrey = MarauderCapabilities(
    brandingAsset: 'assets/branding/pwnterrey.png',
    baseAppRelease: 'PwnterreyESP32Marauder',
    supportsBleSniff: false,
    supportsBtWardrive: false,
    supportsNfc: true,
    wifiWardriveCommand: 'wardrive -serial',
    gpsTrackerStartCommand: 'gps -t',
    showEsp32C5Warning: true,
  );

  /// Official [ESP32Marauder](https://github.com/justcallmekoko/ESP32Marauder) CLI.
  static const oficial = MarauderCapabilities(
    brandingAsset: 'assets/branding/esp32-marauder.png',
    baseAppRelease: 'ESP32Marauder',
    supportsBleSniff: true,
    supportsBtWardrive: true,
    supportsNfc: false,
    wifiWardriveCommand: 'wardrive -serial',
    wifiStationWardriveCommand: 'wardrive -serial -s',
    btWardriveCommand: 'btwardrive -serial',
    btWardriveContinuousCommand: 'btwardrive -serial -c',
    gpsTrackerStartCommand: 'gpstracker -c start',
    gpsTrackerStopCommand: 'gpstracker -c stop',
  );
}

@immutable
class DeviceProfile {
  const DeviceProfile({
    required this.id,
    required this.routePath,
    required this.title,
    required this.subtitle,
    required this.themeStorageKey,
    required this.appKind,
    required this.deviceSourceWifiBle,
    required this.deviceSourceLte,
    this.deviceSource,
    required this.supportsAdvancedSerial,
    required this.defaultBaudRate,
    this.marauderCapabilities,
  });

  final String id;
  final String routePath;
  final String title;
  final String subtitle;
  final String themeStorageKey;
  final AppKind appKind;
  final String deviceSourceWifiBle;
  final String deviceSourceLte;
  final String? deviceSource;
  final bool supportsAdvancedSerial;
  final int defaultBaudRate;
  final MarauderCapabilities? marauderCapabilities;

  /// Upload `device_source` for TSIM WiFi/BLE CSV (shared by TSIM7000G and TSIM7600H-G).
  static const rfCustomFirmwareWifi = 'rf custom firmware wifi';

  /// Upload `device_source` for TSIM LTE CSV (shared by TSIM7000G and TSIM7600H-G).
  static const rfCustomFirmwareLte = 'rf custom firmware lte';

  static const tsim7000g = DeviceProfile(
    id: 'tsim7000g',
    routePath: '/tsim7000g',
    title: 'LilyGO TSIM7000G',
    subtitle: 'Wardriving with custom firmware for TSIM7000G',
    themeStorageKey: 'lilygo-color-mode',
    appKind: AppKind.wardriving,
    deviceSourceWifiBle: rfCustomFirmwareWifi,
    deviceSourceLte: rfCustomFirmwareLte,
    supportsAdvancedSerial: false,
    defaultBaudRate: 115200,
  );

  static const tsim7600hg = DeviceProfile(
    id: 'tsim7600hg',
    routePath: '/tsim7600hg',
    title: 'LilyGO TSIM7600H-G 16 MB',
    subtitle: 'Wardriving with custom firmware for TSIM7600H-G',
    themeStorageKey: 'lilygo-tsim7600hg-color-mode',
    appKind: AppKind.wardriving,
    deviceSourceWifiBle: rfCustomFirmwareWifi,
    deviceSourceLte: rfCustomFirmwareLte,
    supportsAdvancedSerial: true,
    defaultBaudRate: 115200,
  );

  static const pwnterreyMarauder = DeviceProfile(
    id: 'pwnterrey-marauder',
    routePath: '/pwnterrey-marauder',
    title: 'Badge Pwnterrey 2026',
    subtitle: 'ESP32 Marauder Custom Pwnterrey Firmware 2026',
    themeStorageKey: 'pwnterrey-marauder-color-mode',
    appKind: AppKind.marauder,
    deviceSource: 'pwnterrey marauder',
    deviceSourceWifiBle: '',
    deviceSourceLte: '',
    supportsAdvancedSerial: false,
    defaultBaudRate: 115200,
    marauderCapabilities: MarauderCapabilities.pwnterrey,
  );

  static const oficialMarauder = DeviceProfile(
    id: 'oficial-marauder',
    routePath: '/oficial-marauder',
    title: 'Oficial Firmware',
    subtitle: 'ESP32 Marauder official firmware (justcallmekoko)',
    themeStorageKey: 'oficial-marauder-color-mode',
    appKind: AppKind.marauder,
    deviceSource: 'pwnterrey marauder',
    deviceSourceWifiBle: '',
    deviceSourceLte: '',
    supportsAdvancedSerial: false,
    defaultBaudRate: 115200,
    marauderCapabilities: MarauderCapabilities.oficial,
  );

  static const magspoofV5 = DeviceProfile(
    id: 'magspoof-v5',
    routePath: '/magspoof-v5',
    title: 'MagSpoof V5',
    subtitle: 'Web Serial Client for Electronic Cats Hardware',
    themeStorageKey: 'magspoof-v5-color-mode',
    appKind: AppKind.magspoof,
    deviceSourceWifiBle: '',
    deviceSourceLte: '',
    supportsAdvancedSerial: false,
    defaultBaudRate: 9600,
  );

  static const all = [
    tsim7000g,
    tsim7600hg,
    pwnterreyMarauder,
    oficialMarauder,
    magspoofV5,
  ];

  static List<DeviceProfile> forKind(AppKind kind) =>
      all.where((profile) => profile.appKind == kind).toList();

  static DeviceProfile? fromPath(String path) {
    for (final profile in all) {
      if (profile.routePath == path) return profile;
    }
    return null;
  }

  bool get hasMarauderDeviceSource =>
      deviceSource != null && deviceSource!.isNotEmpty;

  static const targetUsbFilter = UsbSerialFilter(
    usbVendorId: 0x1a86,
    usbProductId: 0x55d4,
  );

  static const fallbackUsbFilters = [
    UsbSerialFilter(usbVendorId: 0x10c4),
    UsbSerialFilter(usbVendorId: 0x1a86),
    UsbSerialFilter(usbVendorId: 0x0403),
  ];

  List<UsbSerialFilter>? filtersForMode(SerialConnectMode mode) {
    if (!supportsAdvancedSerial || mode == SerialConnectMode.none) {
      return null;
    }

    return switch (mode) {
      SerialConnectMode.target => [targetUsbFilter],
      SerialConnectMode.usbFallback => fallbackUsbFilters,
      SerialConnectMode.all => const [],
      SerialConnectMode.none => null,
    };
  }

  String statusForRequestMode(SerialConnectMode mode) {
    return switch (mode) {
      SerialConnectMode.target => 'Select TSIM 7600H-G serial port...',
      SerialConnectMode.usbFallback => 'Select other USB serial port...',
      SerialConnectMode.all => 'Select any serial port...',
      SerialConnectMode.none => 'Select serial port...',
    };
  }
}

const baudRates = [9600, 19200, 38400, 57600, 115200, 230400, 460800, 921600];

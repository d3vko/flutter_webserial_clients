import 'package:flutter/foundation.dart';

import '../../../core/config/device_profile.dart';
import '../domain/marauder_models.dart';

const maxTerminalLines = 1000;
const maxGpsLogLines = 500;

@immutable
class MarauderState {
  const MarauderState({
    required this.profile,
    this.isConnected = false,
    this.isConnecting = false,
    this.isDisconnecting = false,
    this.statusMessage = 'Disconnected',
    this.errorMessage = '',
    this.baudRate = 115200,
    this.selectedPortLabel = '',
    this.terminalLines = const [],
    this.activeCommand,
    this.currentView = MarauderView.ap,
    this.gpsTelemetry = const GpsTelemetry(),
    this.gpsLogLines = const [],
    this.accessPoints = const {},
    this.bluetoothDevices = const {},
    this.wardriveEntries = const [],
    this.wardriveDialect,
    this.columnMapping,
    this.spiffsFiles = const [],
    this.spiffsStorageInfo = '',
    this.spiffsParseMode = SpiffsParseMode.none,
    this.isCapturingFile = false,
    this.capturingFileName = '',
    this.nfcLastOutput = '',
    this.isDarkTheme = false,
    this.authAccess,
    this.authRefresh,
    this.authUsername,
    this.uploadPhase = MarauderUploadPhase.idle,
    this.uploadError = '',
    this.isUploading = false,
  });

  final DeviceProfile profile;
  final bool isConnected;
  final bool isConnecting;
  final bool isDisconnecting;
  final String statusMessage;
  final String errorMessage;
  final int baudRate;
  final String selectedPortLabel;
  final List<TerminalLine> terminalLines;
  final String? activeCommand;
  final MarauderView currentView;
  final GpsTelemetry gpsTelemetry;
  final List<String> gpsLogLines;
  final Map<String, AccessPoint> accessPoints;
  final Map<String, BluetoothDeviceEntry> bluetoothDevices;
  final List<WardriveEntry> wardriveEntries;
  final WardriveDialect? wardriveDialect;
  final WardriveColumnMapping? columnMapping;
  final List<SpiffsFile> spiffsFiles;
  final String spiffsStorageInfo;
  final SpiffsParseMode spiffsParseMode;
  final bool isCapturingFile;
  final String capturingFileName;
  final String nfcLastOutput;
  final bool isDarkTheme;
  final String? authAccess;
  final String? authRefresh;
  final String? authUsername;
  final MarauderUploadPhase uploadPhase;
  final String uploadError;
  final bool isUploading;

  bool get isLoggedIn => authAccess != null && authAccess!.isNotEmpty;

  MarauderState copyWith({
    bool? isConnected,
    bool? isConnecting,
    bool? isDisconnecting,
    String? statusMessage,
    String? errorMessage,
    int? baudRate,
    String? selectedPortLabel,
    List<TerminalLine>? terminalLines,
    String? activeCommand,
    bool clearActiveCommand = false,
    MarauderView? currentView,
    GpsTelemetry? gpsTelemetry,
    List<String>? gpsLogLines,
    Map<String, AccessPoint>? accessPoints,
    Map<String, BluetoothDeviceEntry>? bluetoothDevices,
    List<WardriveEntry>? wardriveEntries,
    WardriveDialect? wardriveDialect,
    WardriveColumnMapping? columnMapping,
    List<SpiffsFile>? spiffsFiles,
    String? spiffsStorageInfo,
    SpiffsParseMode? spiffsParseMode,
    bool? isCapturingFile,
    String? capturingFileName,
    String? nfcLastOutput,
    bool? isDarkTheme,
    String? authAccess,
    String? authRefresh,
    String? authUsername,
    bool clearAuth = false,
    MarauderUploadPhase? uploadPhase,
    String? uploadError,
    bool? isUploading,
  }) {
    return MarauderState(
      profile: profile,
      isConnected: isConnected ?? this.isConnected,
      isConnecting: isConnecting ?? this.isConnecting,
      isDisconnecting: isDisconnecting ?? this.isDisconnecting,
      statusMessage: statusMessage ?? this.statusMessage,
      errorMessage: errorMessage ?? this.errorMessage,
      baudRate: baudRate ?? this.baudRate,
      selectedPortLabel: selectedPortLabel ?? this.selectedPortLabel,
      terminalLines: terminalLines ?? this.terminalLines,
      activeCommand: clearActiveCommand
          ? null
          : activeCommand ?? this.activeCommand,
      currentView: currentView ?? this.currentView,
      gpsTelemetry: gpsTelemetry ?? this.gpsTelemetry,
      gpsLogLines: gpsLogLines ?? this.gpsLogLines,
      accessPoints: accessPoints ?? this.accessPoints,
      bluetoothDevices: bluetoothDevices ?? this.bluetoothDevices,
      wardriveEntries: wardriveEntries ?? this.wardriveEntries,
      wardriveDialect: wardriveDialect ?? this.wardriveDialect,
      columnMapping: columnMapping ?? this.columnMapping,
      spiffsFiles: spiffsFiles ?? this.spiffsFiles,
      spiffsStorageInfo: spiffsStorageInfo ?? this.spiffsStorageInfo,
      spiffsParseMode: spiffsParseMode ?? this.spiffsParseMode,
      isCapturingFile: isCapturingFile ?? this.isCapturingFile,
      capturingFileName: capturingFileName ?? this.capturingFileName,
      nfcLastOutput: nfcLastOutput ?? this.nfcLastOutput,
      isDarkTheme: isDarkTheme ?? this.isDarkTheme,
      authAccess: clearAuth ? null : authAccess ?? this.authAccess,
      authRefresh: clearAuth ? null : authRefresh ?? this.authRefresh,
      authUsername: clearAuth ? null : authUsername ?? this.authUsername,
      uploadPhase: uploadPhase ?? this.uploadPhase,
      uploadError: uploadError ?? this.uploadError,
      isUploading: isUploading ?? this.isUploading,
    );
  }
}

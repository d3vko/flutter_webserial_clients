import 'package:flutter/foundation.dart';

import '../../../core/config/device_profile.dart';
import '../domain/magspoof_commands.dart';
import '../domain/track_models.dart';

@immutable
class MagspoofState {
  const MagspoofState({
    required this.profile,
    this.isConnected = false,
    this.isConnecting = false,
    this.isDisconnecting = false,
    this.statusMessage = 'Desconectado',
    this.errorMessage = '',
    this.baudRate = 9600,
    this.selectedPortLabel = '',
    this.rawTerminal = '',
    this.serialBuffer = '',
    this.lastCommand = '',
    this.parsedRecords = const [],
    this.track1Value = defaultTrack1,
    this.track2Value = defaultTrack2,
    this.tableView = MagspoofTableView.tracks,
    this.exportMode = MagspoofExportMode.masked,
    this.isDarkTheme = false,
  });

  final DeviceProfile profile;
  final bool isConnected;
  final bool isConnecting;
  final bool isDisconnecting;
  final String statusMessage;
  final String errorMessage;
  final int baudRate;
  final String selectedPortLabel;
  final String rawTerminal;
  final String serialBuffer;
  final String lastCommand;
  final List<TrackRecord> parsedRecords;
  final String track1Value;
  final String track2Value;
  final MagspoofTableView tableView;
  final MagspoofExportMode exportMode;
  final bool isDarkTheme;

  MagspoofState copyWith({
    bool? isConnected,
    bool? isConnecting,
    bool? isDisconnecting,
    String? statusMessage,
    String? errorMessage,
    int? baudRate,
    String? selectedPortLabel,
    String? rawTerminal,
    String? serialBuffer,
    String? lastCommand,
    List<TrackRecord>? parsedRecords,
    String? track1Value,
    String? track2Value,
    MagspoofTableView? tableView,
    MagspoofExportMode? exportMode,
    bool? isDarkTheme,
  }) {
    return MagspoofState(
      profile: profile,
      isConnected: isConnected ?? this.isConnected,
      isConnecting: isConnecting ?? this.isConnecting,
      isDisconnecting: isDisconnecting ?? this.isDisconnecting,
      statusMessage: statusMessage ?? this.statusMessage,
      errorMessage: errorMessage ?? this.errorMessage,
      baudRate: baudRate ?? this.baudRate,
      selectedPortLabel: selectedPortLabel ?? this.selectedPortLabel,
      rawTerminal: rawTerminal ?? this.rawTerminal,
      serialBuffer: serialBuffer ?? this.serialBuffer,
      lastCommand: lastCommand ?? this.lastCommand,
      parsedRecords: parsedRecords ?? this.parsedRecords,
      track1Value: track1Value ?? this.track1Value,
      track2Value: track2Value ?? this.track2Value,
      tableView: tableView ?? this.tableView,
      exportMode: exportMode ?? this.exportMode,
      isDarkTheme: isDarkTheme ?? this.isDarkTheme,
    );
  }
}

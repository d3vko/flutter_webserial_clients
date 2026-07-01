import 'package:flutter/foundation.dart';

import '../../../core/config/device_profile.dart';
import '../domain/models.dart';

enum UploadPhase { idle, uploading, ok, error }

@immutable
class WardriveState {
  const WardriveState({
    required this.profile,
    this.isConnected = false,
    this.isConnecting = false,
    this.isDisconnecting = false,
    this.statusMessage = 'Disconnected',
    this.errorMessage = '',
    this.baudRate = 115200,
    this.selectedPortLabel = '',
    this.ignoredCount = 0,
    this.rawLogs = const [],
    this.lteRows = const [],
    this.wifiRows = const [],
    this.bleRows = const [],
    this.isDarkTheme = false,
    this.authAccess,
    this.authRefresh,
    this.authUsername,
    this.uploadStatus = const {
      ScanType.lte: UploadPhase.idle,
      ScanType.wifi: UploadPhase.idle,
      ScanType.ble: UploadPhase.idle,
    },
    this.uploadErrors = const {
      ScanType.lte: '',
      ScanType.wifi: '',
      ScanType.ble: '',
    },
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
  final int ignoredCount;
  final List<RawLogLine> rawLogs;
  final List<LteRecord> lteRows;
  final List<WifiRecord> wifiRows;
  final List<BleRecord> bleRows;
  final bool isDarkTheme;
  final String? authAccess;
  final String? authRefresh;
  final String? authUsername;
  final Map<ScanType, UploadPhase> uploadStatus;
  final Map<ScanType, String> uploadErrors;
  final bool isUploading;

  bool get isLoggedIn => authAccess != null && authAccess!.isNotEmpty;

  bool get hasAnyRows =>
      lteRows.isNotEmpty || wifiRows.isNotEmpty || bleRows.isNotEmpty;

  String get uploadSummary {
    final parts = <String>[];
    const labels = {
      ScanType.ble: 'BLE',
      ScanType.wifi: 'WiFi',
      ScanType.lte: 'LTE',
    };

    for (final type in ScanType.values) {
      final phase = uploadStatus[type] ?? UploadPhase.idle;
      final label = labels[type]!;
      switch (phase) {
        case UploadPhase.ok:
          parts.add('$label ✓');
        case UploadPhase.error:
          parts.add('$label: ${uploadErrors[type]}');
        case UploadPhase.uploading:
          parts.add('$label …');
        case UploadPhase.idle:
          break;
      }
    }

    return parts.join(' · ');
  }

  WardriveState copyWith({
    bool? isConnected,
    bool? isConnecting,
    bool? isDisconnecting,
    String? statusMessage,
    String? errorMessage,
    int? baudRate,
    String? selectedPortLabel,
    int? ignoredCount,
    List<RawLogLine>? rawLogs,
    List<LteRecord>? lteRows,
    List<WifiRecord>? wifiRows,
    List<BleRecord>? bleRows,
    bool? isDarkTheme,
    String? authAccess,
    String? authRefresh,
    String? authUsername,
    bool clearAuth = false,
    Map<ScanType, UploadPhase>? uploadStatus,
    Map<ScanType, String>? uploadErrors,
    bool? isUploading,
  }) {
    return WardriveState(
      profile: profile,
      isConnected: isConnected ?? this.isConnected,
      isConnecting: isConnecting ?? this.isConnecting,
      isDisconnecting: isDisconnecting ?? this.isDisconnecting,
      statusMessage: statusMessage ?? this.statusMessage,
      errorMessage: errorMessage ?? this.errorMessage,
      baudRate: baudRate ?? this.baudRate,
      selectedPortLabel: selectedPortLabel ?? this.selectedPortLabel,
      ignoredCount: ignoredCount ?? this.ignoredCount,
      rawLogs: rawLogs ?? this.rawLogs,
      lteRows: lteRows ?? this.lteRows,
      wifiRows: wifiRows ?? this.wifiRows,
      bleRows: bleRows ?? this.bleRows,
      isDarkTheme: isDarkTheme ?? this.isDarkTheme,
      authAccess: clearAuth ? null : authAccess ?? this.authAccess,
      authRefresh: clearAuth ? null : authRefresh ?? this.authRefresh,
      authUsername: clearAuth ? null : authUsername ?? this.authUsername,
      uploadStatus: uploadStatus ?? this.uploadStatus,
      uploadErrors: uploadErrors ?? this.uploadErrors,
      isUploading: isUploading ?? this.isUploading,
    );
  }
}

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../core/config/device_profile.dart';
import '../../../core/config/wardrive_config.dart';
import '../../../core/storage/local_storage.dart';
import '../../serial/data/serial_client_factory.dart';
import '../../serial/domain/serial_client.dart';
import '../data/auth_storage.dart';
import '../data/auth_storage_factory.dart';
import '../data/csv_download.dart';
import '../data/wardrive_api_repository.dart';
import '../domain/csv_exporter.dart';
import '../domain/models.dart';
import '../domain/serial_parser.dart';
import 'wardrive_state.dart';

const maxRawLines = 1000;

final wardriveConfigProvider = Provider<WardriveConfig>(
  (ref) => WardriveConfig.fromEnvironment(),
);

final wardriveApiProvider = Provider<WardriveApiRepository>((ref) {
  return WardriveApiRepository(ref.watch(wardriveConfigProvider));
});

final wardriveControllerProvider =
    StateNotifierProvider.family<
      WardriveController,
      WardriveState,
      DeviceProfile
    >((ref, profile) {
      return WardriveController(
        profile: profile,
        api: ref.watch(wardriveApiProvider),
      );
    });

class WardriveController extends StateNotifier<WardriveState> {
  WardriveController({
    required DeviceProfile profile,
    required WardriveApiRepository api,
  }) : _api = api,
       _authStorage = createAuthStorage(),
       super(
         WardriveState(
           profile: profile,
           baudRate: profile.defaultBaudRate,
           isDarkTheme: _loadInitialTheme(profile.themeStorageKey),
         ),
       ) {
    _serial = buildSerialClient();
    Future.microtask(_loadStoredAuth);
  }

  static bool _loadInitialTheme(String key) {
    final saved = readLocalStorage(key);
    if (saved == 'black') return true;
    if (saved == 'white') return false;
    return prefersDarkScheme();
  }

  late final SerialClient _serial;
  final WardriveApiRepository _api;
  final AuthStorage _authStorage;

  StreamSubscription<String>? _serialSub;
  String _readCarry = '';
  int _rawLogId = 0;
  bool _pendingUploadAll = false;

  @override
  void dispose() {
    unawaited(_serialSub?.cancel());
    unawaited(_serial.disconnect());
    super.dispose();
  }

  Future<void> _loadStoredAuth() async {
    final stored = await _authStorage.load();
    if (stored == null || !mounted) return;
    state = state.copyWith(
      authAccess: stored.access,
      authRefresh: stored.refresh,
      authUsername: stored.username,
    );
  }

  void toggleTheme() {
    final nextDark = !state.isDarkTheme;
    writeLocalStorage(
      state.profile.themeStorageKey,
      nextDark ? 'black' : 'white',
    );
    state = state.copyWith(isDarkTheme: nextDark);
  }

  void setBaudRate(int baudRate) {
    state = state.copyWith(baudRate: baudRate);
  }

  Future<void> connectSerial({
    SerialConnectMode mode = SerialConnectMode.none,
  }) async {
    if (state.isConnecting || state.isConnected) return;

    state = state.copyWith(
      isConnecting: true,
      errorMessage: '',
      statusMessage: state.profile.supportsAdvancedSerial
          ? state.profile.statusForRequestMode(mode)
          : 'Select serial port...',
    );

    try {
      await _serialSub?.cancel();
      _serialSub = _serial.textChunks.listen(
        _consumeChunk,
        onError: (Object error) {
          _appendRawLog('[serial] read error: $error');
          unawaited(releaseSerialConnection(reason: 'error', error: error));
        },
      );

      final connectMode = state.profile.supportsAdvancedSerial
          ? mode
          : SerialConnectMode.none;

      await _serial.connect(
        SerialConnectOptions(baudRate: state.baudRate, mode: connectMode),
      );

      final label = _serial.portLabel ?? '';
      state = state.copyWith(
        isConnected: true,
        isConnecting: false,
        selectedPortLabel: label,
        statusMessage: 'Connected at ${state.baudRate} baud ($label)',
      );
      _appendRawLog('[serial] connected $label');
    } catch (error) {
      state = state.copyWith(
        isConnecting: false,
        isConnected: false,
        errorMessage: serialErrorMessage(error),
        statusMessage: 'Disconnected',
      );
      await _serial.disconnect();
    }
  }

  Future<void> disconnectSerial() async {
    state = state.copyWith(
      isDisconnecting: true,
      statusMessage: 'Disconnecting...',
      errorMessage: '',
    );
    await releaseSerialConnection(reason: 'user');
  }

  Future<void> releaseSerialConnection({
    required String reason,
    Object? error,
  }) async {
    await _serialSub?.cancel();
    _serialSub = null;

    final flushed = flushSerialCarry(_readCarry);
    _readCarry = '';
    _consumeEvents(flushed);

    await _serial.disconnect();

    var statusMessage = 'Disconnected';
    var errorMessage = state.errorMessage;

    if (reason == 'lost') {
      errorMessage =
          'Serial device disconnected. Reconnect USB and connect again.';
      statusMessage = 'Device lost';
    } else if (reason == 'error' && error != null) {
      errorMessage = serialErrorMessage(error);
      statusMessage = 'Serial error';
    }

    state = state.copyWith(
      isConnected: false,
      isConnecting: false,
      isDisconnecting: false,
      statusMessage: statusMessage,
      errorMessage: errorMessage,
      selectedPortLabel: '',
    );
  }

  void _consumeChunk(String chunk) {
    final parsed = parseSerialChunk(chunk, carry: _readCarry);
    _readCarry = parsed.carry;
    _consumeEvents(parsed.events);
  }

  void _consumeEvents(List<ParsedSerialEvent> events) {
    var lteRows = List<LteRecord>.from(state.lteRows);
    var wifiRows = List<WifiRecord>.from(state.wifiRows);
    var bleRows = List<BleRecord>.from(state.bleRows);
    var ignoredCount = state.ignoredCount;

    for (final event in events) {
      switch (event) {
        case LteEvent(:final record):
          lteRows.insert(0, record);
        case WifiEvent(:final record):
          wifiRows.insert(0, record);
        case BleEvent(:final record):
          bleRows.insert(0, record);
        case IgnoredInvalidCoordinatesEvent():
          ignoredCount++;
        case HeaderEvent():
        case LogEvent():
          break;
      }
      _appendRawLog(lineForEvent(event));
    }

    state = state.copyWith(
      lteRows: lteRows,
      wifiRows: wifiRows,
      bleRows: bleRows,
      ignoredCount: ignoredCount,
    );
  }

  void _appendRawLog(String text) {
    final logs = List<RawLogLine>.from(state.rawLogs)
      ..add(
        RawLogLine(
          id: _rawLogId++,
          text: text,
          receivedAt: DateTime.now().toLocal().toString().split(' ').last,
        ),
      );

    if (logs.length > maxRawLines) {
      logs.removeRange(0, logs.length - maxRawLines);
    }

    state = state.copyWith(rawLogs: logs);
  }

  void loadSample() {
    const sample = [
      '[modem] AT sync OK',
      '[gps] GPS power enabled',
      'Source,Timestamp,Tecnología,Estado,MCC,MNC,LAC,CellID,Banda,RSSI,RSRP,RSRQ,SINR,Operador,Longitud,Latitud',
      'lte,2026-04-10T23:51:58.000Z,LTE,0,334,020,1201,390112,3,-73,-101,-10,9,Telcel,-99.1332090,19.4326080',
      'Source,Timestamp,Tecnología,TipoCelda,Estado,MCC,MNC,LAC,CellID,eNodeB,Sector,PCI,Banda,EARFCN,FreqDL_MHz,FreqUL_MHz,RSSI,RSRP,RSRQ,SINR,Operador,Longitud,Latitud',
      'lte,2026-04-10T23:52:01.000Z,LTE,FDD-LTE,0,334,020,1201,390112,6095,2,123,3,1300,2115.0,1920.0,-73,-101,-10,9,Telcel,-99.1332090,19.4326080',
      'lte,2026-04-10T23:52:02.000Z,LTE,FDD-LTE,0,334,020,1202,390113,6096,3,124,7,1350,2120.0,1930.0,-80,-105,-12,7,Movistar,-99.1400000,19.4400000',
      'lte,2026-04-10T23:52:03.000Z,LTE,FDD-LTE,0,334,090,1203,390114,6097,1,125,20,6150,3500.0,3510.0,-68,-95,-8,12,AT&T,-99.1450000,19.4450000',
      'Source,Timestamp,Lat,Long,SSID,BSSID,Canal,Señal,Seguridad',
      'wifi,2026-04-10T23:52:04.000Z,19.4326080,-99.1332090,SampleNet,AA:BB:CC:DD:EE:FF,6,-65,WPA2_PSK',
      'wifi,2026-04-10T23:52:05.000Z,19.4326080,-99.1332090,,A2:31:DB:A0:CC:C6,7,-73,WPA2_PSK',
      'wifi,2026-04-10T23:52:06.000Z,19.4350000,-99.1300000,CafeCentro,34:6B:46:EC:BA:0B,11,-53,WPA2_PSK',
      'wifi,2026-04-10T23:52:07.000Z,19.4365000,-99.1285000,RF_Village_Guest_Network_5GHz,DE:AD:BE:EF:00:01,36,-48,WPA3_SAE',
      'Source,Timestamp,Lat,Long,Dirección,RSSI,Nombre',
      'ble,2026-04-10T23:52:08.000Z,19.4326080,-99.1332090,80:E1:26:76:33:64,-65,d3vnull0',
      'ble,2026-04-10T23:52:09.000Z,19.4326080,-99.1332090,AA:BB:CC:DD:EE:01,-72,',
      'ble,2026-04-10T23:52:10.000Z,19.4355000,-99.1280000,11:22:33:44:55:66,-58,BeaconTag',
      'ble,2026-04-10T23:52:11.000Z,19.4370000,-99.1270000,FE:DC:BA:98:76:54,-61,RFVillageBeacon',
      '[ble] logged 4 devices',
    ];

    _consumeEvents(sample.map(parseSerialLine).toList());
  }

  void clearRows(ScanType type) {
    state = switch (type) {
      ScanType.lte => state.copyWith(lteRows: const []),
      ScanType.wifi => state.copyWith(wifiRows: const []),
      ScanType.ble => state.copyWith(bleRows: const []),
    };
  }

  void clearAllRows() {
    state = state.copyWith(
      lteRows: const [],
      wifiRows: const [],
      bleRows: const [],
      ignoredCount: 0,
    );
  }

  void downloadCsv(ScanType type) {
    final rows = switch (type) {
      ScanType.lte => state.lteRows,
      ScanType.wifi => state.wifiRows,
      ScanType.ble => state.bleRows,
    };
    downloadCsvFile(type, rows, makeCsvFilename(type));
  }

  Future<void> logout() async {
    await _authStorage.clear();
    state = state.copyWith(clearAuth: true);
  }

  Future<void> saveAuth({
    required String access,
    required String refresh,
    required String username,
  }) async {
    await _authStorage.save(
      StoredAuth(access: access, refresh: refresh, username: username),
    );
    state = state.copyWith(
      authAccess: access,
      authRefresh: refresh,
      authUsername: username,
    );
  }

  Future<bool> tryRefreshToken() async {
    final refresh = state.authRefresh;
    if (refresh == null) return false;

    try {
      final access = await _api.refreshToken(refresh);
      await saveAuth(
        access: access,
        refresh: refresh,
        username: state.authUsername ?? '',
      );
      return true;
    } catch (_) {
      await logout();
      return false;
    }
  }

  Future<void> requestUploadAll() async {
    if (!state.isLoggedIn) {
      _pendingUploadAll = true;
      return;
    }
    await _doUploadAll();
  }

  void clearPendingUploadAll() => _pendingUploadAll = false;

  bool consumePendingUploadAll() {
    final pending = _pendingUploadAll;
    _pendingUploadAll = false;
    return pending;
  }

  Future<void> _doUploadAll() async {
    for (final type in ScanType.values) {
      await uploadType(type);
    }
  }

  Future<void> uploadType(ScanType type) async {
    final rows = switch (type) {
      ScanType.lte => state.lteRows,
      ScanType.wifi => state.wifiRows,
      ScanType.ble => state.bleRows,
    };

    if (rows.isEmpty) {
      return;
    }

    if (!state.isLoggedIn) {
      _setUploadError(type, 'Login required');
      return;
    }

    _setUploadPhase(type, UploadPhase.uploading);
    state = state.copyWith(isUploading: true);

    try {
      await _uploadWithRefresh(type, rows, state.authAccess!);
      _setUploadPhase(type, UploadPhase.ok);
    } on ApiConfigError catch (error) {
      _setUploadError(type, error.message);
    } catch (error) {
      _setUploadError(type, error.toString());
    } finally {
      state = state.copyWith(isUploading: false);
    }
  }

  Future<void> _uploadWithRefresh(
    ScanType type,
    List<Object> rows,
    String accessToken,
  ) async {
    final csv = _api.buildCsvForUpload(type, rows);
    final filename = _api.filenameForUpload(type);

    var response = await _api.uploadCsv(
      type: type,
      csvContent: csv,
      filename: filename,
      accessToken: accessToken,
      profile: state.profile,
    );

    if (response.statusCode == 401) {
      final refreshed = await tryRefreshToken();
      if (!refreshed || state.authAccess == null) {
        throw Exception('Session expired. Please log in again.');
      }
      response = await _api.uploadCsv(
        type: type,
        csvContent: csv,
        filename: filename,
        accessToken: state.authAccess!,
        profile: state.profile,
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Upload failed (${response.statusCode})');
    }
  }

  void _setUploadPhase(ScanType type, UploadPhase phase) {
    final uploadStatus = Map<ScanType, UploadPhase>.from(state.uploadStatus)
      ..[type] = phase;
    final uploadErrors = Map<ScanType, String>.from(state.uploadErrors)
      ..[type] = '';
    state = state.copyWith(
      uploadStatus: uploadStatus,
      uploadErrors: uploadErrors,
    );
  }

  void _setUploadError(ScanType type, String message) {
    final uploadStatus = Map<ScanType, UploadPhase>.from(state.uploadStatus)
      ..[type] = UploadPhase.error;
    final uploadErrors = Map<ScanType, String>.from(state.uploadErrors)
      ..[type] = message;
    state = state.copyWith(
      uploadStatus: uploadStatus,
      uploadErrors: uploadErrors,
    );
  }

  WardriveApiRepository get api => _api;
}

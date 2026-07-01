import 'dart:async';

import 'package:flutter_riverpod/legacy.dart';

import '../../../core/config/device_profile.dart';
import '../../../core/config/wardrive_config.dart';
import '../../../core/storage/local_storage.dart';
import '../../serial/data/serial_client_factory.dart';
import '../../serial/domain/serial_client.dart';
import '../../wardriving/data/auth_storage.dart';
import '../../wardriving/data/auth_storage_factory.dart';
import '../../wardriving/data/csv_download.dart';
import '../../wardriving/data/wardrive_api_repository.dart';
import '../../wardriving/presentation/wardrive_controller.dart';
import '../domain/ble_device_parser.dart';
import '../domain/gps_parser.dart';
import '../domain/marauder_commands.dart';
import '../domain/marauder_models.dart';
import '../domain/marauder_workflows.dart';
import '../domain/spiffs_parser.dart';
import '../domain/wardrive_csv.dart';
import '../domain/wardrive_parser.dart';
import '../domain/wifi_ap_parser.dart';
import 'marauder_state.dart';

final marauderControllerProvider =
    StateNotifierProvider.family<
      MarauderController,
      MarauderState,
      DeviceProfile
    >((ref, profile) {
      final controller = MarauderController(
        profile: profile,
        api: ref.watch(wardriveApiProvider),
      );
      ref.onDispose(controller.dispose);
      return controller;
    });

class MarauderController extends StateNotifier<MarauderState> {
  MarauderController({
    required DeviceProfile profile,
    required WardriveApiRepository api,
  }) : _api = api,
       _authStorage = createAuthStorage(),
       super(
         MarauderState(
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
  int _terminalLineId = 0;
  final _wardriveKeys = <String>{};
  final _pendingSpiffsFiles = <SpiffsFile>[];
  final _captureBuffer = <String>[];

  @override
  void dispose() {
    unawaited(_serialSub?.cancel());
    unawaited(_serial.disconnect());
    super.dispose();
  }

  void setView(MarauderView view) {
    state = state.copyWith(currentView: view);
  }

  Future<void> _loadStoredAuth() async {
    final stored = await _authStorage.load();
    if (stored == null) return;
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

  Future<void> connect() async {
    if (state.isConnecting || state.isConnected) return;

    state = state.copyWith(
      isConnecting: true,
      errorMessage: '',
      statusMessage: 'Select serial port...',
    );

    try {
      await _serialSub?.cancel();
      _serialSub = _serial.textChunks.listen(
        _consumeChunk,
        onError: (Object error) {
          _appendTerminal('Serial read error: $error', TerminalLineType.error);
          unawaited(disconnect(reason: 'error'));
        },
      );

      await _serial.connect(SerialConnectOptions(baudRate: state.baudRate));

      final label = _serial.portLabel ?? '';
      state = state.copyWith(
        isConnected: true,
        isConnecting: false,
        selectedPortLabel: label,
        statusMessage: 'Connected at ${state.baudRate} baud ($label)',
      );
      _appendTerminal('Connected to serial port', TerminalLineType.success);
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

  Future<void> disconnect({String reason = 'user'}) async {
    state = state.copyWith(
      isDisconnecting: true,
      statusMessage: 'Disconnecting...',
    );

    await _serialSub?.cancel();
    _serialSub = null;

    final flushed = _flushCarry();
    if (flushed.isNotEmpty) {
      _processLine(flushed);
    }
    _readCarry = '';

    await _serial.disconnect();

    state = state.copyWith(
      isConnected: false,
      isConnecting: false,
      isDisconnecting: false,
      statusMessage: reason == 'error' ? 'Serial error' : 'Disconnected',
      selectedPortLabel: '',
      clearActiveCommand: true,
      spiffsParseMode: SpiffsParseMode.none,
      isCapturingFile: false,
    );
    _appendTerminal('Disconnected from serial port', TerminalLineType.error);
  }

  Future<void> sendCommand(String command) async {
    final trimmed = command.trim();
    if (trimmed.isEmpty) return;

    if (!state.isConnected) {
      _appendTerminal('No command or not connected', TerminalLineType.error);
      return;
    }

    _maybeSwitchViewForCommand(trimmed);

    if (trimmed == 'stopscan') {
      await _writeCommand(trimmed);
      state = state.copyWith(clearActiveCommand: true);
      return;
    }

    if (isContinuousCommand(trimmed) && state.activeCommand != null) {
      await _stopIfRunning();
    }

    await _writeCommand(trimmed);

    if (isContinuousCommand(trimmed)) {
      state = state.copyWith(activeCommand: trimmed);
    }
  }

  Future<void> sendRaw(String rawText) async {
    if (!state.isConnected) return;
    try {
      await _serial.write(rawText);
      _appendTerminal('> [raw] $rawText', TerminalLineType.command);
    } catch (error) {
      _appendTerminal('Failed to send raw: $error', TerminalLineType.error);
    }
  }

  Future<void> stopScan() => sendCommand('stopscan');

  Future<void> executeWorkflow(
    MarauderWorkflow workflow,
    List<WorkflowStepInput> inputs,
  ) async {
    for (var i = 0; i < workflow.steps.length; i++) {
      final step = workflow.steps[i];
      final input = i < inputs.length ? inputs[i] : const WorkflowStepInput();
      final command = step.resolveCommand(
        input: input.primary,
        secondInput: input.secondary,
      );
      if (command.isNotEmpty) {
        await sendCommand(command);
      }
      if (step.requiresSerialPayload && input.serialPayload != null) {
        await Future<void>.delayed(Duration(milliseconds: step.payloadDelayMs));
        await sendRaw(input.serialPayload!);
      }
      await Future<void>.delayed(const Duration(milliseconds: 500));
    }
  }

  void _maybeSwitchViewForCommand(String command) {
    final lower = command.toLowerCase();
    if (lower.startsWith('gps') ||
        lower == 'gpsdata' ||
        lower == 'nmea' ||
        lower.startsWith('gpspoi')) {
      state = state.copyWith(currentView: MarauderView.gps);
    } else if (lower.startsWith('wardrive') || lower.startsWith('btwardrive')) {
      state = state.copyWith(currentView: MarauderView.wardrive);
    } else if (lower.startsWith('spiffs')) {
      state = state.copyWith(currentView: MarauderView.storage);
    } else if (lower.startsWith('nfc')) {
      state = state.copyWith(currentView: MarauderView.nfc);
    } else if (lower.startsWith('blespam') || lower.startsWith('sniffbt')) {
      state = state.copyWith(currentView: MarauderView.bt);
    } else if (lower.startsWith('scanap') ||
        lower.startsWith('list -a') ||
        lower.startsWith('attack')) {
      state = state.copyWith(currentView: MarauderView.ap);
    }
  }

  Future<void> _stopIfRunning() async {
    if (state.activeCommand == null) return;
    try {
      await _serial.sendCommand('stopscan');
      _appendTerminal('> stopscan (auto)', TerminalLineType.command);
      state = state.copyWith(clearActiveCommand: true);
      await Future<void>.delayed(const Duration(milliseconds: 300));
    } catch (_) {}
  }

  Future<void> _writeCommand(String command) async {
    try {
      await _serial.sendCommand(command);
      _appendTerminal('> $command', TerminalLineType.command);
    } catch (error) {
      _appendTerminal('Failed to send command: $error', TerminalLineType.error);
    }
  }

  Future<void> listSpiffsFiles() async {
    _pendingSpiffsFiles.clear();
    state = state.copyWith(
      spiffsParseMode: SpiffsParseMode.listing,
      spiffsFiles: const [],
      spiffsStorageInfo: '',
    );
    await sendCommand('spiffs ls');
  }

  Future<void> downloadSpiffsFile(String name) async {
    _captureBuffer.clear();
    state = state.copyWith(
      spiffsParseMode: SpiffsParseMode.reading,
      isCapturingFile: true,
      capturingFileName: name,
    );
    await sendCommand('spiffs read $name');
  }

  Future<void> deleteSpiffsFile(String name) async {
    await sendCommand('spiffs rm $name');
    await Future<void>.delayed(const Duration(milliseconds: 500));
    await listSpiffsFiles();
  }

  Future<void> formatSpiffs() async {
    await sendCommand('spiffs format');
    await Future<void>.delayed(const Duration(milliseconds: 500));
    await listSpiffsFiles();
  }

  void clearAccessPoints() {
    state = state.copyWith(accessPoints: const {});
  }

  void clearBluetoothDevices() {
    state = state.copyWith(bluetoothDevices: const {});
  }

  Future<void> refreshAccessPoints() => sendCommand('list -a');

  Future<void> refreshBluetoothDevices() => sendCommand('list -t');

  void _consumeChunk(String chunk) {
    _readCarry += chunk;
    final parts = _readCarry.split('\n');
    _readCarry = parts.removeLast();

    for (final part in parts) {
      _processLine(part);
    }
  }

  String _flushCarry() {
    final carry = _readCarry;
    _readCarry = '';
    return carry;
  }

  void _processLine(String rawLine) {
    final line = rawLine.trim();
    if (line.isEmpty) return;

    _appendTerminal(line, TerminalLineType.normal);

    if (state.activeCommand != null && isCommandFailure(line)) {
      state = state.copyWith(clearActiveCommand: true);
    }

    if (state.currentView == MarauderView.nfc ||
        line.toLowerCase().startsWith('nfc')) {
      state = state.copyWith(nfcLastOutput: line);
    }

    final gpsUpdate = parseGpsTelemetryLine(line);
    if (gpsUpdate != null) {
      state = state.copyWith(
        gpsTelemetry: mergeGpsTelemetry(state.gpsTelemetry, gpsUpdate),
      );
    }
    if (isGpsLogLine(line)) {
      final logs = List<String>.from(state.gpsLogLines)..add(line);
      if (logs.length > maxGpsLogLines) {
        logs.removeRange(0, logs.length - maxGpsLogLines);
      }
      state = state.copyWith(gpsLogLines: logs);
    }

    final apUpdate = parseWifiLine(line);
    if (apUpdate != null) {
      state = state.copyWith(
        accessPoints: applyAccessPointUpdate(state.accessPoints, apUpdate),
      );
    }

    final bleDevices = parseBleDevicesLine(line, state.bluetoothDevices);
    if (bleDevices.isNotEmpty) {
      final map = <String, BluetoothDeviceEntry>{};
      for (final d in bleDevices) {
        final key = d.mac != '-' ? d.mac : d.name;
        map[key] = d;
      }
      state = state.copyWith(bluetoothDevices: map);
    }

    final spiffsResult = parseSpiffsLine(line, state.spiffsParseMode);
    if (spiffsResult != null) {
      _applySpiffsResult(spiffsResult);
    }

    final meta = parseWardriveMetaLine(line);
    if (meta != null) {
      state = state.copyWith(wardriveDialect: meta);
      return;
    }

    final header = parseWardriveColumnHeader(line);
    if (header != null) {
      state = state.copyWith(columnMapping: header);
      return;
    }

    final entry = parseWardriveRow(
      line,
      state.columnMapping,
      state.wardriveDialect,
    );
    if (entry == null) return;

    final key = wardriveEntryKey(entry);
    if (_wardriveKeys.contains(key)) return;
    _wardriveKeys.add(key);

    state = state.copyWith(wardriveEntries: [...state.wardriveEntries, entry]);
  }

  void _applySpiffsResult(SpiffsParseResult result) {
    if (result.isReadBegin) {
      _captureBuffer.clear();
      return;
    }

    if (result.isReadEnd) {
      final content = _captureBuffer.join('\n');
      final filename = state.capturingFileName.replaceFirst(RegExp(r'^/'), '');
      if (content.isNotEmpty) {
        downloadTextFile(content, filename);
      }
      _captureBuffer.clear();
      state = state.copyWith(
        spiffsParseMode: SpiffsParseMode.none,
        isCapturingFile: false,
        capturingFileName: '',
      );
      return;
    }

    if (result.chunk != null) {
      _captureBuffer.add(result.chunk!);
      return;
    }

    if (result.fileName != null && result.fileSize != null) {
      _pendingSpiffsFiles.add(
        SpiffsFile(name: result.fileName!, size: result.fileSize!),
      );
      return;
    }

    if (result.isListComplete) {
      state = state.copyWith(
        spiffsFiles: List<SpiffsFile>.from(_pendingSpiffsFiles),
        spiffsStorageInfo:
            '${formatSpiffsSize(result.usedBytes!)} / ${formatSpiffsSize(result.totalBytes!)}',
        spiffsParseMode: SpiffsParseMode.none,
      );
      _pendingSpiffsFiles.clear();
    }
  }

  void _appendTerminal(String text, TerminalLineType type) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final lines = List<TerminalLine>.from(state.terminalLines)
      ..add(TerminalLine(id: _terminalLineId++, text: trimmed, type: type));

    if (lines.length > maxTerminalLines) {
      lines.removeRange(0, lines.length - maxTerminalLines);
    }

    state = state.copyWith(terminalLines: lines);
  }

  void clearWardriveEntries() {
    _wardriveKeys.clear();
    state = state.copyWith(
      wardriveEntries: const [],
      wardriveDialect: null,
      columnMapping: null,
    );
  }

  void downloadWardriveCsv() {
    if (state.wardriveEntries.isEmpty) return;
    final csv = buildWardriveCsvString(
      state.wardriveEntries,
      state.wardriveDialect,
    );
    downloadTextFile(csv, wardriveCsvFileName());
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

  Future<void> uploadWardrive() async {
    if (state.wardriveEntries.isEmpty) return;

    if (!state.isLoggedIn) {
      state = state.copyWith(
        uploadPhase: MarauderUploadPhase.error,
        uploadError: 'Login required',
      );
      return;
    }

    state = state.copyWith(
      isUploading: true,
      uploadPhase: MarauderUploadPhase.uploading,
      uploadError: '',
    );

    try {
      final csv = buildWardriveCsvString(
        state.wardriveEntries,
        state.wardriveDialect,
      );
      final filename = wardriveCsvFileName();
      final deviceSource = state.profile.deviceSource!;

      var response = await _api.uploadRawCsv(
        csvContent: csv,
        filename: filename,
        accessToken: state.authAccess!,
        deviceSource: deviceSource,
      );

      if (response.statusCode == 401) {
        final refreshed = await tryRefreshToken();
        if (!refreshed || state.authAccess == null) {
          throw Exception('Session expired. Please log in again.');
        }
        response = await _api.uploadRawCsv(
          csvContent: csv,
          filename: filename,
          accessToken: state.authAccess!,
          deviceSource: deviceSource,
        );
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Upload failed (${response.statusCode})');
      }

      state = state.copyWith(uploadPhase: MarauderUploadPhase.ok);
    } on ApiConfigError catch (error) {
      state = state.copyWith(
        uploadPhase: MarauderUploadPhase.error,
        uploadError: error.message,
      );
    } catch (error) {
      state = state.copyWith(
        uploadPhase: MarauderUploadPhase.error,
        uploadError: error.toString(),
      );
    } finally {
      state = state.copyWith(isUploading: false);
    }
  }

  List<MarauderWorkflow> get workflows => marauderWorkflows;

  WardriveApiRepository get api => _api;
}

class WorkflowStepInput {
  const WorkflowStepInput({this.primary, this.secondary, this.serialPayload});

  final String? primary;
  final String? secondary;
  final String? serialPayload;
}

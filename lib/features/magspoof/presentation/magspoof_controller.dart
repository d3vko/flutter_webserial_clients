import 'dart:async';

import 'package:flutter_riverpod/legacy.dart';

import '../../../core/config/device_profile.dart';
import '../../../core/storage/local_storage.dart';
import '../../serial/data/serial_client_factory.dart';
import '../../serial/domain/serial_client.dart';
import '../../wardriving/data/csv_download.dart';
import '../domain/group_tracks.dart';
import '../domain/track_csv.dart';
import '../domain/track_models.dart';
import '../domain/track_parser.dart';
import 'magspoof_state.dart';

final magspoofControllerProvider =
    StateNotifierProvider.family<
      MagspoofController,
      MagspoofState,
      DeviceProfile
    >((ref, profile) {
      final controller = MagspoofController(profile: profile);
      ref.onDispose(controller.dispose);
      return controller;
    });

class MagspoofController extends StateNotifier<MagspoofState> {
  MagspoofController({required DeviceProfile profile})
    : super(
        MagspoofState(
          profile: profile,
          baudRate: profile.defaultBaudRate,
          isDarkTheme: _loadInitialTheme(profile.themeStorageKey),
        ),
      ) {
    _serial = buildSerialClient();
  }

  static bool _loadInitialTheme(String key) {
    final saved = readLocalStorage(key);
    if (saved == 'black') return true;
    if (saved == 'white') return false;
    return prefersDarkScheme();
  }

  late final SerialClient _serial;
  StreamSubscription<String>? _serialSub;

  @override
  void dispose() {
    unawaited(_serialSub?.cancel());
    unawaited(_serial.disconnect());
    super.dispose();
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
    if (state.isConnected) return;
    state = state.copyWith(baudRate: baudRate);
  }

  void setTableView(MagspoofTableView view) {
    state = state.copyWith(tableView: view);
  }

  void setExportMode(MagspoofExportMode mode) {
    state = state.copyWith(exportMode: mode);
  }

  void setTrack1Value(String value) {
    state = state.copyWith(track1Value: value);
  }

  void setTrack2Value(String value) {
    state = state.copyWith(track2Value: value);
  }

  Future<void> connect() async {
    if (state.isConnecting || state.isConnected) return;

    state = state.copyWith(
      isConnecting: true,
      errorMessage: '',
      statusMessage: 'Selecciona puerto serial...',
    );

    try {
      await _serialSub?.cancel();
      _serialSub = _serial.textChunks.listen(
        _handleSerialData,
        onError: (Object error) {
          _appendTerminal('\nSerial read error: $error\n');
          unawaited(disconnect());
        },
      );

      await _serial.connect(SerialConnectOptions(baudRate: state.baudRate));

      final label = _serial.portLabel ?? '';
      state = state.copyWith(
        isConnected: true,
        isConnecting: false,
        selectedPortLabel: label,
        statusMessage: 'Conectado a ${state.baudRate} baud ($label)',
      );
    } catch (error) {
      state = state.copyWith(
        isConnecting: false,
        isConnected: false,
        errorMessage: serialErrorMessage(error),
        statusMessage: 'Desconectado',
      );
      await _serial.disconnect();
    }
  }

  Future<void> disconnect() async {
    state = state.copyWith(
      isDisconnecting: true,
      statusMessage: 'Desconectando...',
    );

    await _serialSub?.cancel();
    _serialSub = null;
    await _serial.disconnect();

    state = state.copyWith(
      isConnected: false,
      isConnecting: false,
      isDisconnecting: false,
      statusMessage: 'Desconectado',
      selectedPortLabel: '',
    );
  }

  Future<void> sendQuickCommand(String command) =>
      sendText(command, sourceCommand: command);

  Future<void> sendManualCommand(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    await sendText(trimmed, sourceCommand: trimmed);
  }

  Future<void> sendTrack(String trackValue, String label) async {
    final trimmed = trackValue.trim();
    if (trimmed.isEmpty) return;

    await sendText(trimmed, sourceCommand: label);
    final parsed = parseTrackLine(trimmed, sourceCommand: label);
    if (parsed != null) {
      _addParsedRecords([parsed]);
    }
  }

  Future<void> sendText(String text, {required String sourceCommand}) async {
    state = state.copyWith(errorMessage: '', lastCommand: sourceCommand);
    _appendTerminal('> $text\n');

    if (!state.isConnected) return;

    try {
      await _serial.sendCommand(text);
    } catch (error) {
      state = state.copyWith(errorMessage: serialErrorMessage(error));
    }
  }

  void clearTerminal() {
    state = state.copyWith(rawTerminal: '', serialBuffer: '');
  }

  void clearRecords() {
    state = state.copyWith(parsedRecords: []);
  }

  void parseBufferedInput() {
    final records = parseBufferedLine(
      state.serialBuffer,
      sourceCommand: state.lastCommand,
    );
    if (records.isEmpty) return;
    _addParsedRecords(records, updateEditors: true);
    state = state.copyWith(serialBuffer: '');
  }

  void exportCurrentCsv() {
    final isGrouped = state.tableView == MagspoofTableView.grouped;
    final rows = isGrouped
        ? groupTrackRecords(
            state.parsedRecords,
          ).map((record) => record.toGroupedRow()).toList()
        : state.parsedRecords.map((record) => record.toTrackRow()).toList();
    final columns = isGrouped ? groupedColumns : trackColumns;
    final csv = rowsToCsv(rows, columns, mode: state.exportMode);
    final scope = isGrouped ? 'grouped' : 'tracks';
    final detail = state.exportMode == MagspoofExportMode.full
        ? 'complete'
        : 'masked';
    downloadTextFile(csv, 'mags_poof_${scope}_$detail.csv');
  }

  void _handleSerialData(String chunk) {
    _appendTerminal(chunk);
    final parsed = parseSerialChunk(
      chunk,
      state.serialBuffer,
      sourceCommand: state.lastCommand,
    );
    state = state.copyWith(serialBuffer: parsed.buffer);
    _addParsedRecords(parsed.records, updateEditors: true);
  }

  void _addParsedRecords(
    List<TrackRecord> records, {
    bool updateEditors = false,
  }) {
    if (records.isEmpty) return;

    final seen = <String>{};
    final uniqueRecords = <TrackRecord>[];
    for (final record in records) {
      final key = '${record.trackTypeLabel}:${record.rawValue}';
      if (seen.contains(key)) continue;
      seen.add(key);
      uniqueRecords.add(record);
    }

    if (uniqueRecords.isEmpty) return;

    var track1 = state.track1Value;
    var track2 = state.track2Value;
    if (updateEditors) {
      for (final record in uniqueRecords) {
        if (record.trackType == TrackType.track1) {
          track1 = record.rawValue;
        }
        if (record.trackType == TrackType.track2) {
          track2 = record.rawValue;
        }
      }
    }

    state = state.copyWith(
      parsedRecords: [...uniqueRecords, ...state.parsedRecords],
      track1Value: track1,
      track2Value: track2,
    );
  }

  void _appendTerminal(String text) {
    if (text.isEmpty) return;
    state = state.copyWith(rawTerminal: state.rawTerminal + text);
  }
}

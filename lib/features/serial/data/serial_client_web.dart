// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';

import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;
import 'package:webserial/webserial.dart';

import '../../../core/config/device_profile.dart';
import '../domain/serial_client.dart';
import 'serial_usb_filters.dart';

SerialClient createSerialClient() => WebSerialClient();

class WebSerialClient implements SerialClient {
  JSSerialPort? _port;
  web.ReadableStreamDefaultReader? _reader;
  bool _reading = false;
  bool _isTearingDown = false;
  String? _portLabel;

  final _chunks = StreamController<String>.broadcast();

  @override
  Stream<String> get textChunks => _chunks.stream;

  @override
  bool get isConnected => _port != null;

  @override
  String? get portLabel => _portLabel;

  @override
  Future<void> connect(SerialConnectOptions options) async {
    if (_port != null) return;

    _isTearingDown = false;
    final filters = _filtersForMode(options.mode);
    final jsFilters = usbFiltersToJs(filters);

    final selectedPort = await requestWebSerialPort(
      jsFilters.isEmpty ? null : jsFilters.toJS,
    );
    if (selectedPort == null) {
      throw Exception('No serial port selected.');
    }

    _port = selectedPort;
    _portLabel = readPortLabel(selectedPort);

    await _port!
        .open(
          JSSerialOptions(
            baudRate: options.baudRate,
            dataBits: 8,
            stopBits: 1,
            parity: 'none',
            bufferSize: 64,
            flowControl: 'none',
          ),
        )
        .toDart;

    if (_port!.readable == null) {
      await _closePort();
      throw Exception('The selected serial port is not readable.');
    }

    _reading = true;
    unawaited(_readLoop());
  }

  List<UsbSerialFilter>? _filtersForMode(SerialConnectMode mode) {
    return switch (mode) {
      SerialConnectMode.target => [DeviceProfile.targetUsbFilter],
      SerialConnectMode.usbFallback => DeviceProfile.fallbackUsbFilters,
      SerialConnectMode.all => const [],
      SerialConnectMode.none => null,
    };
  }

  Future<void> _readLoop() async {
    final readable = _port?.readable;
    if (readable == null) return;

    _reader = readable.getReader() as web.ReadableStreamDefaultReader?;
    Object? readError;

    while (_reading) {
      try {
        final result = await _reader!.read().toDart;
        if (result.done) break;

        final value = result.value;
        final text = value == null
            ? ''
            : utf8.decode((value as JSUint8Array).toDart, allowMalformed: true);

        if (text.isNotEmpty) {
          _chunks.add(text);
        }
      } catch (error, stackTrace) {
        debugPrint('Serial read error: $error\n$stackTrace');
        readError = error;
        break;
      }
    }

    try {
      await _reader?.cancel().toDart;
    } catch (_) {}
    _reader?.releaseLock();
    _reader = null;

    if (!_isTearingDown && readError != null) {
      _chunks.addError(readError);
    }

    if (!_isTearingDown) {
      await disconnect();
    }
  }

  @override
  Future<void> disconnect() async {
    if (_isTearingDown) return;
    _isTearingDown = true;
    _reading = false;

    try {
      await _reader?.cancel().toDart;
    } catch (_) {}

    try {
      _reader?.releaseLock();
    } catch (_) {}
    _reader = null;

    await _closePort();
    _isTearingDown = false;
  }

  Future<void> _closePort() async {
    final port = _port;
    _port = null;
    _portLabel = null;

    try {
      await port?.close().toDart;
    } catch (_) {}
  }

  @override
  Future<void> write(String text) async {
    final port = _port;
    if (port == null) {
      throw StateError('Not connected to a serial port.');
    }

    final writable = port.writable;
    if (writable == null) {
      throw StateError('The selected serial port is not writable.');
    }

    final writer = port.writable!.getWriter();
    try {
      final bytes = Uint8List.fromList(utf8.encode(text));
      await writer.write(bytes.toJS).toDart;
    } finally {
      writer.releaseLock();
    }
  }

  @override
  Future<void> sendCommand(String command) => write('$command\n');
}

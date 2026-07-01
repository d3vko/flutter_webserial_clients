import 'dart:async';

import '../domain/serial_client.dart';

SerialClient createSerialClient() => StubSerialClient();

class StubSerialClient implements SerialClient {
  final _chunks = StreamController<String>.broadcast();

  @override
  Stream<String> get textChunks => _chunks.stream;

  @override
  bool get isConnected => false;

  @override
  String? get portLabel => null;

  @override
  Future<void> connect(SerialConnectOptions options) async {
    throw UnsupportedError(
      'Web Serial is only available on Flutter Web with a compatible browser.',
    );
  }

  @override
  Future<void> disconnect() async {
    await _chunks.close();
  }

  @override
  Future<void> write(String text) async {
    throw UnsupportedError(
      'Web Serial is only available on Flutter Web with a compatible browser.',
    );
  }

  @override
  Future<void> sendCommand(String command) => write('$command\n');
}

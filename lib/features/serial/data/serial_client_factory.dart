import '../domain/serial_client.dart';
import 'serial_client_stub.dart'
    if (dart.library.js_interop) 'serial_client_web.dart';

SerialClient buildSerialClient() => createSerialClient();

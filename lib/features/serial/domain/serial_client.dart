import '../../../core/config/device_profile.dart';

class SerialConnectOptions {
  const SerialConnectOptions({
    this.baudRate = 115200,
    this.mode = SerialConnectMode.none,
  });

  final int baudRate;
  final SerialConnectMode mode;
}

abstract interface class SerialClient {
  Stream<String> get textChunks;
  bool get isConnected;
  String? get portLabel;

  Future<void> connect(SerialConnectOptions options);
  Future<void> disconnect();
  Future<void> write(String text);
  Future<void> sendCommand(String command);
}

String formatUsbId(int? value) {
  if (value == null) return '';
  return '0x${value.toRadixString(16).padLeft(4, '0')}';
}

String formatPortInfo({int? usbVendorId, int? usbProductId}) {
  final vendorId = formatUsbId(usbVendorId);
  final productId = formatUsbId(usbProductId);

  if (vendorId.isNotEmpty && productId.isNotEmpty) {
    return 'VID $vendorId / PID $productId';
  }
  if (vendorId.isNotEmpty) {
    return 'VID $vendorId';
  }
  return 'unknown USB serial port';
}

String serialErrorMessage(Object error) {
  final message = error.toString();
  if (message.contains('The device has been lost')) {
    return 'The serial device was lost. Reconnect the USB cable or reset the board, close other serial monitors, then connect again.';
  }
  return message;
}

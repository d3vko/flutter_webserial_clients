import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:webserial/webserial.dart';

import '../../../core/config/device_profile.dart';
import '../domain/serial_client.dart';

List<JSFilterObject> usbFiltersToJs(List<UsbSerialFilter>? filters) {
  if (filters == null) return [];
  if (filters.isEmpty) return [];

  return filters.map((filter) {
    if (filter.usbVendorId != null && filter.usbProductId != null) {
      return JSFilterObject(
        usbVendorId: filter.usbVendorId!,
        usbProductId: filter.usbProductId!,
      );
    }

    final object = JSObject();
    if (filter.usbVendorId != null) {
      object.setProperty('usbVendorId'.toJS, filter.usbVendorId!.toJS);
    }
    if (filter.usbProductId != null) {
      object.setProperty('usbProductId'.toJS, filter.usbProductId!.toJS);
    }
    return object as JSFilterObject;
  }).toList();
}

String readPortLabel(JSSerialPort port) {
  final info = port.getInfo();
  return formatPortInfo(
    usbVendorId: info.usbVendorId,
    usbProductId: info.usbProductId,
  );
}

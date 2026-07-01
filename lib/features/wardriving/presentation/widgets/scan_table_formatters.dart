import 'package:intl/intl.dart';

const emptyDash = '—';

String dashIfEmpty(String value) => value.isEmpty ? emptyDash : value;

String unknownIfEmpty(String value) => value.isEmpty ? 'Unknown' : value;

String hiddenSsid(String ssid) => ssid.isEmpty ? '(hidden)' : ssid;

String formatCapturedTime(String capturedAt) {
  if (capturedAt.isEmpty) return emptyDash;
  final parsed = DateTime.tryParse(capturedAt);
  if (parsed == null) return capturedAt;
  return DateFormat('yyyy-MM-dd HH:mm:ss').format(parsed.toLocal());
}

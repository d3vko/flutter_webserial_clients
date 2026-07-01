import 'track_models.dart';

const trackColumns = [
  'track_type',
  'parse_status',
  'pan',
  'cardholder_name',
  'expiration',
  'service_code',
  'discretionary_data',
  'raw_value',
  'source_command',
  'created_at',
];

const groupedColumns = [
  'pan',
  'cardholder_name',
  'expiration',
  'service_code',
  'track_1_raw_value',
  'track_2_raw_value',
  'track_1_status',
  'track_2_status',
  'source_command',
  'created_at',
];

String rowsToCsv(
  List<Map<String, String>> rows,
  List<String> columns, {
  MagspoofExportMode mode = MagspoofExportMode.masked,
}) {
  final prepared = rows.map((row) => _maskRow(row, mode)).toList();
  final body = prepared
      .map(
        (row) => columns.map((column) => _csvCell(row[column] ?? '')).join(','),
      )
      .toList();
  return [columns.join(','), ...body].join('\r\n');
}

String maskPan(String value) {
  final text = value;
  if (text.length <= 10) {
    return text.replaceAllMapped(RegExp(r'\d(?=\d{4})'), (_) => '*');
  }
  final maskedMiddle = '*' * (text.length - 10);
  return '${text.substring(0, 6)}$maskedMiddle${text.substring(text.length - 4)}';
}

String maskTrackRaw(String rawValue) {
  var result = rawValue;
  result = result.replaceAllMapped(
    RegExp(r'(%B)([0-9]{1,19})(\^)([^^?]*)(\^)'),
    (match) {
      return '${match.group(1)}${maskPan(match.group(2)!)}'
          '${match.group(3)}${_maskName(match.group(4)!)}${match.group(5)}';
    },
  );
  result = result.replaceAllMapped(
    RegExp(r'(;)([0-9]{1,19})(=)'),
    (match) => '${match.group(1)}${maskPan(match.group(2)!)}${match.group(3)}',
  );
  return result;
}

Map<String, String> _maskRow(Map<String, String> row, MagspoofExportMode mode) {
  if (mode == MagspoofExportMode.full) return Map<String, String>.from(row);

  final masked = Map<String, String>.from(row);
  if (masked.containsKey('pan')) {
    masked['pan'] = maskPan(masked['pan'] ?? '');
  }
  if (masked.containsKey('cardholder_name')) {
    masked['cardholder_name'] = _maskName(masked['cardholder_name'] ?? '');
  }

  for (final key in masked.keys.toList()) {
    if (key == 'raw_value' || key.endsWith('_raw_value')) {
      masked[key] = maskTrackRaw(masked[key] ?? '');
    }
  }

  return masked;
}

String _maskName(String value) {
  final text = value.trim();
  if (text.isEmpty) return '';
  return text
      .split(RegExp(r'\s+'))
      .map((part) {
        if (part.length <= 1) return '*';
        return '${part[0]}${'*' * (part.length - 1)}';
      })
      .join(' ');
}

String _csvCell(String value) {
  return '"${value.replaceAll('"', '""')}"';
}

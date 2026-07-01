import 'package:flutter/material.dart';

import '../../domain/models.dart';
import 'scan_table_cell.dart';
import 'scan_table_formatters.dart';
import 'scan_type_theme.dart';

class WifiDataTableSource extends DataTableSource {
  WifiDataTableSource({List<WifiRecord>? rows, ScanTypeTheme? theme})
    : _rows = List<WifiRecord>.from(rows ?? []),
      theme = theme ?? ScanTypeTheme.forType(ScanType.wifi);

  List<WifiRecord> _rows;
  final ScanTypeTheme theme;

  void updateRows(List<WifiRecord> rows) {
    _rows = List<WifiRecord>.from(rows);
    notifyListeners();
  }

  List<DataColumn> columns() => theme.columnsFor(const [
    'Timestamp',
    'Lat',
    'Long',
    'SSID',
    'BSSID',
    'Channel',
    'Signal',
    'Security',
    'Captured',
  ]);

  @override
  DataRow? getRow(int index) {
    if (index < 0 || index >= _rows.length) return null;
    final row = _rows[index];
    return DataRow(
      color: WidgetStateProperty.all(theme.zebraForRow(index)),
      cells: [
        scanTableCell(dashIfEmpty(row.timestamp)),
        scanTableCell(row.latitude),
        scanTableCell(row.longitude),
        scanTableCell(hiddenSsid(row.ssid)),
        scanTableCell(row.bssid),
        scanTableCell(row.channel),
        scanTableCell(
          row.signal,
          style: TextStyle(color: theme.signalStrengthColor(row.signal)),
        ),
        scanTableCell(row.security),
        scanTableCell(formatCapturedTime(row.capturedAt)),
      ],
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => _rows.length;

  @override
  int get selectedRowCount => 0;
}

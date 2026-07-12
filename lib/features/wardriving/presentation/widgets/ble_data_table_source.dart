import 'package:flutter/material.dart';

import '../../domain/models.dart';
import 'scan_table_cell.dart';
import 'scan_table_formatters.dart';
import 'scan_table_layout.dart';
import 'scan_type_theme.dart';

class BleDataTableSource extends DataTableSource {
  BleDataTableSource({List<BleRecord>? rows, ScanTypeTheme? theme})
    : _rows = List<BleRecord>.from(rows ?? []),
      theme = theme ?? ScanTypeTheme.forType(ScanType.ble);

  List<BleRecord> _rows;
  final ScanTypeTheme theme;

  void updateRows(List<BleRecord> rows) {
    _rows = List<BleRecord>.from(rows);
    notifyListeners();
  }

  List<DataColumn> columns() => theme.columnsFor(radioTableColumns);

  @override
  DataRow? getRow(int index) {
    if (index < 0 || index >= _rows.length) return null;
    final row = _rows[index];
    final radioType = row.radioType.isEmpty ? 'BLE' : row.radioType;
    final authMode = row.security.isEmpty ? 'BLE' : row.security;
    return DataRow(
      color: WidgetStateProperty.all(theme.zebraForRow(index)),
      cells: [
        scanTableCell(row.address),
        scanTableCell(unknownIfEmpty(row.ssid)),
        scanTableCell(authMode),
        scanTableCell(dashIfEmpty(row.timestamp)),
        scanTableCell(dashIfEmpty(row.channel)),
        scanTableCell(
          row.rssi,
          style: TextStyle(color: theme.signalStrengthColor(row.rssi)),
        ),
        scanTableCell(row.latitude),
        scanTableCell(row.longitude),
        scanTableCell(dashIfEmpty(row.altitudeMeters)),
        scanTableCell(dashIfEmpty(row.accuracyMeters)),
        scanTableCell(radioType),
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

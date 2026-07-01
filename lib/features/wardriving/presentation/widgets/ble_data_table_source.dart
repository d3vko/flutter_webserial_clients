import 'package:flutter/material.dart';

import '../../domain/models.dart';
import 'scan_table_cell.dart';
import 'scan_table_formatters.dart';
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

  List<DataColumn> columns() => theme.columnsFor(const [
    'Timestamp',
    'Lat',
    'Long',
    'Address',
    'RSSI',
    'Name',
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
        scanTableCell(row.address),
        scanTableCell(
          row.rssi,
          style: TextStyle(color: theme.signalStrengthColor(row.rssi)),
        ),
        scanTableCell(unknownIfEmpty(row.name)),
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

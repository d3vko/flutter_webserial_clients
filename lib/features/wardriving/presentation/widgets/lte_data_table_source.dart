import 'package:flutter/material.dart';

import '../../domain/models.dart';
import 'scan_table_cell.dart';
import 'scan_table_formatters.dart';
import 'scan_type_theme.dart';

class LteDataTableSource extends DataTableSource {
  LteDataTableSource({List<LteRecord>? rows, ScanTypeTheme? theme})
    : _rows = List<LteRecord>.from(rows ?? []),
      theme = theme ?? ScanTypeTheme.forType(ScanType.lte);

  List<LteRecord> _rows;
  final ScanTypeTheme theme;

  void updateRows(List<LteRecord> rows) {
    _rows = List<LteRecord>.from(rows);
    notifyListeners();
  }

  List<DataColumn> columns() => theme.columnsFor(const [
    'Timestamp',
    'Tech',
    'TipoCelda',
    'Status',
    'MCC',
    'MNC',
    'LAC',
    'CellID',
    'eNodeB',
    'Sector',
    'PCI',
    'Band',
    'EARFCN',
    'FreqDL',
    'FreqUL',
    'RSSI',
    'RSRP',
    'RSRQ',
    'SINR',
    'Operator',
    'Long',
    'Lat',
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
        scanTableCell(row.technology),
        scanTableCell(dashIfEmpty(row.cellType)),
        scanTableCell(dashIfEmpty(row.status)),
        scanTableCell(dashIfEmpty(row.mcc)),
        scanTableCell(dashIfEmpty(row.mnc)),
        scanTableCell(dashIfEmpty(row.lac)),
        scanTableCell(dashIfEmpty(row.cellId)),
        scanTableCell(dashIfEmpty(row.eNodeB)),
        scanTableCell(dashIfEmpty(row.sector)),
        scanTableCell(dashIfEmpty(row.pci)),
        scanTableCell(row.band),
        scanTableCell(dashIfEmpty(row.earfcn)),
        scanTableCell(dashIfEmpty(row.freqDlMhz)),
        scanTableCell(dashIfEmpty(row.freqUlMhz)),
        scanTableCell(
          row.rssi,
          style: TextStyle(color: theme.signalStrengthColor(row.rssi)),
        ),
        scanTableCell(
          row.rsrp,
          style: TextStyle(color: theme.signalStrengthColor(row.rsrp)),
        ),
        scanTableCell(
          row.rsrq,
          style: TextStyle(color: theme.signalStrengthColor(row.rsrq)),
        ),
        scanTableCell(
          row.sinr,
          style: TextStyle(
            color: theme.signalStrengthColor(row.sinr, higherIsBetter: true),
          ),
        ),
        scanTableCell(unknownIfEmpty(row.operator)),
        scanTableCell(row.longitude),
        scanTableCell(row.latitude),
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

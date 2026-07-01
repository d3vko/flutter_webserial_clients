import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/rf_village_gradient.dart';
import '../../domain/models.dart';
import 'ble_data_table_source.dart';
import 'lte_data_table_source.dart';
import 'scan_table_layout.dart';
import 'scan_type_theme.dart';
import 'wifi_data_table_source.dart';

class ScanDataSection extends StatefulWidget {
  const ScanDataSection.lte({
    required this.subtitle,
    required this.filename,
    required List<LteRecord> rows,
    required this.onDownload,
    required this.onClear,
    required this.onUpload,
    super.key,
  }) : scanType = ScanType.lte,
       title = 'LTE',
       lteRows = rows,
       wifiRows = const [],
       bleRows = const [];

  const ScanDataSection.wifi({
    required this.subtitle,
    required this.filename,
    required List<WifiRecord> rows,
    required this.onDownload,
    required this.onClear,
    required this.onUpload,
    super.key,
  }) : scanType = ScanType.wifi,
       title = 'WiFi',
       lteRows = const [],
       wifiRows = rows,
       bleRows = const [];

  const ScanDataSection.ble({
    required this.subtitle,
    required this.filename,
    required List<BleRecord> rows,
    required this.onDownload,
    required this.onClear,
    required this.onUpload,
    super.key,
  }) : scanType = ScanType.ble,
       title = 'BLE',
       lteRows = const [],
       wifiRows = const [],
       bleRows = rows;

  final ScanType scanType;
  final String title;
  final String subtitle;
  final String filename;
  final List<LteRecord> lteRows;
  final List<WifiRecord> wifiRows;
  final List<BleRecord> bleRows;
  final VoidCallback onDownload;
  final VoidCallback onClear;
  final Future<void> Function() onUpload;

  int get rowCount => switch (scanType) {
    ScanType.lte => lteRows.length,
    ScanType.wifi => wifiRows.length,
    ScanType.ble => bleRows.length,
  };

  @override
  State<ScanDataSection> createState() => _ScanDataSectionState();
}

class _ScanDataSectionState extends State<ScanDataSection> {
  static const _availableRowsPerPage = [10, 20, 50];

  late final ScanTypeTheme _typeTheme;
  late DataTableSource _source;
  int _rowsPerPage = 10;

  @override
  void initState() {
    super.initState();
    _typeTheme = ScanTypeTheme.forType(widget.scanType);
    _source = _createSource();
  }

  @override
  void didUpdateWidget(covariant ScanDataSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    switch (widget.scanType) {
      case ScanType.lte:
        if (oldWidget.lteRows != widget.lteRows) {
          (_source as LteDataTableSource).updateRows(widget.lteRows);
        }
      case ScanType.wifi:
        if (oldWidget.wifiRows != widget.wifiRows) {
          (_source as WifiDataTableSource).updateRows(widget.wifiRows);
        }
      case ScanType.ble:
        if (oldWidget.bleRows != widget.bleRows) {
          (_source as BleDataTableSource).updateRows(widget.bleRows);
        }
    }
  }

  DataTableSource _createSource() => switch (widget.scanType) {
    ScanType.lte => LteDataTableSource(rows: widget.lteRows, theme: _typeTheme),
    ScanType.wifi => WifiDataTableSource(
      rows: widget.wifiRows,
      theme: _typeTheme,
    ),
    ScanType.ble => BleDataTableSource(rows: widget.bleRows, theme: _typeTheme),
  };

  void _onRowsPerPageChanged(int? value) {
    if (value == null || value == _rowsPerPage) return;
    setState(() => _rowsPerPage = value);
  }

  Widget _buildPaginatedTable() {
    return PaginatedDataTable(
      columns: _columnsForType(),
      source: _source,
      rowsPerPage: _rowsPerPage,
      availableRowsPerPage: _availableRowsPerPage,
      onRowsPerPageChanged: _onRowsPerPageChanged,
      showFirstLastButtons: true,
      showCheckboxColumn: false,
      showEmptyRows: true,
      columnSpacing: 24,
      headingRowHeight: defaultHeadingRowHeight,
      dataRowMaxHeight: defaultDataRowHeight,
      horizontalMargin: 16,
    );
  }

  Widget _buildTableArea(BoxConstraints constraints) {
    final tableHeight = paginatedTableHeight(
      rowsPerPage: _rowsPerPage,
      rowCount: widget.rowCount,
    );
    final table = _buildPaginatedTable();
    final minWidth = _typeTheme.tableMinWidth;

    return SizedBox(
      height: tableHeight,
      width: constraints.maxWidth,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: math.max(constraints.maxWidth, minWidth),
          child: table,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 4,
            decoration: const BoxDecoration(
              gradient: RfVillageGradient.cardAccent,
            ),
          ),
          Container(
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(color: _typeTheme.accent, width: 4),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.title.toUpperCase(),
                              style: Theme.of(context).textTheme.labelMedium
                                  ?.copyWith(
                                    color: _typeTheme.accent,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.2,
                                  ),
                            ),
                            Text(
                              widget.subtitle,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Text(
                              widget.filename,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      Wrap(
                        spacing: 8,
                        children: [
                          OutlinedButton(
                            onPressed: widget.rowCount == 0
                                ? null
                                : widget.onDownload,
                            child: const Text('Download'),
                          ),
                          OutlinedButton(
                            onPressed: widget.rowCount == 0
                                ? null
                                : widget.onClear,
                            child: const Text('Clear'),
                          ),
                          FilledButton(
                            onPressed: widget.rowCount == 0
                                ? null
                                : widget.onUpload,
                            child: const Text('Upload'),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (widget.rowCount == 0)
                    Text(
                      'No records yet',
                      style: Theme.of(context).textTheme.bodyMedium,
                    )
                  else
                    LayoutBuilder(
                      builder: (context, constraints) =>
                          _buildTableArea(constraints),
                    ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<DataColumn> _columnsForType() => switch (widget.scanType) {
    ScanType.lte => (_source as LteDataTableSource).columns(),
    ScanType.wifi => (_source as WifiDataTableSource).columns(),
    ScanType.ble => (_source as BleDataTableSource).columns(),
  };
}

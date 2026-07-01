import 'package:flutter/material.dart';

import '../../domain/group_tracks.dart';
import '../../domain/track_csv.dart';
import '../../domain/track_models.dart';

class MagspoofTracksTablePanel extends StatelessWidget {
  const MagspoofTracksTablePanel({
    required this.records,
    required this.tableView,
    required this.exportMode,
    required this.onTableViewChanged,
    required this.onExportModeChanged,
    required this.onParseBuffer,
    required this.onClearRecords,
    required this.onExportCsv,
    super.key,
  });

  final List<TrackRecord> records;
  final MagspoofTableView tableView;
  final MagspoofExportMode exportMode;
  final ValueChanged<MagspoofTableView> onTableViewChanged;
  final ValueChanged<MagspoofExportMode> onExportModeChanged;
  final VoidCallback onParseBuffer;
  final VoidCallback onClearRecords;
  final VoidCallback onExportCsv;

  @override
  Widget build(BuildContext context) {
    final isGrouped = tableView == MagspoofTableView.grouped;
    final columns = isGrouped ? groupedColumns : trackColumns;
    final rows = isGrouped
        ? groupTrackRecords(
            records,
          ).map((record) => record.toGroupedRow()).toList()
        : records.map((record) => record.toTrackRow()).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
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
                        'Datos parseados',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text('${rows.length} filas'),
                    ],
                  ),
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.end,
                  children: [
                    SegmentedButton<MagspoofTableView>(
                      segments: const [
                        ButtonSegment(
                          value: MagspoofTableView.tracks,
                          label: Text('Por track'),
                        ),
                        ButtonSegment(
                          value: MagspoofTableView.grouped,
                          label: Text('Agrupada'),
                        ),
                      ],
                      selected: {tableView},
                      onSelectionChanged: (selection) =>
                          onTableViewChanged(selection.first),
                    ),
                    DropdownButton<MagspoofExportMode>(
                      value: exportMode,
                      items: const [
                        DropdownMenuItem(
                          value: MagspoofExportMode.masked,
                          child: Text('Enmascarado'),
                        ),
                        DropdownMenuItem(
                          value: MagspoofExportMode.full,
                          child: Text('Completo'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) onExportModeChanged(value);
                      },
                    ),
                    OutlinedButton(
                      onPressed: onParseBuffer,
                      child: const Text('Parsear buffer'),
                    ),
                    OutlinedButton(
                      onPressed: onClearRecords,
                      child: const Text('Limpiar datos'),
                    ),
                    FilledButton(
                      onPressed: rows.isEmpty ? null : onExportCsv,
                      child: const Text('CSV'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: [
                  for (final column in columns) DataColumn(label: Text(column)),
                ],
                rows: rows.isEmpty
                    ? [
                        DataRow(
                          cells: [
                            DataCell(Text('No hay tracks detectados.')),
                            for (var i = 1; i < columns.length; i++)
                              const DataCell(Text('')),
                          ],
                        ),
                      ]
                    : [
                        for (final row in rows)
                          DataRow(
                            cells: [
                              for (final column in columns)
                                DataCell(Text(row[column] ?? '')),
                            ],
                          ),
                      ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

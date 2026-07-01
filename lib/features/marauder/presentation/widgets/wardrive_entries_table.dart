import 'package:flutter/material.dart';

import '../../domain/marauder_models.dart';

class WardriveEntriesTable extends StatelessWidget {
  const WardriveEntriesTable({
    required this.entries,
    this.showHeader = true,
    super.key,
  });

  final List<WardriveEntry> entries;
  final bool showHeader;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showHeader) ...[
          Row(
            children: [
              Text(
                'Captured networks',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              Text('${entries.length} rows', style: theme.textTheme.bodySmall),
            ],
          ),
          const SizedBox(height: 8),
        ],
        Expanded(
          child: entries.isEmpty
              ? Align(
                  alignment: Alignment.topLeft,
                  child: Text(
                    'No wardrive data yet. Start WiFi or BLE wardrive from the panel beside the terminal.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                )
              : DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(color: theme.colorScheme.outlineVariant),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Scrollbar(
                      thumbVisibility: true,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.vertical,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            headingRowHeight: 36,
                            dataRowMinHeight: 32,
                            dataRowMaxHeight: 40,
                            columnSpacing: 16,
                            columns: const [
                              DataColumn(label: Text('#')),
                              DataColumn(label: Text('MAC')),
                              DataColumn(label: Text('SSID / Name')),
                              DataColumn(label: Text('Security')),
                              DataColumn(label: Text('Ch')),
                              DataColumn(label: Text('RSSI')),
                              DataColumn(label: Text('Lat')),
                              DataColumn(label: Text('Lon')),
                              DataColumn(label: Text('Type')),
                            ],
                            rows: [
                              for (var i = 0; i < entries.length; i++)
                                _row(i + 1, entries[i]),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  DataRow _row(int index, WardriveEntry entry) {
    return DataRow(
      cells: [
        DataCell(Text('$index')),
        DataCell(
          Text(entry.mac, style: const TextStyle(fontFamily: 'monospace')),
        ),
        DataCell(Text(entry.ssid.isEmpty ? '—' : entry.ssid)),
        DataCell(Text(entry.security.isEmpty ? '—' : entry.security)),
        DataCell(Text(entry.channel)),
        DataCell(Text(entry.rssi)),
        DataCell(Text(entry.latitude)),
        DataCell(Text(entry.longitude)),
        DataCell(Text(entry.type)),
      ],
    );
  }
}

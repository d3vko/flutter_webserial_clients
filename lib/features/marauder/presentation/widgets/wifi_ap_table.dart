import 'package:flutter/material.dart';

import '../../domain/marauder_models.dart';

class WifiApTable extends StatefulWidget {
  const WifiApTable({
    required this.accessPoints,
    required this.isConnected,
    required this.onRefresh,
    required this.onClear,
    super.key,
  });

  final Map<String, AccessPoint> accessPoints;
  final bool isConnected;
  final VoidCallback onRefresh;
  final VoidCallback onClear;

  @override
  State<WifiApTable> createState() => _WifiApTableState();
}

class _WifiApTableState extends State<WifiApTable> {
  var _search = '';
  var _sortBy = 'rssi';

  @override
  Widget build(BuildContext context) {
    var aps = widget.accessPoints.values.toList();
    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      aps = aps
          .where(
            (ap) =>
                ap.essid.toLowerCase().contains(q) ||
                ap.bssid.toLowerCase().contains(q),
          )
          .toList();
    }

    aps.sort((a, b) {
      return switch (_sortBy) {
        'rssi' => (b.rssi ?? -999).compareTo(a.rssi ?? -999),
        'essid' => a.essid.compareTo(b.essid),
        'channel' => a.channel.compareTo(b.channel),
        _ => 0,
      };
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              'Access Points (${aps.length})',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const Spacer(),
            FilledButton(
              onPressed: widget.isConnected ? widget.onRefresh : null,
              child: const Text('Refresh'),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: widget.onClear,
              child: const Text('Clear'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                decoration: const InputDecoration(
                  hintText: 'Search ESSID or BSSID...',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: (v) => setState(() => _search = v),
              ),
            ),
            const SizedBox(width: 8),
            DropdownButton<String>(
              value: _sortBy,
              items: const [
                DropdownMenuItem(value: 'rssi', child: Text('Signal')),
                DropdownMenuItem(value: 'essid', child: Text('Name')),
                DropdownMenuItem(value: 'channel', child: Text('Channel')),
              ],
              onChanged: (v) => setState(() => _sortBy = v ?? 'rssi'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListView.separated(
              itemCount: aps.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final ap = aps[index];
                return ListTile(
                  dense: true,
                  title: Text('${ap.essid} (${ap.bssid})'),
                  subtitle: Text(
                    'CH ${ap.channel} · RSSI ${ap.rssi ?? 'N/A'} · STA ${ap.stations.length}',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                  trailing: ap.isSelected ? const Text('selected') : null,
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';

import '../../domain/marauder_models.dart';

class BleDeviceTable extends StatefulWidget {
  const BleDeviceTable({
    required this.devices,
    required this.isConnected,
    required this.onRefresh,
    required this.onClear,
    this.showEsp32C5Warning = false,
    super.key,
  });

  final Map<String, BluetoothDeviceEntry> devices;
  final bool isConnected;
  final VoidCallback onRefresh;
  final VoidCallback onClear;
  final bool showEsp32C5Warning;

  @override
  State<BleDeviceTable> createState() => _BleDeviceTableState();
}

class _BleDeviceTableState extends State<BleDeviceTable> {
  var _search = '';

  @override
  Widget build(BuildContext context) {
    var list = widget.devices.values.toList();
    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      list = list
          .where(
            (d) =>
                d.name.toLowerCase().contains(q) ||
                d.mac.toLowerCase().contains(q),
          )
          .toList();
    }
    list.sort((a, b) => (b.rssi ?? -999).compareTo(a.rssi ?? -999));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.showEsp32C5Warning) ...[
          const Text(
            'ESP32-C5: BLE spam TX supported; sniffing/BT wardrive not available.',
            style: TextStyle(fontSize: 12, color: Colors.amber),
          ),
          const SizedBox(height: 8),
        ],
        Row(
          children: [
            Text(
              'Bluetooth (${list.length})',
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
        TextField(
          decoration: const InputDecoration(
            hintText: 'Search name or MAC...',
            border: OutlineInputBorder(),
            isDense: true,
          ),
          onChanged: (v) => setState(() => _search = v),
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
              itemCount: list.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final d = list[index];
                return ListTile(
                  dense: true,
                  title: Text(d.name),
                  subtitle: Text(
                    '${d.mac} · RSSI ${d.rssi ?? 'N/A'}',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

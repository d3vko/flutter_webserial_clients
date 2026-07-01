import 'package:flutter/material.dart';

typedef CommandCallback = Future<void> Function(String command);

enum CommandBuilderMode { wifi, bluetooth }

class CommandBuilder extends StatefulWidget {
  const CommandBuilder({
    required this.onCommand,
    this.initialMode = CommandBuilderMode.wifi,
    super.key,
  });

  final CommandCallback onCommand;
  final CommandBuilderMode initialMode;

  @override
  State<CommandBuilder> createState() => _CommandBuilderState();
}

class _CommandBuilderState extends State<CommandBuilder> {
  final _customController = TextEditingController();
  late CommandBuilderMode _mode;

  @override
  void initState() {
    super.initState();
    _mode = widget.initialMode;
  }

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  Future<void> _send(String command) => widget.onCommand(command);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Commands', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            SegmentedButton<CommandBuilderMode>(
              segments: const [
                ButtonSegment(
                  value: CommandBuilderMode.wifi,
                  label: Text('WiFi'),
                ),
                ButtonSegment(
                  value: CommandBuilderMode.bluetooth,
                  label: Text('Bluetooth'),
                ),
              ],
              selected: {_mode},
              onSelectionChanged: (s) => setState(() => _mode = s.first),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton.tonal(
                    onPressed: () => _send('stopscan'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.red.withValues(alpha: 0.2),
                    ),
                    child: const Text('Stop'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    onPressed: () => _send(
                      _mode == CommandBuilderMode.wifi ? 'list -a' : 'list -t',
                    ),
                    child: Text(
                      _mode == CommandBuilderMode.wifi ? 'List APs' : 'List BT',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_mode == CommandBuilderMode.wifi) ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final cmd in const [
                    ('Scan AP', 'scanap'),
                    ('Scan All', 'scanall'),
                    ('Sniff Beacon', 'sniffbeacon'),
                    ('Sniff Deauth', 'sniffdeauth'),
                    ('Sniff PMKID', 'sniffpmkid'),
                    ('Wardrive', 'wardrive -serial'),
                  ])
                    OutlinedButton(
                      onPressed: () => _send(cmd.$2),
                      child: Text(cmd.$1),
                    ),
                  _disabledCmd(
                    context,
                    'Sniff BT',
                    'Not supported on ESP32-C5 (single-core)',
                  ),
                  _disabledCmd(
                    context,
                    'BT Wardrive',
                    'Not supported on ESP32-C5 (single-core)',
                  ),
                ],
              ),
            ] else ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final cmd in const [
                    ('Spam Apple', 'blespam -t apple'),
                    ('Spam Windows', 'blespam -t windows'),
                    ('Spam Samsung', 'blespam -t samsung'),
                    ('Spam Google', 'blespam -t google'),
                    ('Spam Flipper', 'blespam -t flipper'),
                    ('Spam All', 'blespam -t all'),
                    ('Spoof Airtag', 'spoofat -t airtag'),
                  ])
                    OutlinedButton(
                      onPressed: () => _send(cmd.$2),
                      child: Text(cmd.$1),
                    ),
                  _disabledCmd(
                    context,
                    'Sniff BT',
                    'BLE sniffing not available on ESP32-C5',
                  ),
                  _disabledCmd(
                    context,
                    'BT Wardrive',
                    'BT wardrive not available on ESP32-C5',
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _customController,
                    decoration: const InputDecoration(
                      hintText: 'Enter command...',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onSubmitted: (value) async {
                      if (value.trim().isEmpty) return;
                      await _send(value.trim());
                      _customController.clear();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () async {
                    final value = _customController.text.trim();
                    if (value.isEmpty) return;
                    await _send(value);
                    _customController.clear();
                  },
                  child: const Text('Send'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _disabledCmd(BuildContext context, String label, String tooltip) {
    return Tooltip(
      message: tooltip,
      child: OutlinedButton(onPressed: null, child: Text(label)),
    );
  }
}

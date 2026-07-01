import 'package:flutter/material.dart';

class SystemUtilitiesPanel extends StatefulWidget {
  const SystemUtilitiesPanel({
    required this.onCommand,
    required this.onOpenStorage,
    super.key,
  });

  final Future<void> Function(String command) onCommand;
  final VoidCallback onOpenStorage;

  @override
  State<SystemUtilitiesPanel> createState() => _SystemUtilitiesPanelState();
}

class _SystemUtilitiesPanelState extends State<SystemUtilitiesPanel> {
  final _channelController = TextEditingController(text: '1');
  final _ledController = TextEditingController(text: '#00ff00');
  final _settingController = TextEditingController();

  @override
  void dispose() {
    _channelController.dispose();
    _ledController.dispose();
    _settingController.dispose();
    super.dispose();
  }

  Future<void> _confirmCommand(String cmd) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm'),
        content: Text('Execute: $cmd?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    if (ok == true) await widget.onCommand(cmd);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'System Utilities',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.tonal(
                  onPressed: () => _confirmCommand('reboot'),
                  child: const Text('Reboot'),
                ),
                FilledButton(
                  onPressed: () => widget.onCommand('info'),
                  child: const Text('Sys Info'),
                ),
                FilledButton.tonal(
                  onPressed: widget.onOpenStorage,
                  child: const Text('Storage'),
                ),
                OutlinedButton(
                  onPressed: () => widget.onCommand('clearlist -a'),
                  child: const Text('Clear APs'),
                ),
                OutlinedButton(
                  onPressed: () => widget.onCommand('clearlist -c'),
                  child: const Text('Clear Stations'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _channelController,
                    decoration: const InputDecoration(
                      labelText: 'Channel 1-14',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.tonal(
                  onPressed: () {
                    final ch = int.tryParse(_channelController.text);
                    if (ch != null && ch >= 1 && ch <= 14) {
                      widget.onCommand('channel -s $ch');
                    }
                  },
                  child: const Text('Set'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ledController,
                    decoration: const InputDecoration(
                      labelText: 'LED #RRGGBB',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.tonal(
                  onPressed: () =>
                      widget.onCommand('led -s ${_ledController.text.trim()}'),
                  child: const Text('Set LED'),
                ),
              ],
            ),
            OutlinedButton(
              onPressed: () => widget.onCommand('led -p rainbow'),
              child: const Text('Rainbow'),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                OutlinedButton(
                  onPressed: () => widget.onCommand('autostart on'),
                  child: const Text('Autostart On'),
                ),
                OutlinedButton(
                  onPressed: () => widget.onCommand('autostart off'),
                  child: const Text('Off'),
                ),
                OutlinedButton(
                  onPressed: () => widget.onCommand('autostart status'),
                  child: const Text('Status'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _settingController,
                    decoration: const InputDecoration(
                      labelText: 'setting_name',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () {
                    final name = _settingController.text.trim();
                    if (name.isNotEmpty)
                      widget.onCommand('settings -s $name enable');
                  },
                  child: const Text('Enable'),
                ),
                OutlinedButton(
                  onPressed: () {
                    final name = _settingController.text.trim();
                    if (name.isNotEmpty)
                      widget.onCommand('settings -s $name disable');
                  },
                  child: const Text('Disable'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

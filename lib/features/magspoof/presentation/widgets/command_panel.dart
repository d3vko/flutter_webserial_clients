import 'package:flutter/material.dart';

import '../../domain/magspoof_commands.dart';

class MagspoofCommandPanel extends StatefulWidget {
  const MagspoofCommandPanel({
    required this.track1Controller,
    required this.track2Controller,
    required this.onQuickCommand,
    required this.onManualCommand,
    required this.onSendTrack1,
    required this.onSendTrack2,
    super.key,
  });

  final TextEditingController track1Controller;
  final TextEditingController track2Controller;
  final ValueChanged<String> onQuickCommand;
  final ValueChanged<String> onManualCommand;
  final VoidCallback onSendTrack1;
  final VoidCallback onSendTrack2;

  @override
  State<MagspoofCommandPanel> createState() => _MagspoofCommandPanelState();
}

class _MagspoofCommandPanelState extends State<MagspoofCommandPanel> {
  final _manualController = TextEditingController();

  @override
  void dispose() {
    _manualController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Comandos', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final command in magspoofQuickCommands)
                  OutlinedButton(
                    onPressed: () => widget.onQuickCommand(command),
                    child: Text(command),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _manualController,
                    decoration: const InputDecoration(
                      labelText: 'Texto crudo',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (value) {
                      widget.onManualCommand(value);
                      _manualController.clear();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () {
                    widget.onManualCommand(_manualController.text);
                    _manualController.clear();
                  },
                  child: const Text('Enviar'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: widget.track1Controller,
              decoration: const InputDecoration(
                labelText: 'Track 1',
                border: OutlineInputBorder(),
              ),
              minLines: 2,
              maxLines: 3,
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: widget.onSendTrack1,
              child: const Text('Enviar Track 1'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: widget.track2Controller,
              decoration: const InputDecoration(
                labelText: 'Track 2',
                border: OutlineInputBorder(),
              ),
              minLines: 2,
              maxLines: 3,
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: widget.onSendTrack2,
              child: const Text('Enviar Track 2'),
            ),
          ],
        ),
      ),
    );
  }
}

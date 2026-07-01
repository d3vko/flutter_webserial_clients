import 'package:flutter/material.dart';

class MagspoofTerminalPanel extends StatelessWidget {
  const MagspoofTerminalPanel({
    required this.rawTerminal,
    required this.scrollController,
    required this.onClear,
    super.key,
  });

  final String rawTerminal;
  final ScrollController scrollController;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Terminal raw',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                TextButton(onPressed: onClear, child: const Text('Limpiar')),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              height: 240,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: scheme.outlineVariant),
              ),
              child: Scrollbar(
                controller: scrollController,
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: SelectableText(
                    rawTerminal.isEmpty ? 'Sin datos seriales.' : rawTerminal,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

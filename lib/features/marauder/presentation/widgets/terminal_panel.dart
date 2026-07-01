import 'package:flutter/material.dart';

import '../../domain/marauder_models.dart';

class TerminalPanel extends StatelessWidget {
  const TerminalPanel({
    required this.lines,
    required this.scrollController,
    super.key,
  });

  final List<TerminalLine> lines;
  final ScrollController scrollController;

  Color _colorForType(TerminalLineType type, ColorScheme scheme) {
    return switch (type) {
      TerminalLineType.normal => Colors.greenAccent,
      TerminalLineType.success => Colors.lightBlueAccent,
      TerminalLineType.error => Colors.redAccent,
      TerminalLineType.command => Colors.amberAccent,
    };
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Terminal', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: scheme.outlineVariant),
                ),
                child: Scrollbar(
                  controller: scrollController,
                  child: ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.all(8),
                    itemCount: lines.length,
                    itemBuilder: (context, index) {
                      final line = lines[index];
                      return SelectableText(
                        line.text,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          color: _colorForType(line.type, scheme),
                        ),
                      );
                    },
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

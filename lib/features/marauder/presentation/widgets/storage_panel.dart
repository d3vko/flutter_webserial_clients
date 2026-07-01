import 'package:flutter/material.dart';

import '../../domain/marauder_models.dart';
import '../../domain/spiffs_parser.dart';

class StoragePanel extends StatelessWidget {
  const StoragePanel({
    required this.files,
    required this.storageInfo,
    required this.isCapturing,
    required this.capturingFileName,
    required this.onList,
    required this.onDownload,
    required this.onDelete,
    required this.onFormat,
    super.key,
  });

  final List<SpiffsFile> files;
  final String storageInfo;
  final bool isCapturing;
  final String capturingFileName;
  final VoidCallback onList;
  final void Function(String name) onDownload;
  final void Function(String name) onDelete;
  final VoidCallback onFormat;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            FilledButton(onPressed: onList, child: const Text('List Files')),
            const SizedBox(width: 8),
            FilledButton.tonal(
              onPressed: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Format storage?'),
                    content: const Text(
                      'Delete all files except settings? This cannot be undone.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Confirm'),
                      ),
                    ],
                  ),
                );
                if (ok == true) onFormat();
              },
              child: const Text('Format Storage'),
            ),
            const Spacer(),
            if (storageInfo.isNotEmpty)
              Text(
                storageInfo,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
          ],
        ),
        if (isCapturing) ...[
          const SizedBox(height: 8),
          Text('Downloading $capturingFileName...'),
        ],
        const SizedBox(height: 12),
        Expanded(
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: files.isEmpty
                ? const Center(
                    child: Text('No files listed. Press List Files.'),
                  )
                : ListView.separated(
                    itemCount: files.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final file = files[index];
                      final protected = file.name == '/settings.json';
                      return ListTile(
                        dense: true,
                        title: Text(
                          file.name,
                          style: const TextStyle(fontFamily: 'monospace'),
                        ),
                        subtitle: Text(formatSpiffsSize(file.size)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextButton(
                              onPressed: () => onDownload(file.name),
                              child: const Text('Download'),
                            ),
                            TextButton(
                              onPressed: protected
                                  ? null
                                  : () => onDelete(file.name),
                              child: const Text('Delete'),
                            ),
                          ],
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

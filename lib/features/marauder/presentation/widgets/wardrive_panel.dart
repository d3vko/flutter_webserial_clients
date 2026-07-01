import 'package:flutter/material.dart';

import '../../domain/marauder_models.dart';

class WardrivePanel extends StatelessWidget {
  const WardrivePanel({
    required this.entryCount,
    required this.uploadPhase,
    required this.uploadError,
    required this.isUploading,
    required this.isLoggedIn,
    required this.onDownload,
    required this.onUpload,
    required this.onClear,
    super.key,
  });

  final int entryCount;
  final MarauderUploadPhase uploadPhase;
  final String uploadError;
  final bool isUploading;
  final bool isLoggedIn;
  final VoidCallback onDownload;
  final VoidCallback onUpload;
  final VoidCallback onClear;

  String get _uploadLabel {
    return switch (uploadPhase) {
      MarauderUploadPhase.idle => '',
      MarauderUploadPhase.uploading => 'Uploading…',
      MarauderUploadPhase.ok => 'Upload OK',
      MarauderUploadPhase.error => uploadError,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Wardrive', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Text('$entryCount entries captured (WiGLE format)'),
        if (_uploadLabel.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            _uploadLabel,
            style: TextStyle(
              color: uploadPhase == MarauderUploadPhase.error
                  ? Colors.redAccent
                  : uploadPhase == MarauderUploadPhase.ok
                  ? Colors.greenAccent
                  : null,
            ),
          ),
        ],
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton(
              onPressed: entryCount > 0 ? onDownload : null,
              child: const Text('Export CSV'),
            ),
            FilledButton.tonal(
              onPressed: entryCount > 0 && !isUploading ? onUpload : null,
              child: Text(isLoggedIn ? 'Upload' : 'Upload (login)'),
            ),
            OutlinedButton(
              onPressed: entryCount > 0 ? onClear : null,
              child: const Text('Clear'),
            ),
          ],
        ),
      ],
    );
  }
}

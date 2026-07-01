import 'package:flutter/material.dart';

import '../../../../core/config/device_profile.dart';
import '../../domain/marauder_models.dart';
import 'marauder_command_section.dart';

class WardrivePanel extends StatelessWidget {
  const WardrivePanel({
    required this.entryCount,
    required this.uploadPhase,
    required this.uploadError,
    required this.isUploading,
    required this.isLoggedIn,
    required this.isConnected,
    required this.capabilities,
    required this.onCommand,
    required this.onDownload,
    required this.onUpload,
    required this.onClear,
    this.dialect,
    super.key,
  });

  final int entryCount;
  final MarauderUploadPhase uploadPhase;
  final String uploadError;
  final bool isUploading;
  final bool isLoggedIn;
  final bool isConnected;
  final MarauderCapabilities capabilities;
  final Future<void> Function(String command) onCommand;
  final VoidCallback onDownload;
  final VoidCallback onUpload;
  final VoidCallback onClear;
  final WardriveDialect? dialect;

  String get _uploadLabel {
    return switch (uploadPhase) {
      MarauderUploadPhase.idle => '',
      MarauderUploadPhase.uploading => 'Uploading…',
      MarauderUploadPhase.ok => 'Upload OK',
      MarauderUploadPhase.error => uploadError,
    };
  }

  String? get _dialectLabel {
    final d = dialect;
    if (d == null) return null;
    final parts = <String>[
      if (d.sourceFormat.isNotEmpty) d.sourceFormat,
      if (d.sourceVersion.isNotEmpty) d.sourceVersion,
      if (d.appRelease.isNotEmpty) d.appRelease,
    ];
    if (parts.isEmpty) return null;
    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final caps = capabilities;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text('Wardrive', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(width: 12),
            Text(
              '$entryCount WiGLE entries',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
        if (_dialectLabel != null) ...[
          const SizedBox(height: 4),
          Text(
            _dialectLabel!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
        if (_uploadLabel.isNotEmpty) ...[
          const SizedBox(height: 6),
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
        const SizedBox(height: 14),
        MarauderCommandSection(
          title: '1. Start capture',
          subtitle: 'Requires GPS fix for coordinates (-serial streams to UI)',
          children: [
            FilledButton(
              onPressed: isConnected
                  ? () => onCommand(caps.wifiWardriveCommand)
                  : null,
              child: const Text('WiFi Wardrive'),
            ),
            if (caps.wifiStationWardriveCommand != null)
              FilledButton.tonal(
                onPressed: isConnected
                    ? () => onCommand(caps.wifiStationWardriveCommand!)
                    : null,
                child: const Text('WiFi Stations'),
              ),
            if (caps.supportsBtWardrive && caps.btWardriveCommand != null)
              FilledButton(
                onPressed: isConnected
                    ? () => onCommand(caps.btWardriveCommand!)
                    : null,
                child: const Text('BLE Wardrive'),
              ),
            if (caps.btWardriveContinuousCommand != null)
              FilledButton.tonal(
                onPressed: isConnected
                    ? () => onCommand(caps.btWardriveContinuousCommand!)
                    : null,
                child: const Text('BLE Wardrive (−c)'),
              ),
            FilledButton.tonal(
              onPressed: isConnected ? () => onCommand('stopscan') : null,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red.withValues(alpha: 0.2),
              ),
              child: const Text('Stop'),
            ),
          ],
        ),
        const SizedBox(height: 14),
        MarauderCommandSection(
          title: '2. Export & upload',
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

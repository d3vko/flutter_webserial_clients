import 'package:flutter/material.dart';

import '../../../../core/config/device_profile.dart';
import '../../domain/marauder_models.dart';
import 'marauder_command_section.dart';

/// Narrow command column shown beside the terminal on GPS / Wardrive tabs.
class MarauderGeoCommandRail extends StatelessWidget {
  const MarauderGeoCommandRail({
    required this.view,
    required this.capabilities,
    required this.isConnected,
    required this.onCommand,
    this.wardriveEntryCount = 0,
    this.uploadPhase = MarauderUploadPhase.idle,
    this.uploadError = '',
    this.isUploading = false,
    this.isLoggedIn = false,
    this.onDownload,
    this.onUpload,
    this.onClear,
    super.key,
  });

  final MarauderView view;
  final MarauderCapabilities capabilities;
  final bool isConnected;
  final Future<void> Function(String command) onCommand;
  final int wardriveEntryCount;
  final MarauderUploadPhase uploadPhase;
  final String uploadError;
  final bool isUploading;
  final bool isLoggedIn;
  final VoidCallback? onDownload;
  final VoidCallback? onUpload;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Scrollbar(
          thumbVisibility: true,
          child: SingleChildScrollView(
            child: switch (view) {
              MarauderView.gps => GpsCommandRail(
                capabilities: capabilities,
                isConnected: isConnected,
                onCommand: onCommand,
              ),
              MarauderView.wardrive => WardriveCommandRail(
                capabilities: capabilities,
                isConnected: isConnected,
                onCommand: onCommand,
                entryCount: wardriveEntryCount,
                uploadPhase: uploadPhase,
                uploadError: uploadError,
                isUploading: isUploading,
                isLoggedIn: isLoggedIn,
                onDownload: onDownload,
                onUpload: onUpload,
                onClear: onClear,
              ),
              _ => const SizedBox.shrink(),
            },
          ),
        ),
      ),
    );
  }
}

class WardriveCommandRail extends StatelessWidget {
  const WardriveCommandRail({
    required this.capabilities,
    required this.isConnected,
    required this.onCommand,
    required this.entryCount,
    required this.uploadPhase,
    required this.uploadError,
    required this.isUploading,
    required this.isLoggedIn,
    this.onDownload,
    this.onUpload,
    this.onClear,
    super.key,
  });

  final MarauderCapabilities capabilities;
  final bool isConnected;
  final Future<void> Function(String command) onCommand;
  final int entryCount;
  final MarauderUploadPhase uploadPhase;
  final String uploadError;
  final bool isUploading;
  final bool isLoggedIn;
  final VoidCallback? onDownload;
  final VoidCallback? onUpload;
  final VoidCallback? onClear;

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
    final caps = capabilities;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Wardrive', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 4),
        Text(
          '$entryCount WiGLE entries',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        if (_uploadLabel.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            _uploadLabel,
            style: TextStyle(
              fontSize: 12,
              color: uploadPhase == MarauderUploadPhase.error
                  ? Colors.redAccent
                  : uploadPhase == MarauderUploadPhase.ok
                  ? Colors.greenAccent
                  : null,
            ),
          ),
        ],
        const SizedBox(height: 12),
        MarauderCommandSection(
          title: 'Capture',
          subtitle: 'GPS fix required · -serial streams to UI',
          children: [
            _fullWidth(
              FilledButton(
                onPressed: isConnected
                    ? () => onCommand(caps.wifiWardriveCommand)
                    : null,
                child: const Text('WiFi Wardrive'),
              ),
            ),
            if (caps.wifiStationWardriveCommand != null)
              _fullWidth(
                FilledButton.tonal(
                  onPressed: isConnected
                      ? () => onCommand(caps.wifiStationWardriveCommand!)
                      : null,
                  child: const Text('WiFi Stations'),
                ),
              ),
            if (caps.supportsBtWardrive && caps.btWardriveCommand != null)
              _fullWidth(
                FilledButton(
                  onPressed: isConnected
                      ? () => onCommand(caps.btWardriveCommand!)
                      : null,
                  child: const Text('BLE Wardrive'),
                ),
              ),
            if (caps.btWardriveContinuousCommand != null)
              _fullWidth(
                FilledButton.tonal(
                  onPressed: isConnected
                      ? () => onCommand(caps.btWardriveContinuousCommand!)
                      : null,
                  child: const Text('BLE Wardrive (−c)'),
                ),
              ),
            _fullWidth(
              FilledButton.tonal(
                onPressed: isConnected ? () => onCommand('stopscan') : null,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.red.withValues(alpha: 0.2),
                ),
                child: const Text('Stop'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        MarauderCommandSection(
          title: 'Export',
          children: [
            _fullWidth(
              FilledButton(
                onPressed: entryCount > 0 ? onDownload : null,
                child: const Text('Export CSV'),
              ),
            ),
            _fullWidth(
              FilledButton.tonal(
                onPressed: entryCount > 0 && !isUploading ? onUpload : null,
                child: Text(isLoggedIn ? 'Upload' : 'Upload (login)'),
              ),
            ),
            _fullWidth(
              OutlinedButton(
                onPressed: entryCount > 0 ? onClear : null,
                child: const Text('Clear'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class GpsCommandRail extends StatelessWidget {
  const GpsCommandRail({
    required this.capabilities,
    required this.isConnected,
    required this.onCommand,
    super.key,
  });

  final MarauderCapabilities capabilities;
  final bool isConnected;
  final Future<void> Function(String command) onCommand;

  static const _constellations = [
    ('Native', 'native'),
    ('All', 'all'),
    ('GPS', 'gps'),
    ('GLONASS', 'glonass'),
    ('Galileo', 'galileo'),
    ('BeiDou', 'beidou'),
    ('NavIC', 'navic'),
    ('QZSS', 'qzss'),
  ];

  @override
  Widget build(BuildContext context) {
    final caps = capabilities;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('GPS', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 12),
        MarauderCommandSection(
          title: 'Stream',
          children: [
            _fullWidth(
              FilledButton(
                onPressed: isConnected ? () => onCommand('gpsdata') : null,
                child: const Text('GPS Data'),
              ),
            ),
            _fullWidth(
              FilledButton(
                onPressed: isConnected ? () => onCommand('nmea') : null,
                child: const Text('NMEA Stream'),
              ),
            ),
            _fullWidth(
              FilledButton.tonal(
                onPressed: isConnected
                    ? () => onCommand(caps.gpsTrackerStartCommand)
                    : null,
                child: const Text('Tracker'),
              ),
            ),
            if (caps.gpsTrackerStopCommand != null)
              _fullWidth(
                FilledButton.tonal(
                  onPressed: isConnected
                      ? () => onCommand(caps.gpsTrackerStopCommand!)
                      : null,
                  child: const Text('Tracker Stop'),
                ),
              ),
            _fullWidth(
              FilledButton.tonal(
                onPressed: isConnected ? () => onCommand('stopscan') : null,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.red.withValues(alpha: 0.2),
                ),
                child: const Text('Stop'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        MarauderCommandSection(
          title: 'Query',
          children: [
            for (final q in const [
              ('Fix', 'gps -g fix'),
              ('Sats', 'gps -g sat'),
              ('Lat', 'gps -g lat'),
              ('Lon', 'gps -g lon'),
              ('Alt', 'gps -g alt'),
              ('Accuracy', 'gps -g accuracy'),
              ('Date', 'gps -g date'),
              ('NMEA', 'gps -g nmea'),
            ])
              _fullWidth(
                OutlinedButton(
                  onPressed: isConnected ? () => onCommand(q.$2) : null,
                  child: Text(q.$1),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        MarauderCommandSection(
          title: 'POI',
          children: [
            _fullWidth(
              FilledButton.tonal(
                onPressed: isConnected ? () => onCommand('gpspoi -s') : null,
                child: const Text('POI Start'),
              ),
            ),
            _fullWidth(
              FilledButton.tonal(
                onPressed: isConnected ? () => onCommand('gpspoi -m') : null,
                child: const Text('POI Mark'),
              ),
            ),
            _fullWidth(
              OutlinedButton(
                onPressed: isConnected ? () => onCommand('gpspoi -e') : null,
                child: const Text('POI End'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        MarauderCommandSection(
          title: 'Constellation',
          children: [
            for (final c in _constellations)
              _fullWidth(
                OutlinedButton(
                  onPressed: isConnected
                      ? () => onCommand('gps -n ${c.$2}')
                      : null,
                  child: Text(c.$1),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

Widget _fullWidth(Widget child) {
  return SizedBox(width: double.infinity, child: child);
}

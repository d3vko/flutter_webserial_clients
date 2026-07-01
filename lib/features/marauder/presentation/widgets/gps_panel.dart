import 'package:flutter/material.dart';

import '../../../../core/config/device_profile.dart';
import '../../domain/marauder_models.dart';
import 'marauder_command_section.dart';

class GpsPanel extends StatelessWidget {
  const GpsPanel({
    required this.telemetry,
    required this.logLines,
    required this.capabilities,
    required this.isConnected,
    required this.onCommand,
    this.showTelemetry = true,
    super.key,
  });

  final GpsTelemetry telemetry;
  final List<String> logLines;
  final MarauderCapabilities capabilities;
  final bool isConnected;
  final Future<void> Function(String command) onCommand;
  final bool showTelemetry;

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
        if (showTelemetry) ...[
          MarauderTelemetryBar(
            fix: telemetry.fix,
            sats: telemetry.sats,
            lat: telemetry.lat,
            lon: telemetry.lon,
            alt: telemetry.alt,
            accuracy: telemetry.accuracy,
            datetime: telemetry.datetime,
          ),
          const SizedBox(height: 12),
        ],
        MarauderCommandSection(
          title: '1. Stream & track',
          subtitle: 'Continuous GPS output from the module',
          children: [
            FilledButton(
              onPressed: isConnected ? () => onCommand('gpsdata') : null,
              child: const Text('GPS Data'),
            ),
            FilledButton(
              onPressed: isConnected ? () => onCommand('nmea') : null,
              child: const Text('NMEA Stream'),
            ),
            FilledButton.tonal(
              onPressed: isConnected
                  ? () => onCommand(caps.gpsTrackerStartCommand)
                  : null,
              child: const Text('Tracker'),
            ),
            if (caps.gpsTrackerStopCommand != null)
              FilledButton.tonal(
                onPressed: isConnected
                    ? () => onCommand(caps.gpsTrackerStopCommand!)
                    : null,
                child: const Text('Tracker Stop'),
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
          title: '2. Quick query',
          subtitle: 'One-shot gps -g reads',
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
              OutlinedButton(
                onPressed: isConnected ? () => onCommand(q.$2) : null,
                child: Text(q.$1),
              ),
          ],
        ),
        const SizedBox(height: 14),
        MarauderCommandSection(
          title: '3. POI markers',
          children: [
            FilledButton.tonal(
              onPressed: isConnected ? () => onCommand('gpspoi -s') : null,
              child: const Text('POI Start'),
            ),
            FilledButton.tonal(
              onPressed: isConnected ? () => onCommand('gpspoi -m') : null,
              child: const Text('POI Mark'),
            ),
            OutlinedButton(
              onPressed: isConnected ? () => onCommand('gpspoi -e') : null,
              child: const Text('POI End'),
            ),
          ],
        ),
        const SizedBox(height: 14),
        MarauderCommandSection(
          title: '4. Constellation',
          subtitle: 'gps -n output filter',
          children: [
            for (final c in _constellations)
              OutlinedButton(
                onPressed: isConnected
                    ? () => onCommand('gps -n ${c.$2}')
                    : null,
                child: Text(c.$1),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'GPS log',
          style: Theme.of(
            context,
          ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 140,
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: logLines.isEmpty
                  ? const Align(
                      alignment: Alignment.topLeft,
                      child: Text(
                        'No GPS lines yet — start GPS Data or NMEA Stream.',
                      ),
                    )
                  : ListView.builder(
                      itemCount: logLines.length,
                      itemBuilder: (context, index) => Text(
                        logLines[index],
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11,
                        ),
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }
}

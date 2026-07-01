import 'package:flutter/material.dart';

import '../../domain/marauder_models.dart';

class GpsPanel extends StatelessWidget {
  const GpsPanel({
    required this.telemetry,
    required this.logLines,
    required this.onCommand,
    super.key,
  });

  final GpsTelemetry telemetry;
  final List<String> logLines;
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _stat('Fix', telemetry.fix == true ? 'Yes' : 'No'),
            _stat('Sats', '${telemetry.sats ?? '--'}'),
            _stat('Lat', telemetry.lat ?? '--'),
            _stat('Lon', telemetry.lon ?? '--'),
            _stat('Alt', telemetry.alt != null ? '${telemetry.alt}m' : '--'),
            _stat('Accuracy', telemetry.accuracy ?? '--'),
            _stat('Date/Time', telemetry.datetime ?? '--'),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton(
              onPressed: () => onCommand('gpsdata'),
              child: const Text('GPS Data'),
            ),
            FilledButton(
              onPressed: () => onCommand('nmea'),
              child: const Text('NMEA Stream'),
            ),
            FilledButton.tonal(
              onPressed: () => onCommand('gps -t'),
              child: const Text('Tracker'),
            ),
            FilledButton.tonal(
              onPressed: () => onCommand('stopscan'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red.withValues(alpha: 0.2),
              ),
              child: const Text('Stop'),
            ),
            for (final q in const [
              ('Fix', 'gps -g fix'),
              ('Sats', 'gps -g sat'),
              ('Lat', 'gps -g lat'),
              ('Lon', 'gps -g lon'),
              ('Alt', 'gps -g alt'),
              ('Date', 'gps -g date'),
              ('NMEA', 'gps -g nmea'),
            ])
              OutlinedButton(
                onPressed: () => onCommand(q.$2),
                child: Text(q.$1),
              ),
            FilledButton.tonal(
              onPressed: () => onCommand('gpspoi -s'),
              child: const Text('POI Start'),
            ),
            FilledButton.tonal(
              onPressed: () => onCommand('gpspoi -m'),
              child: const Text('POI Mark'),
            ),
            OutlinedButton(
              onPressed: () => onCommand('gpspoi -e'),
              child: const Text('POI End'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            const Text('Constellation:', style: TextStyle(fontSize: 12)),
            for (final c in _constellations)
              OutlinedButton(
                onPressed: () => onCommand('gps -n ${c.$2}'),
                child: Text(c.$1),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          height: 200,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: logLines.isEmpty
              ? const Text('No GPS data yet. Press GPS Data or NMEA Stream.')
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
      ],
    );
  }

  Widget _stat(String label, String value) {
    return Chip(
      label: Text(
        '$label: $value',
        style: const TextStyle(fontFamily: 'monospace'),
      ),
    );
  }
}

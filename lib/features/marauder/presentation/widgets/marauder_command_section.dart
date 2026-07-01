import 'package:flutter/material.dart';

/// Grouped Marauder CLI actions under a short heading.
class MarauderCommandSection extends StatelessWidget {
  const MarauderCommandSection({
    required this.title,
    required this.children,
    this.subtitle,
    super.key,
  });

  final String title;
  final String? subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.4,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(
            subtitle!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.65),
            ),
          ),
        ],
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: children),
      ],
    );
  }
}

/// Compact telemetry chips for GPS / wardrive headers.
class MarauderTelemetryBar extends StatelessWidget {
  const MarauderTelemetryBar({
    required this.fix,
    required this.sats,
    required this.lat,
    required this.lon,
    required this.alt,
    required this.accuracy,
    required this.datetime,
    super.key,
  });

  final bool? fix;
  final int? sats;
  final String? lat;
  final String? lon;
  final String? alt;
  final String? accuracy;
  final String? datetime;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _chip('Fix', fix == true ? 'Yes' : 'No'),
        _chip('Sats', '${sats ?? '--'}'),
        _chip('Lat', lat ?? '--'),
        _chip('Lon', lon ?? '--'),
        _chip('Alt', alt != null ? '${alt}m' : '--'),
        _chip('Accuracy', accuracy ?? '--'),
        _chip('Date/Time', datetime ?? '--'),
      ],
    );
  }

  Widget _chip(String label, String value) {
    return Chip(
      label: Text(
        '$label: $value',
        style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
      ),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}

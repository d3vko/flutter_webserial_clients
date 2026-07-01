import 'package:flutter/material.dart';

import '../../domain/marauder_map_points.dart';
import '../../domain/marauder_models.dart';
import 'marauder_command_section.dart';
import 'marauder_map_section.dart';
import 'wardrive_entries_table.dart';

enum _WardriveSubView { map, table }

enum _GpsSubView { map, log }

class WardriveDataPane extends StatefulWidget {
  const WardriveDataPane({
    required this.entries,
    required this.gpsTelemetry,
    this.dialect,
    super.key,
  });

  final List<WardriveEntry> entries;
  final GpsTelemetry gpsTelemetry;
  final WardriveDialect? dialect;

  @override
  State<WardriveDataPane> createState() => _WardriveDataPaneState();
}

class _WardriveDataPaneState extends State<WardriveDataPane> {
  _WardriveSubView _subView = _WardriveSubView.map;

  String? get _dialectLabel {
    final d = widget.dialect;
    if (d == null) return null;
    final parts = <String>[
      if (d.sourceFormat.isNotEmpty) d.sourceFormat,
      if (d.sourceVersion.isNotEmpty) d.sourceVersion,
      if (d.appRelease.isNotEmpty) d.appRelease,
    ];
    if (parts.isEmpty) return null;
    return parts.join(' · ');
  }

  int get _mapPointCount => marauderMapPoints(
    wardriveEntries: widget.entries,
    gpsTelemetry: widget.gpsTelemetry,
    includeGpsFix: true,
  ).length;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_dialectLabel != null) ...[
          Text(
            _dialectLabel!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
        ],
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ChoiceChip(
              label: Text('Map ($_mapPointCount)'),
              selected: _subView == _WardriveSubView.map,
              onSelected: (_) =>
                  setState(() => _subView = _WardriveSubView.map),
            ),
            ChoiceChip(
              label: Text('Table (${widget.entries.length})'),
              selected: _subView == _WardriveSubView.table,
              onSelected: (_) =>
                  setState(() => _subView = _WardriveSubView.table),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Expanded(
          child: switch (_subView) {
            _WardriveSubView.map => MarauderMapSection(
              wardriveEntries: widget.entries,
              gpsTelemetry: widget.gpsTelemetry,
              includeGpsFix: true,
              expandMap: true,
            ),
            _WardriveSubView.table => WardriveEntriesTable(
              entries: widget.entries,
              showHeader: false,
            ),
          },
        ),
      ],
    );
  }
}

class GpsDataPane extends StatefulWidget {
  const GpsDataPane({
    required this.telemetry,
    required this.logLines,
    required this.wardriveEntries,
    super.key,
  });

  final GpsTelemetry telemetry;
  final List<String> logLines;
  final List<WardriveEntry> wardriveEntries;

  @override
  State<GpsDataPane> createState() => _GpsDataPaneState();
}

class _GpsDataPaneState extends State<GpsDataPane> {
  _GpsSubView _subView = _GpsSubView.map;

  int get _mapPointCount => marauderMapPoints(
    wardriveEntries: widget.wardriveEntries,
    gpsTelemetry: widget.telemetry,
    includeWardrive: false,
    includeGpsFix: true,
  ).length;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MarauderTelemetryBar(
          fix: widget.telemetry.fix,
          sats: widget.telemetry.sats,
          lat: widget.telemetry.lat,
          lon: widget.telemetry.lon,
          alt: widget.telemetry.alt,
          accuracy: widget.telemetry.accuracy,
          datetime: widget.telemetry.datetime,
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ChoiceChip(
              label: Text('Map ($_mapPointCount)'),
              selected: _subView == _GpsSubView.map,
              onSelected: (_) => setState(() => _subView = _GpsSubView.map),
            ),
            ChoiceChip(
              label: Text('Log (${widget.logLines.length})'),
              selected: _subView == _GpsSubView.log,
              onSelected: (_) => setState(() => _subView = _GpsSubView.log),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Expanded(
          child: switch (_subView) {
            _GpsSubView.map => MarauderMapSection(
              wardriveEntries: widget.wardriveEntries,
              gpsTelemetry: widget.telemetry,
              includeWardrive: false,
              expandMap: true,
            ),
            _GpsSubView.log => _GpsLogPane(logLines: widget.logLines),
          },
        ),
      ],
    );
  }
}

class _GpsLogPane extends StatelessWidget {
  const _GpsLogPane({required this.logLines});

  final List<String> logLines;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
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
            : Scrollbar(
                thumbVisibility: true,
                child: ListView.builder(
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
    );
  }
}

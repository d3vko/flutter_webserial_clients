import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/rf_village_gradient.dart';
import '../../../../core/widgets/capture_map_widget.dart';
import '../../../wardriving/domain/capture_map_points.dart';
import '../../../wardriving/domain/models.dart';
import '../../../wardriving/presentation/widgets/scan_type_theme.dart';
import '../../domain/marauder_map_points.dart';
import '../../domain/marauder_models.dart';

class MarauderMapSection extends StatelessWidget {
  const MarauderMapSection({
    required this.wardriveEntries,
    required this.gpsTelemetry,
    this.includeWardrive = true,
    this.includeGpsFix = true,
    this.expandMap = false,
    super.key,
  });

  final List<WardriveEntry> wardriveEntries;
  final GpsTelemetry gpsTelemetry;
  final bool includeWardrive;
  final bool includeGpsFix;
  final bool expandMap;

  List<CaptureMapPoint> get _points => marauderMapPoints(
    wardriveEntries: wardriveEntries,
    gpsTelemetry: gpsTelemetry,
    includeWardrive: includeWardrive,
    includeGpsFix: includeGpsFix,
  );

  int get _wifiCount =>
      _points.where((p) => p.scanType == ScanType.wifi).length;

  int get _bleCount => _points.where((p) => p.scanType == ScanType.ble).length;

  bool get _hasGpsFix => _points.any((p) => p.isGpsFix);

  @override
  Widget build(BuildContext context) {
    final points = _points;
    final mapWidget = CaptureMapWidget(
      points: points,
      expand: expandMap,
      emptyMessage: includeGpsFix && !includeWardrive
          ? 'No GPS fix yet — run gpsdata or wardrive with GPS'
          : 'No coordinates yet — start wardrive or enable GPS',
    );

    final content = Card(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 4,
            decoration: const BoxDecoration(
              gradient: RfVillageGradient.cardAccent,
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'MAP',
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: AppColors.villageCyan,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                            ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${points.length} points',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const Spacer(),
                      if (includeWardrive && _wifiCount > 0)
                        _LegendChip(
                          color: ScanTypeTheme.forType(ScanType.wifi).accent,
                          label: 'WiFi $_wifiCount',
                        ),
                      if (includeWardrive && _bleCount > 0) ...[
                        const SizedBox(width: 8),
                        _LegendChip(
                          color: ScanTypeTheme.forType(ScanType.ble).accent,
                          label: 'BLE $_bleCount',
                        ),
                      ],
                      if (includeGpsFix && _hasGpsFix) ...[
                        const SizedBox(width: 8),
                        _LegendChip(
                          color: AppColors.villageCyan,
                          label: 'GPS fix',
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 10),
                  Expanded(child: mapWidget),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    if (expandMap) {
      return SizedBox.expand(child: content);
    }

    return content;
  }
}

class _LegendChip extends StatelessWidget {
  const _LegendChip({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.location_on, color: color, size: 16),
        const SizedBox(width: 2),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

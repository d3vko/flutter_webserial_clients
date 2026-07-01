import 'package:flutter/material.dart';

import '../../../../core/config/map_config.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/rf_village_gradient.dart';
import '../../../../core/widgets/capture_map_widget.dart';
import '../../domain/capture_map_points.dart';
import '../../domain/models.dart';
import 'scan_type_theme.dart';

class CaptureMapSection extends StatelessWidget {
  const CaptureMapSection({
    required this.lteRows,
    required this.wifiRows,
    required this.bleRows,
    super.key,
  });

  final List<LteRecord> lteRows;
  final List<WifiRecord> wifiRows;
  final List<BleRecord> bleRows;

  List<CaptureMapPoint> get _points =>
      captureMapPoints(lteRows: lteRows, wifiRows: wifiRows, bleRows: bleRows);

  @override
  Widget build(BuildContext context) {
    final points = _points;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 4,
            decoration: const BoxDecoration(
              gradient: RfVillageGradient.cardAccent,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MAP',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppColors.villageCyan,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
                Text(
                  '${points.length} captured points',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  children: [
                    _LegendChip(
                      color: ScanTypeTheme.forType(ScanType.lte).accent,
                      label: 'LTE (${lteRows.length})',
                    ),
                    _LegendChip(
                      color: ScanTypeTheme.forType(ScanType.wifi).accent,
                      label: 'WiFi (${wifiRows.length})',
                    ),
                    _LegendChip(
                      color: ScanTypeTheme.forType(ScanType.ble).accent,
                      label: 'BLE (${bleRows.length})',
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                CaptureMapWidget(
                  points: points,
                  emptyMessage:
                      'No coordinates yet — connect serial or Load sample',
                ),
                const SizedBox(height: 8),
                Text(
                  '${MapConfig.attribution} · pan/zoom to explore captures',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.villageText.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
        Icon(Icons.location_on, color: color, size: 18),
        const SizedBox(width: 4),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

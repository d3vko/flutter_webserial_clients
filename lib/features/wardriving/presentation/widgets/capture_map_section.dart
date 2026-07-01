import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/layout/app_breakpoints.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/rf_village_gradient.dart';
import '../../domain/capture_map_points.dart';
import '../../domain/models.dart';
import 'scan_type_theme.dart';

class CaptureMapSection extends StatefulWidget {
  const CaptureMapSection({
    required this.lteRows,
    required this.wifiRows,
    required this.bleRows,
    super.key,
  });

  final List<LteRecord> lteRows;
  final List<WifiRecord> wifiRows;
  final List<BleRecord> bleRows;

  @override
  State<CaptureMapSection> createState() => _CaptureMapSectionState();
}

class _CaptureMapSectionState extends State<CaptureMapSection> {
  final _mapController = MapController();
  int _pointCount = 0;

  List<CaptureMapPoint> get _points => captureMapPoints(
    lteRows: widget.lteRows,
    wifiRows: widget.wifiRows,
    bleRows: widget.bleRows,
  );

  @override
  void didUpdateWidget(covariant CaptureMapSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    final count = _points.length;
    if (count != _pointCount) {
      _pointCount = count;
      WidgetsBinding.instance.addPostFrameCallback((_) => _fitToPoints());
    }
  }

  @override
  void initState() {
    super.initState();
    _pointCount = _points.length;
    WidgetsBinding.instance.addPostFrameCallback((_) => _fitToPoints());
  }

  void _fitToPoints() {
    final points = _points;
    if (points.isEmpty || !mounted) return;

    if (points.length == 1) {
      final point = points.first;
      _mapController.move(LatLng(point.latitude, point.longitude), 15);
      return;
    }

    var minLat = points.first.latitude;
    var maxLat = points.first.latitude;
    var minLng = points.first.longitude;
    var maxLng = points.first.longitude;

    for (final point in points.skip(1)) {
      minLat = minLat < point.latitude ? minLat : point.latitude;
      maxLat = maxLat > point.latitude ? maxLat : point.latitude;
      minLng = minLng < point.longitude ? minLng : point.longitude;
      maxLng = maxLng > point.longitude ? maxLng : point.longitude;
    }

    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: LatLngBounds(LatLng(minLat, minLng), LatLng(maxLat, maxLng)),
        padding: const EdgeInsets.all(48),
      ),
    );
  }

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
                      label: 'LTE (${widget.lteRows.length})',
                    ),
                    _LegendChip(
                      color: ScanTypeTheme.forType(ScanType.wifi).accent,
                      label: 'WiFi (${widget.wifiRows.length})',
                    ),
                    _LegendChip(
                      color: ScanTypeTheme.forType(ScanType.ble).accent,
                      label: 'BLE (${widget.bleRows.length})',
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    height: MediaQuery.sizeOf(context).width <
                            AppBreakpoints.medium
                        ? 240
                        : 320,
                    child: Stack(
                      children: [
                        FlutterMap(
                          mapController: _mapController,
                          options: MapOptions(
                            initialCenter: const LatLng(
                              defaultMapLatitude,
                              defaultMapLongitude,
                            ),
                            initialZoom: defaultMapZoom,
                            interactionOptions: const InteractionOptions(
                              flags: InteractiveFlag.all,
                            ),
                          ),
                          children: [
                            TileLayer(
                              urlTemplate:
                                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName:
                                  'dev.rfvillage.lilygo_wardriving_web',
                            ),
                            MarkerLayer(
                              markers: [
                                for (final point in points)
                                  Marker(
                                    point: LatLng(
                                      point.latitude,
                                      point.longitude,
                                    ),
                                    width: 36,
                                    height: 36,
                                    child: Tooltip(
                                      message: point.label,
                                      child: Icon(
                                        Icons.location_on,
                                        color: ScanTypeTheme.forType(
                                          point.scanType,
                                        ).accent,
                                        size: 32,
                                        shadows: const [
                                          Shadow(
                                            color: Colors.black54,
                                            blurRadius: 4,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                        if (points.isEmpty)
                          Container(
                            color: AppColors.villageBlack.withValues(
                              alpha: 0.55,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'No coordinates yet — connect serial or Load sample',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: AppColors.villageText),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'OpenStreetMap tiles · pan/zoom to explore captures',
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

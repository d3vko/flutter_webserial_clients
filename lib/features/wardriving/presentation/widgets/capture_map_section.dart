import 'dart:async';

import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../../../../core/config/map_config.dart';
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
  MapLibreMapController? _mapController;
  var _styleLoaded = false;
  var _pointsSignature = '';

  List<CaptureMapPoint> get _points => captureMapPoints(
    lteRows: widget.lteRows,
    wifiRows: widget.wifiRows,
    bleRows: widget.bleRows,
  );

  String get _currentPointsSignature {
    final points = _points;
    return points
        .map((p) => '${p.latitude},${p.longitude},${p.scanType.name}')
        .join('|');
  }

  @override
  void initState() {
    super.initState();
    _pointsSignature = _currentPointsSignature;
  }

  @override
  void didUpdateWidget(covariant CaptureMapSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    final signature = _currentPointsSignature;
    if (signature == _pointsSignature) return;
    _pointsSignature = signature;
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshMap());
  }

  void _onMapCreated(MapLibreMapController controller) {
    _mapController = controller;
    controller.onCircleTapped.add((circle) {
      final label = circle.data?['label'] as String?;
      if (label == null || !mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(label), duration: const Duration(seconds: 2)),
      );
    });
  }

  void _onStyleLoaded() {
    _styleLoaded = true;
    unawaited(_refreshMap());
  }

  Future<void> _refreshMap() async {
    await _syncCircles();
    await _fitToPoints();
  }

  Future<void> _syncCircles() async {
    final controller = _mapController;
    if (controller == null || !_styleLoaded) return;

    await controller.clearCircles();
    final points = _points;
    if (points.isEmpty) return;

    await controller.addCircles(
      [
        for (final point in points)
          CircleOptions(
            geometry: LatLng(point.latitude, point.longitude),
            circleRadius: 8,
            circleColor: _colorToHex(
              ScanTypeTheme.forType(point.scanType).accent,
            ),
            circleStrokeWidth: 2,
            circleStrokeColor: '#000000',
            circleOpacity: 0.9,
          ),
      ],
      [
        for (final point in points) {'label': point.label},
      ],
    );
  }

  Future<void> _fitToPoints() async {
    final controller = _mapController;
    if (controller == null || !_styleLoaded || !mounted) return;

    final points = _points;
    if (points.isEmpty) return;

    if (points.length == 1) {
      final point = points.first;
      await controller.animateCamera(
        CameraUpdate.newLatLngZoom(LatLng(point.latitude, point.longitude), 15),
      );
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

    await controller.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        left: 48,
        top: 48,
        right: 48,
        bottom: 48,
      ),
    );
  }

  String _colorToHex(Color color) {
    final value = color.toARGB32();
    return '#${(value & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';
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
                    height:
                        MediaQuery.sizeOf(context).width < AppBreakpoints.medium
                        ? 240
                        : 320,
                    child: Stack(
                      children: [
                        MapLibreMap(
                          styleString: MapConfig.styleUrl,
                          initialCameraPosition: CameraPosition(
                            target: LatLng(
                              defaultMapLatitude,
                              defaultMapLongitude,
                            ),
                            zoom: defaultMapZoom,
                          ),
                          onMapCreated: _onMapCreated,
                          onStyleLoadedCallback: _onStyleLoaded,
                          logoEnabled: false,
                          attributionButtonPosition:
                              AttributionButtonPosition.bottomLeft,
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

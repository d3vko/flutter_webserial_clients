import 'dart:async';

import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../config/map_config.dart';
import '../layout/app_breakpoints.dart';
import '../theme/app_colors.dart';
import '../../features/wardriving/domain/capture_map_points.dart';
import '../../features/wardriving/presentation/widgets/scan_type_theme.dart';

class CaptureMapWidget extends StatefulWidget {
  const CaptureMapWidget({
    required this.points,
    this.legend,
    this.emptyMessage = 'No coordinates yet — connect serial or start wardrive',
    this.height,
    this.expand = false,
    super.key,
  });

  final List<CaptureMapPoint> points;
  final Widget? legend;
  final String emptyMessage;
  final double? height;
  final bool expand;

  @override
  State<CaptureMapWidget> createState() => _CaptureMapWidgetState();
}

class _CaptureMapWidgetState extends State<CaptureMapWidget> {
  MapLibreMapController? _mapController;
  var _styleLoaded = false;
  var _pointsSignature = '';

  String get _currentPointsSignature {
    return widget.points
        .map((p) => '${p.latitude},${p.longitude},${p.scanType.name}')
        .join('|');
  }

  @override
  void initState() {
    super.initState();
    _pointsSignature = _currentPointsSignature;
  }

  @override
  void didUpdateWidget(covariant CaptureMapWidget oldWidget) {
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
    final points = widget.points;
    if (points.isEmpty) return;

    await controller.addCircles(
      [
        for (final point in points)
          CircleOptions(
            geometry: LatLng(point.latitude, point.longitude),
            circleRadius: point.isGpsFix ? 12 : 8,
            circleColor: _colorToHex(
              point.color ?? ScanTypeTheme.forType(point.scanType).accent,
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

    final points = widget.points;
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
    final points = widget.points;
    final mapHeight =
        widget.height ??
        (MediaQuery.sizeOf(context).width < AppBreakpoints.medium
            ? 280.0
            : 360.0);

    final mapChild = Stack(
      fit: widget.expand ? StackFit.expand : StackFit.loose,
      children: [
        Positioned.fill(
          child: MapLibreMap(
            styleString: MapConfig.styleUrl,
            initialCameraPosition: CameraPosition(
              target: LatLng(defaultMapLatitude, defaultMapLongitude),
              zoom: defaultMapZoom,
            ),
            onMapCreated: _onMapCreated,
            onStyleLoadedCallback: _onStyleLoaded,
            logoEnabled: false,
            attributionButtonPosition: AttributionButtonPosition.bottomLeft,
          ),
        ),
        if (points.isEmpty)
          Container(
            color: AppColors.villageBlack.withValues(alpha: 0.55),
            alignment: Alignment.center,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                widget.emptyMessage,
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppColors.villageText),
              ),
            ),
          ),
      ],
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: widget.expand
          ? mapChild
          : SizedBox(height: mapHeight, child: mapChild),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:last/features/tracking/models/geofence.dart';
import 'package:last/features/tracking/models/location_record.dart';

/// Abstraction over map providers so flutter_map can be swapped later.
abstract class TrackingMapController {
  void centerOn(double latitude, double longitude, {double? zoom});
  void fitBounds(List<LatLng> points);
}

/// Configuration for [TrackingMapWidget].
class TrackingMapOptions {
  const TrackingMapOptions({
    this.height = 220,
    this.showAccuracyRadius = true,
    this.showHistoryPolyline = false,
    this.interactive = true,
    this.initialZoom = 15,
  });

  final double height;
  final bool showAccuracyRadius;
  final bool showHistoryPolyline;
  final bool interactive;
  final double initialZoom;
}

/// Reusable map widget decoupled from specific screens.
class TrackingMapWidget extends StatefulWidget {
  const TrackingMapWidget({
    super.key,
    required this.location,
    this.history,
    this.geofences,
    this.options = const TrackingMapOptions(),
    this.onControllerReady,
  });

  final LocationRecord? location;
  final List<LocationRecord>? history;
  final List<Geofence>? geofences;
  final TrackingMapOptions options;
  final void Function(TrackingMapController controller)? onControllerReady;

  @override
  State<TrackingMapWidget> createState() => TrackingMapWidgetState();
}

class TrackingMapWidgetState extends State<TrackingMapWidget> implements TrackingMapController {
  final _mapController = MapController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onControllerReady?.call(this);
      _centerIfNeeded();
    });
  }

  @override
  void didUpdateWidget(TrackingMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.location?.latitude != widget.location?.latitude ||
        oldWidget.location?.longitude != widget.location?.longitude) {
      _centerIfNeeded();
    }
  }

  void _centerIfNeeded() {
    final loc = widget.location;
    if (loc != null && loc.hasValidCoordinates) {
      centerOn(loc.latitude, loc.longitude);
    }
  }

  @override
  void centerOn(double latitude, double longitude, {double? zoom}) {
    _mapController.move(LatLng(latitude, longitude), zoom ?? widget.options.initialZoom);
  }

  @override
  void fitBounds(List<LatLng> points) {
    if (points.isEmpty) return;
    final bounds = LatLngBounds.fromPoints(points);
    _mapController.fitCamera(CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(32)));
  }

  void centerOnParolee() {
    final loc = widget.location;
    if (loc != null) centerOn(loc.latitude, loc.longitude);
  }

  @override
  Widget build(BuildContext context) {
    final loc = widget.location;
    final center = loc != null && loc.hasValidCoordinates
        ? LatLng(loc.latitude, loc.longitude)
        : const LatLng(11.2408, 125.0039);

    final historyPoints = widget.history
            ?.where((r) => r.hasValidCoordinates)
            .map((r) => LatLng(r.latitude, r.longitude))
            .toList() ??
        [];

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: widget.options.height,
        child: FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: center,
            initialZoom: widget.options.initialZoom,
            interactionOptions: InteractionOptions(
              flags: widget.options.interactive ? InteractiveFlag.all : InteractiveFlag.none,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.parole.monitoring',
            ),
            if (widget.options.showHistoryPolyline && historyPoints.length >= 2)
              PolylineLayer(
                polylines: [
                  Polyline(points: historyPoints, color: Colors.blue.withValues(alpha: 0.7), strokeWidth: 3),
                ],
              ),
            if (widget.geofences != null)
              CircleLayer(
                circles: widget.geofences!
                    .map((g) => CircleMarker(
                          point: LatLng(g.centerLat, g.centerLng),
                          radius: g.radiusMeters,
                          useRadiusInMeter: true,
                          color: Colors.green.withValues(alpha: 0.15),
                          borderColor: Colors.green,
                          borderStrokeWidth: 1,
                        ))
                    .toList(),
              ),
            if (loc != null && loc.hasValidCoordinates) ...[
              if (widget.options.showAccuracyRadius && loc.accuracy != null && loc.accuracy! > 0)
                CircleLayer(
                  circles: [
                    CircleMarker(
                      point: LatLng(loc.latitude, loc.longitude),
                      radius: loc.accuracy!,
                      useRadiusInMeter: true,
                      color: Colors.blue.withValues(alpha: 0.12),
                      borderColor: Colors.blue.withValues(alpha: 0.3),
                      borderStrokeWidth: 1,
                    ),
                  ],
                ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: LatLng(loc.latitude, loc.longitude),
                    width: 40,
                    height: 40,
                    child: const Icon(Icons.location_on, color: Colors.red, size: 36),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Reusable widget aliases per spec
typedef TrackingMap = TrackingMapWidget;

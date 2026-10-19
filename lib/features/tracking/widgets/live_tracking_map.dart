import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:last/core/theme/app_colors.dart';
import 'package:last/features/tracking/models/geofence.dart';
import 'package:last/features/tracking/models/location_record.dart';

class LiveTrackingMap extends StatefulWidget {
  const LiveTrackingMap({
    super.key,
    this.location,
    this.history = const [],
    this.geofences = const [],
    this.height = 280,
    this.showAccuracyRadius = true,
  });

  final LocationRecord? location;
  final List<LocationRecord> history;
  final List<Geofence> geofences;
  final double height;
  final bool showAccuracyRadius;

  @override
  State<LiveTrackingMap> createState() => LiveTrackingMapState();
}

class LiveTrackingMapState extends State<LiveTrackingMap> {
  final MapController _controller = MapController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void centerOnParolee() {
    final loc = widget.location;
    if (loc == null || !loc.hasValidCoordinates) return;
    _controller.move(LatLng(loc.latitude, loc.longitude), _controller.camera.zoom);
  }

  @override
  void didUpdateWidget(LiveTrackingMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    final loc = widget.location;
    if (loc != null &&
        loc.hasValidCoordinates &&
        (oldWidget.location?.latitude != loc.latitude ||
            oldWidget.location?.longitude != loc.longitude)) {
      _controller.move(LatLng(loc.latitude, loc.longitude), _controller.camera.zoom);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = widget.location;
    final hasLocation = loc != null && loc.hasValidCoordinates;
    final center = hasLocation
        ? LatLng(loc.latitude, loc.longitude)
        : const LatLng(11.240800, 125.003900);

    return SizedBox(
      height: widget.height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: FlutterMap(
          mapController: _controller,
          options: MapOptions(
            initialCenter: center,
            initialZoom: 15,
            interactionOptions: const InteractionOptions(flags: InteractiveFlag.all),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.last',
            ),
            if (widget.history.length > 1)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: widget.history
                        .where((r) => r.hasValidCoordinates)
                        .map((r) => LatLng(r.latitude, r.longitude))
                        .toList(),
                    color: AppColors.officer.withValues(alpha: 0.6),
                    strokeWidth: 3,
                  ),
                ],
              ),
            if (widget.geofences.isNotEmpty)
              CircleLayer(
                circles: widget.geofences
                    .where((g) => g.isActive)
                    .map(
                      (g) => CircleMarker(
                        point: LatLng(g.centerLat, g.centerLng),
                        radius: g.radiusMeters,
                        useRadiusInMeter: true,
                        color: AppColors.success.withValues(alpha: 0.08),
                        borderColor: AppColors.success.withValues(alpha: 0.5),
                        borderStrokeWidth: 2,
                      ),
                    )
                    .toList(),
              ),
            if (hasLocation && widget.showAccuracyRadius && loc.accuracy != null)
              CircleLayer(
                circles: [
                  CircleMarker(
                    point: center,
                    radius: loc.accuracy!,
                    useRadiusInMeter: true,
                    color: AppColors.officer.withValues(alpha: 0.15),
                    borderColor: AppColors.officer.withValues(alpha: 0.4),
                    borderStrokeWidth: 1,
                  ),
                ],
              ),
            if (hasLocation)
              MarkerLayer(
                markers: [
                  Marker(
                    point: center,
                    width: 40,
                    height: 40,
                    child: const Icon(Icons.location_on, color: AppColors.officer, size: 36),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

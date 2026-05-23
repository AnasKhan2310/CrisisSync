import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:crisisync/config/theme.dart';
import 'package:crisisync/services/crisis_provider.dart';
import 'package:crisisync/models/crisis_models.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with SingleTickerProviderStateMixin {
  GoogleMapController? _mapController;
  late AnimationController _vehicleAnimationController;
  
  // Default coordinates (Islamabad Center)
  static const LatLng _defaultCenter = LatLng(33.6844, 73.0479);
  
  LatLng _incidentLatLng = _defaultCenter;
  double _vehicleAngle = 0.0;

  @override
  void initState() {
    super.initState();
    _vehicleAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..addListener(() {
        setState(() {
          _vehicleAngle = _vehicleAnimationController.value * 2 * pi;
        });
      })..repeat();
  }

  @override
  void dispose() {
    _vehicleAnimationController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  LatLng _getIncidentCoordinates(Incident? incident) {
    if (incident == null) return _defaultCenter;
    
    // Check if any zone has coordinates
    for (var zone in incident.affectedZones) {
      if (zone.coordinates != null && zone.coordinates!.length == 2) {
        return LatLng(zone.coordinates![0], zone.coordinates![1]);
      }
    }

    // Default heuristics based on location text
    final loc = incident.location.toLowerCase();
    if (loc.contains("g-10")) {
      return const LatLng(33.6823, 73.0135);
    } else if (loc.contains("saddar")) {
      return const LatLng(33.5973, 73.0479);
    } else if (loc.contains("george town")) {
      return const LatLng(33.7294, 73.0931);
    } else if (loc.contains("kashmir highway") || loc.contains("highway")) {
      return const LatLng(33.6644, 73.0031);
    }
    return _defaultCenter;
  }

  void _animateToLocation(LatLng target) {
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: target, zoom: 14.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<CrisisProvider>(context);
    final activeInc = provider.activeIncident;
    final overlays = provider.mapOverlays;

    final blockedRoads = List<String>.from(overlays['blocked_roads'] ?? []);
    final alternateRoutes = List<String>.from(overlays['alternate_routes'] ?? []);
    final hasActive = activeInc != null;

    final targetCoords = _getIncidentCoordinates(activeInc);
    if (targetCoords != _incidentLatLng) {
      _incidentLatLng = targetCoords;
      // Animate map controller to new coordinates
      _animateToLocation(_incidentLatLng);
    }

    // 1. Build Markers
    final Set<Marker> markers = {};
    if (hasActive) {
      // Hotspot Marker
      markers.add(
        Marker(
          markerId: const MarkerId("hotspot"),
          position: _incidentLatLng,
          infoWindow: InfoWindow(
            title: activeInc.title,
            snippet: "Severity: ${activeInc.severity}",
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );

      // Affected zone sub-markers
      for (int i = 0; i < activeInc.affectedZones.length; i++) {
        final zone = activeInc.affectedZones[i];
        if (zone.coordinates != null && zone.coordinates!.length == 2) {
          markers.add(
            Marker(
              markerId: MarkerId("zone_$i"),
              position: LatLng(zone.coordinates![0], zone.coordinates![1]),
              infoWindow: InfoWindow(title: zone.name, snippet: "Zone Severity: ${zone.severity}"),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                zone.severity == "HIGH" ? BitmapDescriptor.hueOrange : BitmapDescriptor.hueYellow,
              ),
            ),
          );
        }
      }

      // Dynamic Responder Vehicle Marker (moving in a small circle around incident center)
      final double offsetRadius = 0.0025; // Latitude degree offset
      final vehicleLatLng = LatLng(
        _incidentLatLng.latitude + (offsetRadius * cos(_vehicleAngle)),
        _incidentLatLng.longitude + (offsetRadius * sin(_vehicleAngle)),
      );
      markers.add(
        Marker(
          markerId: const MarkerId("responder_vehicle"),
          position: vehicleLatLng,
          infoWindow: const InfoWindow(title: "Rescue 1122 Unit 3", snippet: "Status: En route (ETA 9m)"),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        ),
      );
    }

    // 2. Build Circles (Flood Zones or Heatwave Areas)
    final Set<Circle> circles = {};
    if (hasActive) {
      circles.add(
        Circle(
          circleId: const CircleId("crisis_area"),
          center: _incidentLatLng,
          radius: activeInc.type == "urban_flooding" ? 600 : 900,
          fillColor: activeInc.type == "urban_flooding" 
              ? Colors.blue.withOpacity(0.15) 
              : Colors.orange.withOpacity(0.12),
          strokeColor: activeInc.type == "urban_flooding" ? Colors.blue : Colors.orange,
          strokeWidth: 2,
        ),
      );
    }

    // 3. Build Polylines (Blocked Lanes in Red, Detours in Green)
    final Set<Polyline> polylines = {};
    if (hasActive) {
      if (blockedRoads.isNotEmpty) {
        // Red line showing blocked route
        polylines.add(
          Polyline(
            polylineId: const PolylineId("blocked_road"),
            color: AppTheme.alertRed,
            width: 6,
            points: [
              _incidentLatLng,
              LatLng(_incidentLatLng.latitude + 0.003, _incidentLatLng.longitude + 0.003),
            ],
          ),
        );
      }
      
      if (alternateRoutes.isNotEmpty) {
        // Green line showing detour
        polylines.add(
          Polyline(
            polylineId: const PolylineId("detour_route"),
            color: Colors.green,
            width: 5,
            patterns: [PatternItem.dash(12), PatternItem.gap(8)],
            points: [
              LatLng(_incidentLatLng.latitude, _incidentLatLng.longitude - 0.002),
              LatLng(_incidentLatLng.latitude - 0.004, _incidentLatLng.longitude - 0.002),
              LatLng(_incidentLatLng.latitude - 0.004, _incidentLatLng.longitude + 0.004),
              LatLng(_incidentLatLng.latitude + 0.003, _incidentLatLng.longitude + 0.003),
            ],
          ),
        );
      }
    }

    return Scaffold(
      body: Stack(
        children: [
          // Google Map Widget
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _incidentLatLng,
              zoom: hasActive ? 14.5 : 12.0,
            ),
            mapType: MapType.normal,
            markers: markers,
            circles: circles,
            polylines: polylines,
            zoomControlsEnabled: true,
            myLocationButtonEnabled: false,
            onMapCreated: (GoogleMapController controller) {
              _mapController = controller;
              if (hasActive) {
                _animateToLocation(_incidentLatLng);
              }
            },
          ),

          // Top Info Card Overlay
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: AppTheme.glassCardDecoration(color: Colors.white, opacity: 0.95),
              child: Row(
                children: [
                  const Icon(Icons.my_location_rounded, color: AppTheme.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      hasActive
                          ? "Active Zone: ${activeInc.location} (${activeInc.type.toUpperCase().replaceAll('_', ' ')})"
                          : "Grid Status: NORMAL (Monitoring active)",
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: hasActive ? AppTheme.alertRed : Colors.green,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Left Legend Overlay
          Positioned(
            bottom: 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: AppTheme.glassCardDecoration(color: const Color(0xFF1E2627), opacity: 0.95),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildLegendRow("Blocked Arteries", AppTheme.alertRed, isLine: true),
                  const SizedBox(height: 6),
                  _buildLegendRow("Diverted Detours", Colors.green, isLine: true, isDashed: true),
                  const SizedBox(height: 6),
                  _buildLegendRow("Incident Hotspot", Colors.red, isMarker: true),
                  const SizedBox(height: 6),
                  _buildLegendRow("Rescue Unit Mobile", Colors.blue, isMarker: true),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendRow(String label, Color color,
      {bool isLine = false, bool isDashed = false, bool isMarker = false}) {
    Widget graphic;
    if (isLine) {
      graphic = SizedBox(
        width: 24,
        child: Row(
          children: List.generate(
            isDashed ? 3 : 1,
            (index) => Expanded(
              child: Container(
                height: 3,
                margin: const EdgeInsets.symmetric(horizontal: 1),
                color: color,
              ),
            ),
          ),
        ),
      );
    } else if (isMarker) {
      graphic = Icon(Icons.location_on_rounded, color: color, size: 16);
    } else {
      graphic = Container(width: 12, height: 12, color: color);
    }

    return Row(
      children: [
        graphic,
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 11, fontFamily: 'monospace'),
        ),
      ],
    );
  }
}

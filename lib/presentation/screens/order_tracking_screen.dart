import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/config/philippine_regions.dart';

/// Live tracking screen that displays a map with the driver's moving position.
/// Shows a route polyline, pickup/dropoff markers, and a delivery progress card.
class OrderTrackingScreen extends StatefulWidget {
  final String? region;
  final int orderIndex;

  const OrderTrackingScreen({super.key, this.region, this.orderIndex = 0});

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  final MapController _mapController = MapController();
  Timer? _movementTimer;
  double _progress = 0.0;
  List<LatLng> _routePoints = [];

  late LatLng _pickup;
  late LatLng _dropoff;
  late LatLng _driverPosition;
  String _pickupName = '';
  String _dropoffName = '';

  late PhilippineRegion _currentRegion;

  @override
  void initState() {
    super.initState();
    _currentRegion =
        PhilippineRegions.getRegionByCode(widget.region ?? 'Region 7') ??
        PhilippineRegions.region7;

    if (widget.orderIndex == 0) {
      // Red order
      _pickupName = 'IT Park, Cebu City';
      _dropoffName = 'Tipolo National High School';
      _pickup = const LatLng(10.3300, 123.9060);
      _dropoff = const LatLng(10.3280, 123.9280);
    } else if (widget.orderIndex == 1) {
      // Green order
      _pickupName = 'Parkmall, Mandaue City';
      _dropoffName = 'Tipolo National High School';
      _pickup = const LatLng(10.3250, 123.9350);
      _dropoff = const LatLng(10.3280, 123.9280);
    } else if (widget.orderIndex == 2) {
      // Orange order
      _pickupName = 'SM City Cebu';
      _dropoffName = 'Tipolo National High School';
      _pickup = const LatLng(10.3117, 123.9183);
      _dropoff = const LatLng(10.3280, 123.9280);
    } else {
      // Dynamically added admin test order
      _pickupName = 'Trace EM Hub, Mandaue';
      _dropoffName = 'Your Location (Fetching...)';
      _pickup = const LatLng(10.3323, 123.9400); // Warehouse
      _dropoff = const LatLng(10.3150, 123.8900); // Generic home default
      _fetchUserAddress();
    }
    _driverPosition = _pickup;

    _fetchRoute();
    _startDriverMovement();
  }

  /// Fetches the current user's saved address from Firestore to use as the dropoff label.
  /// Only used for dynamically-created admin test orders (orderIndex >= 3).
  Future<void> _fetchUserAddress() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (doc.exists && doc.data()!.containsKey('address')) {
          if (mounted) {
            setState(() {
              _dropoffName = doc['address'];
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching user address: $e');
    }
  }

  /// Fetches the driving route between pickup and dropoff using the OSRM routing API.
  /// Falls back to a secondary OSRM server if the primary is unavailable.
  Future<void> _fetchRoute() async {
    try {
      final coords =
          '${_pickup.longitude},${_pickup.latitude};${_dropoff.longitude},${_dropoff.latitude}';
      final headers = {'User-Agent': 'TraceEmApp/1.0 (contact@traceem.app)'};

      var url =
          'https://router.project-osrm.org/route/v1/driving/$coords?overview=full&geometries=geojson';
      http.Response? response;

      try {
        response = await http.get(Uri.parse(url), headers: headers);
      } catch (e) {
        debugPrint('Primary OSRM failed: $e');
        response = null;
      }

      if (response == null || response.statusCode != 200) {
        url =
            'https://routing.openstreetmap.de/routed-car/route/v1/driving/$coords?overview=full&geometries=geojson';
        response = await http.get(Uri.parse(url), headers: headers);
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final routes = data['routes'] as List?;
        if (routes != null && routes.isNotEmpty) {
          final geometry = routes[0]['geometry'];
          final coordinates = geometry['coordinates'] as List;

          final points = coordinates.map((coord) {
            return LatLng(
              (coord[1] as num).toDouble(),
              (coord[0] as num).toDouble(),
            );
          }).toList();

          if (mounted) {
            setState(() {
              _routePoints = points;
              // Add driver position to slightly offset the center later if needed
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching route for tracking: $e');
    }
  }

  @override
  void dispose() {
    _movementTimer?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  /// Starts a periodic timer to simulate or fetch the driver's movement every 3 seconds.
  /// For orderIndex 0, fetches real position from the FastAPI server.
  /// For other orders, simulates movement along the route.
  void _startDriverMovement() {
    _movementTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (!mounted) return;

      if (widget.orderIndex == 0) {
        try {
          final String baseUrl = kIsWeb
              ? 'http://localhost:8000'
              : 'http://10.0.2.2:8000';

          final response = await http.get(
            Uri.parse('$baseUrl/history/user_123'),
          );

          if (response.statusCode == 200) {
            final List<dynamic> history = jsonDecode(response.body);
            if (history.isNotEmpty) {
              final latest = history.last;
              setState(() {
                _driverPosition = LatLng(
                  latest['latitude'],
                  latest['longitude'],
                );
                double totalDist = _calculateDistance(_pickup, _dropoff);
                double distLeft = _calculateDistance(_driverPosition, _dropoff);
                _progress = (1.0 - (distLeft / totalDist)).clamp(0.0, 1.0);
              });
            }
          }
        } catch (e) {
          debugPrint('Error fetching tracking data: $e');
        }
      } else {
        setState(() {
          if (_progress < 1.0) {
            _progress += 0.015; // move slower so they can watch it arrive
          }
          if (_progress >= 1.0) {
            _progress = 1.0; // park it at the drop-off
            _movementTimer?.cancel();
          }

          if (_routePoints.isNotEmpty) {
            final idx = (_progress * (_routePoints.length - 1)).round();
            _driverPosition = _routePoints[idx];
          } else {
            // Straight line fallback
            _driverPosition = LatLng(
              _pickup.latitude +
                  (_dropoff.latitude - _pickup.latitude) * _progress,
              _pickup.longitude +
                  (_dropoff.longitude - _pickup.longitude) * _progress,
            );
          }
        });
      }
    });
  }

  /// Simple helper to calculate approximate distance between two [LatLng] points
  /// using the Manhattan/taxicab distance of their coordinate differences.
  double _calculateDistance(LatLng p1, LatLng p2) {
    return (p1.latitude - p2.latitude).abs() +
        (p1.longitude - p2.longitude).abs();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Tracking - Region 7'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: LatLng(
                _currentRegion.centerLat,
                _currentRegion.centerLng,
              ),
              initialZoom: 12.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.traceem.app',
              ),
              if (_routePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routePoints,
                      color: const Color(0xFF4C8CFF),
                      strokeWidth: 5,
                    ),
                  ],
                )
              else
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: [_pickup, _driverPosition, _dropoff],
                      color: Colors.blue.withOpacity(0.5),
                      strokeWidth: 5,
                    ),
                  ],
                ),
              MarkerLayer(
                markers: [
                  // Pickup
                  Marker(
                    point: _pickup,
                    width: 44,
                    height: 44,
                    child: const Icon(
                      Icons.location_on,
                      color: Colors.green,
                      size: 40,
                    ),
                  ),
                  // Drop-off
                  Marker(
                    point: _dropoff,
                    width: 44,
                    height: 44,
                    child: const Icon(
                      Icons.location_on,
                      color: Colors.red,
                      size: 40,
                    ),
                  ),
                  // Driver
                  Marker(
                    point: _driverPosition,
                    width: 44,
                    height: 44,
                    child: const Icon(
                      Icons.local_shipping,
                      color: Color(0xFF4C8CFF),
                      size: 38,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.delivery_dining,
                          color: Color(0xFF4C8CFF),
                          size: 30,
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Driver is moving...',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              'Estimated arrival: ${12 - (12 * _progress).toInt()} mins',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        CircularProgressIndicator(
                          value: _progress,
                          strokeWidth: 5,
                          backgroundColor: Colors.grey[200],
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(
                        Icons.location_on,
                        color: Colors.green,
                      ),
                      title: Text(
                        _pickupName,
                        style: const TextStyle(fontSize: 14),
                      ),
                      dense: true,
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.location_on, color: Colors.red),
                      title: Text(
                        _dropoffName,
                        style: const TextStyle(fontSize: 14),
                      ),
                      dense: true,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

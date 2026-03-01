import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../../core/config/philippine_regions.dart';

class OrderTrackingScreen extends StatefulWidget {
  final String? region;

  const OrderTrackingScreen({super.key, this.region});

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  final MapController _mapController = MapController();
  Timer? _movementTimer;
  double _progress = 0.0;

  late PhilippineRegion _currentRegion;

  // Region 7 Simulation: IT Park to Parkmall
  static const LatLng _itPark = LatLng(10.3300, 123.9060);
  static const LatLng _parkmall = LatLng(10.3250, 123.9350);

  LatLng _driverPosition = _itPark;

  @override
  void initState() {
    super.initState();
    _currentRegion =
        PhilippineRegions.getRegionByCode(widget.region ?? 'Region 7') ??
        PhilippineRegions.region7;
    _startDriverMovement();
  }

  @override
  void dispose() {
    _movementTimer?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  void _startDriverMovement() {
    _movementTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (!mounted) return;

      try {
        final String baseUrl = kIsWeb
            ? 'http://localhost:8000'
            : 'http://10.0.2.2:8000';

        final response = await http.get(Uri.parse('$baseUrl/history/user_123'));

        if (response.statusCode == 200) {
          final List<dynamic> history = jsonDecode(response.body);
          if (history.isNotEmpty) {
            final latest = history.last;
            setState(() {
              _driverPosition = LatLng(latest['latitude'], latest['longitude']);
              double totalDist = _calculateDistance(_itPark, _parkmall);
              double distLeft = _calculateDistance(_driverPosition, _parkmall);
              _progress = (1.0 - (distLeft / totalDist)).clamp(0.0, 1.0);
            });
          }
        }
      } catch (e) {
        debugPrint('Error fetching tracking data: $e');
      }
    });
  }

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
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: [_itPark, _driverPosition, _parkmall],
                    color: Colors.blue.withOpacity(0.5),
                    strokeWidth: 5,
                  ),
                ],
              ),
              MarkerLayer(
                markers: [
                  // Pickup
                  Marker(
                    point: _itPark,
                    width: 40,
                    height: 40,
                    child: const Icon(
                      Icons.location_on,
                      color: Colors.green,
                      size: 36,
                    ),
                  ),
                  // Drop-off
                  Marker(
                    point: _parkmall,
                    width: 40,
                    height: 40,
                    child: const Icon(Icons.flag, color: Colors.red, size: 36),
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
                    const ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.location_on, color: Colors.green),
                      title: Text(
                        'IT Park, Cebu City',
                        style: TextStyle(fontSize: 14),
                      ),
                      dense: true,
                    ),
                    const ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.flag, color: Colors.red),
                      title: Text(
                        'Parkmall, Mandaue City',
                        style: TextStyle(fontSize: 14),
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

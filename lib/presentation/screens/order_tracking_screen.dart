import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../../core/config/philippine_regions.dart';

class OrderTrackingScreen extends StatefulWidget {
  final String? region; // Optional region parameter

  const OrderTrackingScreen({super.key, this.region});

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  final Completer<GoogleMapController> _controller = Completer();
  Timer? _movementTimer;
  double _progress = 0.0;

  late PhilippineRegion _currentRegion;
  late CameraPosition _initialPosition;

  // Region 7 Simulation: IT Park to Parkmall
  static const LatLng _itPark = LatLng(10.3300, 123.9060);
  static const LatLng _parkmall = LatLng(10.3250, 123.9350);

  LatLng _driverPosition = _itPark;

  @override
  void initState() {
    super.initState();

    // Initialize region (default to Region 7 if not specified)
    _currentRegion =
        PhilippineRegions.getRegionByCode(widget.region ?? 'Region 7') ??
        PhilippineRegions.region7;

    // Set initial camera position based on region
    _initialPosition = CameraPosition(
      target: LatLng(_currentRegion.centerLat, _currentRegion.centerLng),
      zoom: 12.0,
    );

    _startDriverMovement();
  }

  @override
  void dispose() {
    _movementTimer?.cancel();
    super.dispose();
  }

  void _startDriverMovement() {
    // Polls the backend every 3 seconds for the latest location
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

              // Calculate progress based on distance to destination
              // For demonstration, we'll still use a simple calculation
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
    // Very simplified distance calculation
    return (p1.latitude - p2.latitude).abs() +
        (p1.longitude - p2.longitude).abs();
  }

  Set<Marker> get _markers {
    return {
      Marker(
        markerId: const MarkerId('it_park'),
        position: _itPark,
        infoWindow: const InfoWindow(title: 'Pickup: IT Park'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      ),
      Marker(
        markerId: const MarkerId('parkmall'),
        position: _parkmall,
        infoWindow: const InfoWindow(title: 'Drop-off: Parkmall'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ),
      Marker(
        markerId: const MarkerId('driver'),
        position: _driverPosition,
        rotation: 90, // Simple rotation adjustment
        infoWindow: InfoWindow(
          title: 'Driver',
          snippet: '${(_progress * 100).toInt()}% of the way',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      ),
    };
  }

  Set<Polyline> get _polylines {
    return {
      Polyline(
        polylineId: const PolylineId('route1'),
        points: [_itPark, _parkmall],
        color: Colors.blue.withOpacity(0.5),
        width: 5,
      ),
    };
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
          GoogleMap(
            mapType: MapType.normal,
            initialCameraPosition: _initialPosition,
            markers: _markers,
            polylines: _polylines,
            onMapCreated: (GoogleMapController controller) {
              _controller.complete(controller);
            },
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

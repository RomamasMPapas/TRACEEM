import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../core/config/philippine_regions.dart';

class BookingScreen extends StatefulWidget {
  final String region;
  const BookingScreen({super.key, required this.region});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  late CameraPosition _initialPosition;

  // Simulation: IT Park to Parkmall
  static const LatLng _itPark = LatLng(10.3300, 123.9060);
  static const LatLng _parkmall = LatLng(10.3250, 123.9350);

  @override
  void initState() {
    super.initState();
    final region =
        PhilippineRegions.getRegionByCode(widget.region) ??
        PhilippineRegions.region7;
    _initialPosition = CameraPosition(
      target: LatLng(region.centerLat, region.centerLng),
      zoom: 13.5,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Blue Header
            Container(
              color: const Color(0xFF4C8CFF),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildHeaderIcon(Icons.notifications, hasBadge: true),
                  const SizedBox(
                    width: 44,
                  ), // Placeholder to keep layout balanced
                ],
              ),
            ),

            // From/To Inputs
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    _buildInputBox("FROM:"),
                    const SizedBox(height: 5),
                    _buildInputBox("TO:"),
                    const SizedBox(height: 10),

                    // Map Area
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: GoogleMap(
                          initialCameraPosition: _initialPosition,
                          markers: {
                            const Marker(
                              markerId: MarkerId('start'),
                              position: _itPark,
                            ),
                            const Marker(
                              markerId: MarkerId('end'),
                              position: _parkmall,
                              icon: BitmapDescriptor.defaultMarker,
                            ),
                          },
                          polylines: {
                            Polyline(
                              polylineId: const PolylineId('route'),
                              points: const [_itPark, _parkmall],
                              color: Colors.blue.shade900,
                              width: 6,
                            ),
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Vehicle Type & Total
                    _buildVehicleBox(),
                    const SizedBox(height: 15),
                    _buildTotalBox(),
                    const SizedBox(height: 15),

                    // Play Button
                    Container(
                      width: 60,
                      height: 60,
                      decoration: const BoxDecoration(
                        color: Color(0xFF2DFF81),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 10,
                            offset: Offset(0, 5),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.play_arrow,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Blue Footer
            Container(
              color: const Color(0xFF4C8CFF),
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new,
                      color: Colors.red,
                      weight: 900,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Expanded(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'TRACE EM',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                            ),
                          ),
                          Icon(
                            Icons.local_shipping,
                            color: Colors.white,
                            size: 30,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 48), // Spacer to balance back button
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderIcon(IconData icon, {bool hasBadge = false}) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5)],
      ),
      child: Stack(
        children: [
          Icon(icon, color: Colors.black, size: 28),
          if (hasBadge)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInputBox(String label) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const Expanded(child: SizedBox()),
          const Icon(Icons.search, size: 18, color: Colors.grey),
        ],
      ),
    );
  }

  Widget _buildVehicleBox() {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.black),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 5, offset: Offset(2, 2)),
        ],
      ),
      child: const Center(
        child: Text(
          '(VEHICLE TYPE)',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildTotalBox() {
    return Container(
      width: double.infinity,
      height: 35,
      decoration: BoxDecoration(border: Border.all(color: Colors.black)),
      child: const Center(
        child: Text(
          'TOTAL AMOUNT',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
        ),
      ),
    );
  }
}

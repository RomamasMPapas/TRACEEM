import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';
import '../../../core/config/philippine_regions.dart';

class BookView extends StatefulWidget {
  final String? detectedRegion;

  const BookView({super.key, this.detectedRegion});

  @override
  State<BookView> createState() => _BookViewState();
}

class _BookViewState extends State<BookView> {
  final Completer<GoogleMapController> _controller = Completer();
  late CameraPosition _initialPosition;
  bool _isBookingMode = false;

  @override
  void initState() {
    super.initState();
    _setInitialPosition();
  }

  void _setInitialPosition() {
    // Get region configuration based on detected region
    final region =
        PhilippineRegions.getRegionByCode(
          widget.detectedRegion ?? 'Region 7',
        ) ??
        PhilippineRegions.region7;

    _initialPosition = CameraPosition(
      target: LatLng(region.centerLat, region.centerLng),
      zoom: 12.0,
    );
  }

  @override
  void didUpdateWidget(BookView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update map position if region changes
    if (oldWidget.detectedRegion != widget.detectedRegion) {
      _setInitialPosition();
      if (!kIsWeb) {
        _updateMapPosition();
      }
    }
  }

  Future<void> _updateMapPosition() async {
    final controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newCameraPosition(_initialPosition));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white, // Background behind the shrunk map
      child: Stack(
        children: [
          // Shrunk Map with Animation
          AnimatedPadding(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
            padding: _isBookingMode
                ? const EdgeInsets.only(
                    top: 130,
                    bottom: 160,
                    left: 20,
                    right: 20,
                  )
                : EdgeInsets.zero,
            child: Container(
              decoration: _isBookingMode
                  ? BoxDecoration(
                      border: Border.all(
                        color: Colors.grey.shade300,
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(5),
                    )
                  : null,
              child: ClipRRect(
                borderRadius: _isBookingMode
                    ? BorderRadius.circular(5)
                    : BorderRadius.zero,
                child: kIsWeb ? _buildWebMapPlaceholder() : _buildGoogleMap(),
              ),
            ),
          ),

          // Search Bars (Visible in Booking Mode)
          if (_isBookingMode)
            Positioned(
              top: 20,
              left: 20,
              right: 20,
              child: Column(
                children: [
                  _buildSearchInput("FROM:"),
                  const SizedBox(height: 10),
                  _buildSearchInput("TO:"),
                ],
              ),
            ),

          // Region indicator badge (Only in normal mode)
          if (!_isBookingMode)
            Positioned(
              top: 16,
              left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.location_on, color: Colors.red, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      widget.detectedRegion ?? 'Region 7',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Floating action button Area
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Center(
              child: _isBookingMode ? _buildVehicleButton() : _buildVanButton(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchInput(String label) {
    return Container(
      height: 45,
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
              fontSize: 12,
            ),
          ),
          const Expanded(child: SizedBox()),
          const Icon(Icons.search, size: 18, color: Colors.grey),
        ],
      ),
    );
  }

  Widget _buildVanButton() {
    return GestureDetector(
      onTap: () => setState(() => _isBookingMode = true),
      child: Container(
        width: 75,
        height: 75,
        decoration: BoxDecoration(
          color: const Color(0xFF4C8CFF),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.black, width: 2),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(Icons.local_shipping, color: Colors.white, size: 45),
      ),
    );
  }

  Widget _buildVehicleButton() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Vehicle Selection Box
        GestureDetector(
          onTap: () => setState(() => _isBookingMode = false),
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.black, width: 1.5),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 5,
                  offset: Offset(2, 2),
                ),
              ],
            ),
            child: const Center(
              child: Text(
                '(VEHICLE TYPE)',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
        const SizedBox(height: 15),
      ],
    );
  }

  Widget _buildGoogleMap() {
    return GoogleMap(
      initialCameraPosition: _initialPosition,
      onMapCreated: (GoogleMapController controller) {
        _controller.complete(controller);
      },
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
      markers: {
        Marker(
          markerId: const MarkerId('region_center'),
          position: LatLng(
            _initialPosition.target.latitude,
            _initialPosition.target.longitude,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(
            title: widget.detectedRegion ?? 'Region 7',
            snippet: 'Your current region',
          ),
        ),
      },
    );
  }

  Widget _buildWebMapPlaceholder() {
    final region =
        PhilippineRegions.getRegionByCode(
          widget.detectedRegion ?? 'Region 7',
        ) ??
        PhilippineRegions.region7;

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.blue.shade100, Colors.blue.shade300],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.map, size: 80, color: Colors.blue.shade700),
            const SizedBox(height: 16),
            Text(
              region.name,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${region.code} - ${region.capital}',
              style: TextStyle(fontSize: 16, color: Colors.blue.shade700),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.symmetric(horizontal: 32),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Google Maps will display here on mobile devices.\nFor web, please configure your Google Maps API key.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

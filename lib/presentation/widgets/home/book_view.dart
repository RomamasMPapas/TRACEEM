import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import '../../../core/config/philippine_regions.dart';

class BookView extends StatefulWidget {
  final String? detectedRegion;

  const BookView({super.key, this.detectedRegion});

  @override
  State<BookView> createState() => _BookViewState();
}

class _BookViewState extends State<BookView> {
  late LatLng _initialCenter;
  LatLng? _fromLatLng; // pin location from FROM address
  LatLng? _toLatLng; // pin location from TO address
  bool _isBookingMode = false;
  bool _isGeocoding = false;
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _setInitialPosition();
  }

  void _setInitialPosition() {
    final region =
        PhilippineRegions.getRegionByCode(
          widget.detectedRegion ?? 'Region 7',
        ) ??
        PhilippineRegions.region7;
    _initialCenter = LatLng(region.centerLat, region.centerLng);
  }

  @override
  void didUpdateWidget(BookView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.detectedRegion != widget.detectedRegion) {
      setState(() => _setInitialPosition());
    }
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
                child: _buildOSMMap(),
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
                  _buildSearchInput("FROM:", _fromController),
                  const SizedBox(height: 10),
                  _buildSearchInput("TO:", _toController),
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

  final TextEditingController _fromController = TextEditingController();
  final TextEditingController _toController = TextEditingController();

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  /// Geocode a place name using Nominatim (free, no key needed)
  Future<LatLng?> _geocode(String query) async {
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/search'
        '?q=${Uri.encodeComponent(query)}, Philippines'
        '&format=json&limit=1',
      );
      final response = await http.get(
        uri,
        headers: {'User-Agent': 'TraceEmApp/1.0 (contact@traceem.app)'},
      );
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        if (data.isNotEmpty) {
          return LatLng(
            double.parse(data[0]['lat']),
            double.parse(data[0]['lon']),
          );
        }
      }
    } catch (e) {
      debugPrint('Geocode error: $e');
    }
    return null;
  }

  void _showAddressBottomSheet(String label, TextEditingController controller) {
    final tempController = TextEditingController(text: controller.text);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                label == 'FROM:'
                    ? 'Enter Pick-up Location'
                    : 'Enter Destination',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: tempController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: label == 'FROM:'
                      ? 'e.g. IT Park, Lahug, Cebu City'
                      : 'e.g. Parkmall, Mandaue City',
                  prefixIcon: Icon(
                    label == 'FROM:' ? Icons.my_location : Icons.location_on,
                    color: const Color(0xFF4C8CFF),
                  ),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () => tempController.clear(),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
                onSubmitted: (val) {
                  setState(() => controller.text = val);
                  Navigator.pop(ctx);
                },
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4C8CFF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () async {
                    final address = tempController.text.trim();
                    controller.text = address;
                    Navigator.pop(ctx);
                    if (address.isEmpty) return;
                    setState(() => _isGeocoding = true);
                    final coords = await _geocode(address);
                    if (mounted) {
                      setState(() {
                        _isGeocoding = false;
                        if (coords != null) {
                          if (label == 'FROM:') {
                            _fromLatLng = coords;
                          } else {
                            _toLatLng = coords;
                          }
                          // Animate map to the FROM pin
                          final target = label == 'FROM:'
                              ? coords
                              : (_fromLatLng ?? coords);
                          _mapController.move(target, 14.0);
                        }
                      });
                    }
                  },
                  child: const Text(
                    'Confirm',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchInput(String label, TextEditingController controller) {
    return GestureDetector(
      onTap: () => _showAddressBottomSheet(label, controller),
      child: Container(
        height: 45,
        padding: const EdgeInsets.symmetric(horizontal: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              label == 'FROM:' ? Icons.my_location : Icons.location_on,
              color: const Color(0xFF4C8CFF),
              size: 18,
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
                fontSize: 11,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                controller.text.isEmpty ? 'Tap to search...' : controller.text,
                style: TextStyle(
                  color: controller.text.isEmpty
                      ? Colors.grey.shade400
                      : Colors.black87,
                  fontSize: 13,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            const Icon(Icons.search, size: 18, color: Color(0xFF4C8CFF)),
          ],
        ),
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

  Widget _buildOSMMap() {
    // Build marker list: FROM pin (red) + TO pin (blue)
    final markers = <Marker>[
      if (_fromLatLng != null)
        Marker(
          point: _fromLatLng!,
          width: 44,
          height: 44,
          child: const Icon(Icons.location_on, color: Colors.red, size: 40),
        ),
      if (_toLatLng != null)
        Marker(
          point: _toLatLng!,
          width: 44,
          height: 44,
          child: const Icon(Icons.flag, color: Color(0xFF4C8CFF), size: 36),
        ),
      // Default center pin when nothing is set yet
      if (_fromLatLng == null && _toLatLng == null)
        Marker(
          point: _initialCenter,
          width: 44,
          height: 44,
          child: const Icon(Icons.location_on, color: Colors.grey, size: 40),
        ),
    ];

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(initialCenter: _initialCenter, initialZoom: 12.0),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.traceem.app',
            ),
            if (_fromLatLng != null && _toLatLng != null)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: [_fromLatLng!, _toLatLng!],
                    color: const Color(0xFF4C8CFF),
                    strokeWidth: 4,
                  ),
                ],
              ),
            MarkerLayer(markers: markers),
          ],
        ),
        // Loading indicator while geocoding
        if (_isGeocoding)
          Positioned.fill(
            child: Container(
              color: Colors.black12,
              child: const Center(
                child: CircularProgressIndicator(color: Color(0xFF4C8CFF)),
              ),
            ),
          ),
      ],
    );
  }
}

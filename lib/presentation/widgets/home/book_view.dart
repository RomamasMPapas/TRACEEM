import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import '../../../core/config/philippine_regions.dart';

class BookView extends StatefulWidget {
  final String? detectedRegion;

  const BookView({super.key, this.detectedRegion});

  @override
  State<BookView> createState() => BookViewState();
}

class BookViewState extends State<BookView> {
  late LatLng _initialCenter;
  LatLng? _fromLatLng; // pin location from FROM address
  LatLng? _toLatLng; // pin location from TO address
  bool _isBookingMode = false;
  bool _isGeocoding = false;
  bool _isFetchingRoute = false;
  List<LatLng> _routePoints = [];
  double? _routeDistanceMeters;
  String _selectedVehicle = 'Motorcycle';
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

  void cancelBooking() {
    setState(() {
      _isBookingMode = false;
      _fromLatLng = null;
      _toLatLng = null;
      _routePoints = [];
      _routeDistanceMeters = null;
      _fromController.clear();
      _toController.clear();
    });
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

  void _showAddressBottomSheet(String label, TextEditingController controller) {
    final currentRegion =
        PhilippineRegions.getRegionByCode(
          widget.detectedRegion ?? 'Region 7',
        ) ??
        PhilippineRegions.region7;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AddressSearchBottomSheet(
        label: label,
        initialText: controller.text,
        region: currentRegion,
        onSelected: (address, coords) {
          setState(() {
            controller.text = address;
            if (label == 'FROM:') {
              _fromLatLng = coords;
            } else {
              _toLatLng = coords;
            }
            // Animate map to the newly selected pin
            _mapController.move(coords, 14.0);

            // Fetch real road route if both are set
            if (_fromLatLng != null && _toLatLng != null) {
              _fetchRoute();
            } else {
              _routePoints = [];
              _routeDistanceMeters = null;
            }
          });
        },
      ),
    );
  }

  Future<void> _fetchRoute() async {
    if (_fromLatLng == null || _toLatLng == null) return;
    setState(() => _isFetchingRoute = true);
    try {
      final coords =
          '${_fromLatLng!.longitude},${_fromLatLng!.latitude};${_toLatLng!.longitude},${_toLatLng!.latitude}';
      final headers = {'User-Agent': 'TraceEmApp/1.0 (contact@traceem.app)'};

      // Try OSRM primary server
      var url =
          'https://router.project-osrm.org/route/v1/driving/$coords?overview=full&geometries=geojson';
      http.Response? response;

      try {
        response = await http.get(Uri.parse(url), headers: headers);
      } catch (e) {
        debugPrint('Primary OSRM failed in BookView: $e');
        response = null;
      }

      // Fallback to OSM routing server if OSRM is overloaded/blocks
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
          final dist = data['routes'][0]['distance'] as num?;

          final points = coordinates.map((coord) {
            return LatLng(
              (coord[1] as num).toDouble(),
              (coord[0] as num).toDouble(),
            );
          }).toList();

          if (mounted) {
            setState(() {
              _routePoints = points;
              _routeDistanceMeters = dist?.toDouble();
              // Slightly zoom out to fit the route by panning to the midpoint
              final centerLat =
                  (_fromLatLng!.latitude + _toLatLng!.latitude) / 2;
              final centerLng =
                  (_fromLatLng!.longitude + _toLatLng!.longitude) / 2;
              _mapController.move(LatLng(centerLat, centerLng), 13.0);
            });
            return; // Success! Exit early.
          }
        }
      }
      // If we got here, route fetch failed but didn't throw error
      if (mounted) {
        setState(() {
          _routePoints = [];
          _routeDistanceMeters = null;
        });
      }
    } catch (e) {
      debugPrint('Error fetching route: $e');
      if (mounted) {
        setState(() {
          _routePoints = [];
          _routeDistanceMeters = null;
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isFetchingRoute = false);
      }
    }
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

  void _showVehicleSelectionDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            double distanceKm = (_routeDistanceMeters ?? 0) / 1000;

            // Initial pay + Variable per km
            double motoPrice = 15.0 + (distanceKm * 10.0);
            double taxiPrice = 80.0 + (distanceKm * 15.0);

            return Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Select Vehicle Type",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  _buildVehicleOption(
                    icon: Icons.two_wheeler,
                    title: "Motorcycle",
                    baseFare: 15,
                    price: motoPrice,
                    isSelected: _selectedVehicle == "Motorcycle",
                    onTap: () {
                      setState(() => _selectedVehicle = "Motorcycle");
                      setModalState(() {});
                      Navigator.pop(ctx);
                    },
                  ),
                  const SizedBox(height: 15),
                  _buildVehicleOption(
                    icon: Icons.local_taxi,
                    title: "Taxi",
                    baseFare: 80,
                    price: taxiPrice,
                    isSelected: _selectedVehicle == "Taxi",
                    onTap: () {
                      setState(() => _selectedVehicle = "Taxi");
                      setModalState(() {});
                      Navigator.pop(ctx);
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildVehicleOption({
    required IconData icon,
    required String title,
    required double baseFare,
    required double price,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF4C8CFF).withOpacity(0.1)
              : Colors.white,
          border: Border.all(
            color: isSelected ? const Color(0xFF4C8CFF) : Colors.grey.shade300,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 30,
              color: isSelected
                  ? const Color(0xFF4C8CFF)
                  : Colors.grey.shade700,
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    "Total Price: ₱${price.toStringAsFixed(2)}",
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleButton() {
    double distanceKm = (_routeDistanceMeters ?? 0) / 1000;
    double price = 0.0;
    if (_selectedVehicle == 'Motorcycle') {
      price = 15.0 + (distanceKm * 10.0);
    } else {
      price = 80.0 + (distanceKm * 15.0);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: _showVehicleSelectionDialog,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.grey.shade300, width: 1.5),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    _selectedVehicle == 'Motorcycle'
                        ? Icons.two_wheeler
                        : Icons.local_taxi,
                    color: const Color(0xFF4C8CFF),
                    size: 32,
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedVehicle,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        if (_routeDistanceMeters != null)
                          Text(
                            "${distanceKm.toStringAsFixed(1)} km",
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          )
                        else
                          Text(
                            "Select destinations",
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      if (_routeDistanceMeters != null)
                        Text(
                          "₱${price.toStringAsFixed(2)}",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            color: Color(0xFF4C8CFF),
                          ),
                        ),
                      const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 15),
          // Proceed Button
          if (_routeDistanceMeters != null)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4C8CFF),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () {
                  // Currently dismisses booking mode
                  setState(() => _isBookingMode = false);
                },
                child: const Text(
                  "Book Now",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
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
          child: const Icon(Icons.location_on, color: Colors.red, size: 40),
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
            else if (_fromLatLng != null && _toLatLng != null)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: [_fromLatLng!, _toLatLng!],
                    color: const Color(0xFF4C8CFF).withOpacity(0.8),
                    strokeWidth: 4,
                  ),
                ],
              ),
            MarkerLayer(markers: markers),
          ],
        ),
        // Loading indicator while geocoding or routing
        if (_isGeocoding || _isFetchingRoute)
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

class _AddressSearchBottomSheet extends StatefulWidget {
  final String label;
  final String initialText;
  final PhilippineRegion region;
  final Function(String address, LatLng coords) onSelected;

  const _AddressSearchBottomSheet({
    required this.label,
    required this.initialText,
    required this.region,
    required this.onSelected,
  });

  @override
  State<_AddressSearchBottomSheet> createState() =>
      _AddressSearchBottomSheetState();
}

class _AddressSearchBottomSheetState extends State<_AddressSearchBottomSheet> {
  late TextEditingController _controller;
  Timer? _debounce;
  List<dynamic> _suggestions = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    if (query.trim().isEmpty) {
      if (mounted) {
        setState(() {
          _suggestions = [];
        });
      }
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 600), () {
      _fetchSuggestions(query);
    });
  }

  Future<void> _fetchSuggestions(String query) async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final region = widget.region;
      final viewbox =
          '${region.swLng},${region.neLat},${region.neLng},${region.swLat}';
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/search'
        '?q=${Uri.encodeComponent(query)}, Philippines'
        '&format=json&addressdetails=1&limit=5'
        '&viewbox=$viewbox&bounded=1',
      );

      http.Response? response;
      try {
        response = await http.get(
          uri,
          headers: {'User-Agent': 'TraceEmApp/1.0 (contact@traceem.app)'},
        );
      } catch (e) {
        debugPrint('Primary Geocode (Nominatim) failed: $e');
      }

      if (response != null && response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        if (data.isNotEmpty) {
          if (mounted) {
            setState(() {
              _suggestions = data;
            });
          }
          return;
        }
      }

      // Fallback to Photon (Komoot) if Nominatim fails or has no results
      debugPrint('Trying fallback geocoder (Photon)...');
      final fallbackUri = Uri.parse(
        'https://photon.komoot.io/api/?q=${Uri.encodeComponent(query)}&limit=5&lat=${region.centerLat}&lon=${region.centerLng}',
      );

      final fallbackRes = await http.get(fallbackUri);
      if (fallbackRes.statusCode == 200) {
        final data = jsonDecode(fallbackRes.body);
        final features = data['features'] as List;

        final normalized = features.map((f) {
          final props = f['properties'];
          final geom = f['geometry']['coordinates'];

          // Construct a display name similar to Nominatim
          String name = props['name'] ?? '';
          if (props['city'] != null) name += ', ${props['city']}';
          if (props['state'] != null) name += ', ${props['state']}';

          return {'display_name': name, 'lat': geom[1], 'lon': geom[0]};
        }).toList();

        if (mounted) {
          setState(() {
            _suggestions = normalized;
          });
        }
      }
    } catch (e) {
      debugPrint('Geocode fallback error: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
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
              widget.label == 'FROM:'
                  ? 'Search Pick-up Location'
                  : 'Search Destination',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              autofocus: true,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: widget.label == 'FROM:'
                    ? 'e.g. IT Park, Lahug, Cebu City'
                    : 'e.g. Parkmall, Mandaue City',
                prefixIcon: Icon(
                  widget.label == 'FROM:'
                      ? Icons.my_location
                      : Icons.location_on,
                  color: const Color(0xFF4C8CFF),
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () {
                    _controller.clear();
                    _onSearchChanged('');
                  },
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
            ),
            const SizedBox(height: 12),
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: CircularProgressIndicator(color: Color(0xFF4C8CFF)),
                ),
              )
            else if (_suggestions.isEmpty && _controller.text.isNotEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Text(
                    'No results found. Try adjusting your search.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: _suggestions.length,
                  itemBuilder: (context, index) {
                    final item = _suggestions[index];
                    final address = item['display_name'] ?? '';
                    return ListTile(
                      leading: const Icon(
                        Icons.location_on,
                        color: Colors.grey,
                      ),
                      title: Text(
                        address,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 14),
                      ),
                      onTap: () {
                        final lat =
                            double.tryParse(item['lat'].toString()) ?? 0.0;
                        final lon =
                            double.tryParse(item['lon'].toString()) ?? 0.0;
                        widget.onSelected(address, LatLng(lat, lon));
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

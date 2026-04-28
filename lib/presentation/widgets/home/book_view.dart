import 'dart:convert';
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import '../../../core/config/philippine_regions.dart';
import '../../screens/rating_screen.dart';

/// The booking tab widget on the Home screen.
/// Shows an OpenStreetMap with FROM/TO address search, route drawing, and vehicle selection.
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
  final bool _isGeocoding = false;
  bool _isFetchingRoute = false;
  List<LatLng> _routePoints = [];
  double? _routeDistanceMeters;
  String _selectedVehicle = 'Motorcycle';
  final MapController _mapController = MapController();

  // DRIVE SIMULATION STATE
  bool _isSimulatingDrive = false;
  LatLng? _animatedVehiclePos;
  int _currentRouteIndex = 0;
  Timer? _simulationTimer;
  Map<String, dynamic>? _currentDriver;
  bool _showHistory = true;
  bool _hasSelectedVehicle = false; // Tracks if user explicitly chose a vehicle

  final List<Map<String, dynamic>> _rideHistory = [
    {
      'fromName': 'IT Park, Lahug',
      'fromCoords': const LatLng(10.3297, 123.9061),
      'toName': 'SM City Cebu',
      'toCoords': const LatLng(10.3117, 123.9183),
      'date': 'Yesterday',
    },
    {
      'fromName': 'Ayala Center',
      'fromCoords': const LatLng(10.3178, 123.9050),
      'toName': 'Mactan Airport',
      'toCoords': const LatLng(10.3060, 123.9790),
      'date': '2 days ago',
    },
    {
      'fromName': 'Colon Street',
      'fromCoords': const LatLng(10.2977, 123.8996),
      'toName': 'Fuente Osmeña',
      'toCoords': const LatLng(10.3114, 123.8938),
      'date': 'Last week',
    },
  ];

  @override
  void initState() {
    super.initState();
    _setInitialPosition();
  }

  /// Sets the map's initial center to the center of the user's detected region.
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

  /// Resets all booking state — clears addresses, pins, route, and hides the booking panel.
  void cancelBooking() {
    setState(() {
      _isBookingMode = false;
      _fromLatLng = null;
      _toLatLng = null;
      _routePoints = [];
      _routeDistanceMeters = null;
      _fromController.clear();
      _toController.clear();
      _showHistory = true; // Ensure history shows again for next booking
      _hasSelectedVehicle = false; // Reset vehicle choice
    });
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    // Map takes 75% of height in booking mode, 100% otherwise
    bool isDetailsMode = _isBookingMode && !_isSimulatingDrive;
    // Lengthened mapCard both ways: lower top padding and lower bottom lift
    double mapBottomPadding = isDetailsMode ? screenHeight * 0.16 : 0;
    double mapTopPadding = isDetailsMode ? 70 : 0; // Much lower top padding
    double sidePadding = isDetailsMode ? 15 : 0; // Added side padding back

    return Container(
      color: Colors.white,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 1. Animated Map with 75/25 split
          AnimatedPadding(
            duration: const Duration(milliseconds: 600),
            curve: Curves.fastOutSlowIn,
            padding: EdgeInsets.only(
              top: mapTopPadding,
              bottom: mapBottomPadding,
              left: sidePadding,
              right: sidePadding,
            ),
            child: Container(
              decoration: isDetailsMode
                  ? BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey.shade200),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    )
                  : null,
              child: ClipRRect(
                borderRadius: isDetailsMode
                    ? BorderRadius.circular(20)
                    : BorderRadius.zero,
                child: _buildOSMMap(),
              ),
            ),
          ),

          // 2. Bottom Panel Background (White Sheet)
          if (isDetailsMode)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 600),
                height: isDetailsMode
                    ? screenHeight * 0.16
                    : 0, // Increased height to avoid overflow
                curve: Curves.fastOutSlowIn,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(25),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 20,
                      offset: const Offset(0, -10),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.only(
                    top: 38.0,
                  ), // Slightly reduced to fit booking button better
                  child: _buildVehicleButton(),
                ),
              ),
            ),

          // 3. Floating Van Bubble Positioned relative to map bottom center
          if (!_isSimulatingDrive)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 600),
              curve: Curves.fastOutSlowIn,
              bottom: isDetailsMode
                  ? (screenHeight * 0.16 -
                        37.5) // Re-centered on the adjusted 16% edge
                  : 40, // Normal floating position
              left: 0,
              right: 0,
              child: Center(
                child: isDetailsMode
                    ? Hero(tag: 'van-btn', child: _buildVanButton())
                    : _buildVanButton(),
              ),
            ),

          // 4. Search Bars (Visible in Booking Mode)
          if (isDetailsMode)
            Positioned(
              top: 25,
              left: 20,
              right: 20,
              child: Column(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Column(
                        children: [
                          _buildSearchInput("FROM:", _fromController),
                          const SizedBox(
                            height: 40,
                          ), // Increased space so button doesn't touch bars
                          _buildSearchInput("TO:", _toController),
                        ],
                      ),
                      // Reverse / Swap Button
                      Positioned(
                        top:
                            49, // (45 from top search bar + (40 gap - 32 button height)/2)
                        left: 0,
                        right: 0,
                        child: Center(
                          child: GestureDetector(
                            onTap: _swapAddresses,
                            child: Container(
                              height: 32,
                              width: 32,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.grey.shade200),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.swap_vert,
                                color: Color(0xFF4C8CFF),
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_showHistory && _routePoints.isEmpty)
                    _buildHistorySection(),
                ],
              ),
            ),

          // 5. Region indicator badge (Only in normal mode)
          if (!_isBookingMode && !_isSimulatingDrive)
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
        ],
      ),
    );
  }

  final TextEditingController _fromController = TextEditingController();
  final TextEditingController _toController = TextEditingController();

  /// Swaps the FROM and TO locations, updating text controllers, coordinates, and route.
  void _swapAddresses() {
    if (_fromController.text.isEmpty && _toController.text.isEmpty) return;
    setState(() {
      final String tempText = _fromController.text;
      _fromController.text = _toController.text;
      _toController.text = tempText;

      final LatLng? tempLatLng = _fromLatLng;
      _fromLatLng = _toLatLng;
      _toLatLng = tempLatLng;

      // Re-fetch route if both are now set
      if (_fromLatLng != null && _toLatLng != null) {
        _fetchRoute();
      } else {
        _routePoints = [];
        _routeDistanceMeters = null;
      }
    });
  }

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    _mapController.dispose();
    _simulationTimer?.cancel();
    super.dispose();
  }

  /// Opens the address search bottom sheet for either the FROM or TO field.
  /// On selection, updates the pin on the map and triggers route fetching if both points are set.
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
        rideHistory: _rideHistory,
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

  /// Fetches the driving route between the FROM and TO coordinates using OSRM.
  /// Falls back to OpenStreetMap routing server on failure.
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

  /// Builds a tappable search input bar that opens the address bottom sheet on tap.
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
              color: Colors.black.withValues(alpha: 0.06),
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

  /// Builds the "Recent Rides" section as a compact, integrated list.
  Widget _buildHistorySection() {
    return Column(
      children: [
        const SizedBox(height: 8),
        ..._rideHistory.take(2).map((ride) => _buildHistoryItem(ride)),
      ],
    );
  }

  /// Builds a single history item row.
  Widget _buildHistoryItem(Map<String, dynamic> ride) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            _fromController.text = ride['fromName'];
            _fromLatLng = ride['fromCoords'];
            _toController.text = ride['toName'];
            _toLatLng = ride['toCoords'];
            _fetchRoute();
            _showHistory = false;
          });
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              const Icon(Icons.history, size: 14, color: Colors.blueGrey),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  "${ride['fromName']} → ${ride['toName']}",
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(Icons.chevron_right, size: 14, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the circular van/truck button that triggers booking mode when tapped.
  Widget _buildVanButton() {
    IconData displayIcon;
    if (!_isBookingMode || !_hasSelectedVehicle) {
      displayIcon = Icons.local_shipping;
    } else {
      displayIcon = _selectedVehicle == 'Motorcycle'
          ? Icons.two_wheeler
          : Icons.local_taxi;
    }

    return GestureDetector(
      onTap: () {
        if (!_isBookingMode) {
          setState(() => _isBookingMode = true);
        } else {
          _showVehicleSelectionDialog();
        }
      },
      child: Container(
        width: 75,
        height: 75,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF4C8CFF), Color(0xFF3B6FCC)],
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4C8CFF).withValues(alpha: 0.4),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
          border: Border.all(color: Colors.white, width: 4),
        ),
        child: Icon(displayIcon, color: Colors.white, size: 40),
      ),
    );
  }

  /// Shows a bottom sheet for the user to select a vehicle type (Motorcycle or Taxi).
  /// Calculates and displays the trip price based on route distance.
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

            // Initial pay + Variable (Motorcycle: 5 per 100m = 50 per km)
            double motoPrice = 15.0 + (distanceKm * 50.0);
            double taxiPrice = 80.0; // Taxi runs on time, no per-km rate

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
                      setState(() {
                        _selectedVehicle = "Motorcycle";
                        _hasSelectedVehicle = true;
                      });
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
                      setState(() {
                        _selectedVehicle = "Taxi";
                        _hasSelectedVehicle = true;
                      });
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

  /// Builds a single selectable vehicle option tile showing the icon, name, and estimated price.
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        transform: isSelected
            ? (Matrix4.identity()..scale(1.02))
            : Matrix4.identity(),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.grey.shade50,
          gradient: isSelected
              ? const LinearGradient(
                  colors: [Colors.white, Color(0xFFF0F5FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF4C8CFF) : Colors.grey.shade200,
            width: isSelected ? 2.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF4C8CFF).withValues(alpha: 0.25),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF4C8CFF).withValues(alpha: 0.1)
                    : Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 32,
                color: isSelected
                    ? const Color(0xFF4C8CFF)
                    : Colors.grey.shade600,
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 17,
                      color: isSelected
                          ? const Color(0xFF1E3A8A)
                          : Colors.black87,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "Standard ride • Faster booking",
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              "₱${price.toStringAsFixed(0)}",
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 22,
                color: isSelected ? const Color(0xFF4C8CFF) : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the bottom booking panel with the selected vehicle info, distance, price,
  /// vehicle switcher button, and the final 'Book Now' confirm button.
  Widget _buildVehicleButton() {
    double distanceKm = (_routeDistanceMeters ?? 0) / 1000;
    double price = 0.0;
    if (_selectedVehicle == 'Motorcycle') {
      price = 15.0 + (distanceKm * 50.0);
    } else {
      price = 80.0; // Taxi runs on time, no per-km rate
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Simplified trip details instead of the big selection box
          if (_routeDistanceMeters != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "${distanceKm.toStringAsFixed(1)} KM",
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      letterSpacing: 1.1,
                    ),
                  ),
                  if (_hasSelectedVehicle) ...[
                    Container(
                      width: 4,
                      height: 4,
                      margin: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Text(
                      "₱${price.toStringAsFixed(2)}",
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                        color: Color(0xFF4C8CFF),
                      ),
                    ),
                  ],
                ],
              ),
            )
          else
            const Padding(
              padding: EdgeInsets.only(bottom: 15),
              child: Text(
                "SELECT DESTINATIONS",
                style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  letterSpacing: 1.1,
                ),
              ),
            ),

          // Proceed Button
          if (_routeDistanceMeters != null && _hasSelectedVehicle)
            Padding(
              padding: const EdgeInsets.only(
                top: 5,
                right: 65,
              ), // Leave space for FloatingActionButton
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4C8CFF), Color(0xFF3B6FCC)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4C8CFF).withValues(alpha: 0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  onPressed: _handleBookNow,
                  child: const Text(
                    "CONFIRM BOOKING",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // --- MOCK DRIVER DATA & BOOKING FLOW ---

  /// List of motorcycle drivers available for simulation.
  /// Each driver includes name, rating, plate, vehicle model, description, and profile pic.
  final List<Map<String, dynamic>> _motorcycleDrivers = [
    {
      'name': 'Lito Fast',
      'rating': 4.8,
      'plate': 'MC-101',
      'vehicle': 'Honda Click - Black',
      'desc': 'Quick and agile, perfect for traffic.',
      'pic': 'https://robohash.org/LitoFast.png?set=set4',
    },
    {
      'name': 'Maria Rider',
      'rating': 4.9,
      'plate': 'MC-202',
      'vehicle': 'Yamaha NMAX - Blue',
      'desc': 'Safe driving and very professional.',
      'pic': 'https://robohash.org/MariaRider.png?set=set4',
    },
    {
      'name': 'Jun Moto',
      'rating': 4.7,
      'plate': 'MC-303',
      'vehicle': 'Suzuki Burgman - Silver',
      'desc': 'Comfortable seat and smooth ride.',
      'pic': 'https://robohash.org/JunMoto.png?set=set4',
    },
    {
      'name': 'Rico Speed',
      'rating': 4.6,
      'plate': 'MC-404',
      'vehicle': 'Kawasaki Ninja - Green',
      'desc': 'Well-maintained bike and experienced rider.',
      'pic': 'https://robohash.org/RicoSpeed.png?set=set4',
    },
    {
      'name': 'Elena Cruz',
      'rating': 5.0,
      'plate': 'MC-505',
      'vehicle': 'Honda Beat - Red',
      'desc': 'Friendly and knows all the shortcuts.',
      'pic': 'https://robohash.org/ElenaCruz.png?set=set4',
    },
  ];

  final List<Map<String, dynamic>> _taxiDrivers = [
    {
      'name': 'Robert Driver',
      'rating': 4.8,
      'plate': 'TX-111',
      'vehicle': 'Toyota Vios - White',
      'desc': 'Clean interior and cool AC.',
      'pic': 'https://robohash.org/RobertDriver.png?set=set4',
    },
    {
      'name': 'Sally Cab',
      'rating': 4.7,
      'plate': 'TX-222',
      'vehicle': 'Hyundai Accent - Black',
      'desc': 'Quiet ride and helps with luggage.',
      'pic': 'https://robohash.org/SallyCab.png?set=set4',
    },
    {
      'name': 'Ben Taxi',
      'rating': 4.5,
      'plate': 'TX-333',
      'vehicle': 'Honda City - Silver',
      'desc': 'Punctual and follows navigation strictly.',
      'pic': 'https://robohash.org/BenTaxi.png?set=set4',
    },
    {
      'name': 'Fred Wheeler',
      'rating': 4.9,
      'plate': 'TX-444',
      'vehicle': 'Toyota Corolla - White',
      'desc': 'Premium feel and very spacious.',
      'pic': 'https://robohash.org/FredWheeler.png?set=set4',
    },
    {
      'name': 'Gloria Road',
      'rating': 4.6,
      'plate': 'TX-555',
      'vehicle': 'Nissan Almera - Grey',
      'desc': 'Soft-spoken and safe driver.',
      'pic': 'https://robohash.org/GloriaRoad.png?set=set4',
    },
  ];

  /// Initiates the booking process by showing a waiting dialog.
  /// Once the 10-second timer completes, it triggers the driver assignment.
  void _handleBookNow() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return _WaitingDialog(
          onComplete: () {
            Navigator.of(context).pop();
            _showDriverAcceptedDialog();
          },
        );
      },
    );
  }

  /// Randomly selects a driver from the appropriate vehicle pool and shows an acceptance dialog.
  /// The dialog displays driver details, vehicle info, and a "Proceed" button for the receipt.
  void _showDriverAcceptedDialog() {
    final random = Random();
    final driverList = _selectedVehicle == 'Motorcycle'
        ? _motorcycleDrivers
        : _taxiDrivers;
    final driver = driverList[random.nextInt(driverList.length)];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 10),
              Text('Driver Found!'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                driver['name'],
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.star, color: Colors.orange, size: 20),
                  Text(' ${driver['rating']} (Active Now)'),
                ],
              ),
              const Divider(height: 24),
              const Text(
                'Vehicle:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              Text(driver['vehicle']),
              Text('Plate: ${driver['plate']}'),
              const SizedBox(height: 8),
              const Text(
                'Description:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              Text(
                driver['desc'],
                style: const TextStyle(fontStyle: FontStyle.italic),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'CANCEL',
                style: TextStyle(color: Colors.red.shade400),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4C8CFF),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                _showVirtualReceipt(driver);
              },
              child: const Text('PROCEED TO RECEIPT'),
            ),
          ],
        );
      },
    );
  }

  /// Displays a detailed virtual receipt showing the driver info and route map.
  /// Allows the user to initiate the drive simulation.
  void _showVirtualReceipt(Map<String, dynamic> driver) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: Container(
            padding: const EdgeInsets.all(16),
            width: MediaQuery.of(context).size.width * 0.9,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [Icon(Icons.logout, size: 20)],
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Text(
                      '#TEM-2026-X8',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blueGrey,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 120,
                      height: 130,
                      decoration: BoxDecoration(
                        color: Colors.pink.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.pink.shade100),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          driver['pic'],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Center(child: Icon(Icons.person, size: 50)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        children: [
                          Container(
                            height: 48,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: const Color(0xFF2DFF81),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Center(
                              child: Text(
                                'RIDE RECEIPT',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            height: 72,
                            width: double.infinity,
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.cyan.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  driver['name'],
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  driver['vehicle'],
                                  style: const TextStyle(fontSize: 10),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                // Distance and Total section
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange.shade100),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'DISTANCE',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange,
                              ),
                            ),
                            Text(
                              '${((_routeDistanceMeters ?? 0) / 1000).toStringAsFixed(2)} km',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green.shade100),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'TOTAL DUE',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                            Text(
                              '₱${(_selectedVehicle == 'Motorcycle' ? (15.0 + ((_routeDistanceMeters ?? 0) / 1000) * 10.0) : (80.0 + ((_routeDistanceMeters ?? 0) / 1000) * 15.0)).toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    height: 200,
                    width: double.infinity,
                    color: Colors.grey.shade200,
                    child: Stack(
                      children: [
                        FlutterMap(
                          options: MapOptions(
                            initialCenter:
                                _fromLatLng ?? const LatLng(10.33, 123.90),
                            initialZoom: 13,
                          ),
                          children: [
                            TileLayer(
                              urlTemplate:
                                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            ),
                            if (_routePoints.isNotEmpty)
                              PolylineLayer(
                                polylines: [
                                  Polyline(
                                    points: _routePoints,
                                    color: Colors.blue.shade900,
                                    strokeWidth: 4,
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  '(MAP REFERENCE)',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 15),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4C8CFF),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                      _currentDriver = driver;
                      _startDriveSimulation();
                    },
                    child: const Text(
                      'SIMULATE DRIVE',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    'CANCEL ORDER',
                    style: TextStyle(
                      color: Colors.red.shade400,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Starts the animated drive simulation.
  /// Moves the vehicle icon point-by-point along the fetched route and centers the map on it.
  /// Navigates to the rating page upon arrival at the destination.
  void _startDriveSimulation() {
    if (_routePoints.isEmpty) {
      _navigateToRating(_currentDriver!);
      return;
    }

    setState(() {
      _isSimulatingDrive = true;
      _currentRouteIndex = 0;
      _animatedVehiclePos = _routePoints[0];
    });

    _simulationTimer = Timer.periodic(const Duration(milliseconds: 100), (
      timer,
    ) {
      if (_currentRouteIndex < _routePoints.length - 1) {
        setState(() {
          _currentRouteIndex++;
          _animatedVehiclePos = _routePoints[_currentRouteIndex];
          // Follow the vehicle with the map
          _mapController.move(_animatedVehiclePos!, 14.5);
        });
      } else {
        timer.cancel();
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            setState(() => _isSimulatingDrive = false);
            _navigateToRating(_currentDriver!);
          }
        });
      }
    });
  }

  /// Displays the RatingDialog for the user to provide feedback for the driver.
  /// Resets the booking UI states after the dialog is shown.
  void _navigateToRating(Map<String, dynamic> driver) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => RatingDialog(
        driverName: driver['name'],
        vehicleInfo: "${driver['vehicle']} - ${driver['plate']}",
        driverPic: driver['pic'],
      ),
    );

    cancelBooking();
  }

  /// Builds the OpenStreetMap widget with route polyline and location markers.
  Widget _buildOSMMap() {
    // Build marker list: FROM pin (green) + TO pin (red)
    final markers = <Marker>[
      if (_fromLatLng != null)
        Marker(
          point: _fromLatLng!,
          width: 44,
          height: 44,
          child: const Icon(Icons.location_on, color: Colors.green, size: 40),
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

      // ANIMATED VEHICLE ICON
      if (_isSimulatingDrive && _animatedVehiclePos != null)
        Marker(
          point: _animatedVehiclePos!,
          width: 60,
          height: 60,
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              _selectedVehicle == 'Motorcycle'
                  ? Icons.two_wheeler
                  : Icons.local_taxi,
              color: const Color(0xFF4C8CFF),
              size: 35,
            ),
          ),
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
                    color: const Color(0xFF4C8CFF).withValues(alpha: 0.8),
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
  final List<Map<String, dynamic>> rideHistory;
  final Function(String address, LatLng coords) onSelected;

  const _AddressSearchBottomSheet({
    required this.label,
    required this.initialText,
    required this.region,
    required this.rideHistory,
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
                child: ListView(
                  children: [
                    if (_controller.text.isEmpty &&
                        widget.rideHistory.isNotEmpty) ...[
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 10),
                        child: Text(
                          'RECENT RIDES',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueGrey,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      ...widget.rideHistory.map((ride) {
                        final address = widget.label == 'FROM:'
                            ? ride['fromName']
                            : ride['toName'];
                        final coords = widget.label == 'FROM:'
                            ? ride['fromCoords']
                            : ride['toCoords'];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(
                            Icons.history,
                            color: Colors.blueGrey,
                            size: 20,
                          ),
                          title: Text(
                            address,
                            style: const TextStyle(fontSize: 14),
                          ),
                          onTap: () {
                            widget.onSelected(address, coords);
                            Navigator.pop(context);
                          },
                        );
                      }),
                      const Divider(height: 30),
                    ],
                    ..._suggestions.map((item) {
                      final address = item['display_name'] ?? '';
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
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
                    }),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _WaitingDialog extends StatefulWidget {
  final VoidCallback onComplete;
  const _WaitingDialog({required this.onComplete});

  @override
  State<_WaitingDialog> createState() => _WaitingDialogState();
}

class _WaitingDialogState extends State<_WaitingDialog> {
  int _secondsRemaining = 10;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        _timer?.cancel();
        widget.onComplete();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
      elevation: 20,
      backgroundColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 25),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 80,
                  height: 80,
                  child: CircularProgressIndicator(
                    strokeWidth: 6,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF4C8CFF),
                    ),
                    backgroundColor: Colors.grey.shade100,
                  ),
                ),
                const Icon(
                  Icons.location_searching,
                  color: Color(0xFF4C8CFF),
                  size: 35,
                ),
              ],
            ),
            const SizedBox(height: 30),
            const Text(
              'FINDING YOUR RIDE',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 20,
                letterSpacing: 2.5,
                color: Color(0xFF1E3A8A),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Searching for nearby drivers...',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 35),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF4C8CFF).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.timer_outlined,
                    size: 20,
                    color: Color(0xFF4C8CFF),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '$_secondsRemaining s',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 24,
                      color: Color(0xFF4C8CFF),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),
            TextButton(
              onPressed: () {
                _timer?.cancel();
                Navigator.of(context).pop();
              },
              child: Text(
                'CANCEL REQUEST',
                style: TextStyle(
                  color: Colors.red.shade400,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

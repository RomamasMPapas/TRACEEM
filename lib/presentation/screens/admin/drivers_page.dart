import 'package:flutter/material.dart';

/// A page for administrators to manage drivers.
/// Displays driver ratings, feedback, ride history, and allows firing drivers.
class DriversPage extends StatefulWidget {
  const DriversPage({super.key});

  @override
  State<DriversPage> createState() => _DriversPageState();
}

/// The [_DriversPageState] class is responsible for managing its respective UI components and state.
class _DriversPageState extends State<DriversPage> {
  final TextEditingController _searchController = TextEditingController();

  // Mock data for drivers
  final List<Map<String, dynamic>> _allDrivers = [
    // Motorcycles (5)
    {
      'id': 'd1', 'name': 'Lito Fast', 'vehicle': 'Honda Click', 'plateNumber': 'ABC 123', 'totalRating': 4.8, 'status': 'Active', 'type': 'Motorcycle',
      'rides': [{'date': '2023-10-25', 'user': 'Rob Martin', 'rating': 5, 'feedback': 'Awesome ride! Very fast and safe.', 'fare': '₱50'}]
    },
    {
      'id': 'd3', 'name': 'Maria Rider', 'vehicle': 'Yamaha NMAX', 'plateNumber': 'XYZ 123', 'totalRating': 4.9, 'status': 'Active', 'type': 'Motorcycle',
      'rides': [{'date': '2023-10-26', 'user': 'Alice Smith', 'rating': 5, 'feedback': 'Very professional.', 'fare': '₱60'}]
    },
    {
      'id': 'd5', 'name': 'Jun Moto', 'vehicle': 'Suzuki Burgman', 'plateNumber': 'QWE 456', 'totalRating': 2.5, 'status': 'Active', 'type': 'Motorcycle',
      'rides': [{'date': '2023-10-22', 'user': 'Charlie Brown', 'rating': 2, 'feedback': 'Rude and drove recklessly.', 'fare': '₱60'}]
    },
    {
      'id': 'd6', 'name': 'Kiko Wheels', 'vehicle': 'Kawasaki Rouser', 'plateNumber': 'RTY 789', 'totalRating': 4.2, 'status': 'Active', 'type': 'Motorcycle',
      'rides': [{'date': '2023-10-27', 'user': 'David Lee', 'rating': 4, 'feedback': 'Good driver.', 'fare': '₱55'}]
    },
    {
      'id': 'd7', 'name': 'Benji Zoom', 'vehicle': 'Vespa Primavera', 'plateNumber': 'UIO 012', 'totalRating': 3.8, 'status': 'Active', 'type': 'Motorcycle',
      'rides': [{'date': '2023-10-28', 'user': 'Eva Green', 'rating': 4, 'feedback': 'Smooth ride.', 'fare': '₱70'}]
    },
    // Taxis (5)
    {
      'id': 'd2', 'name': 'Robert Driver', 'vehicle': 'Toyota Vios', 'plateNumber': 'XYZ 987', 'totalRating': 3.0, 'status': 'Active', 'type': 'Taxi',
      'rides': [{'date': '2023-10-25', 'user': 'Jane Doe', 'rating': 3, 'feedback': 'Comfortable but long route.', 'fare': '₱120'}]
    },
    {
      'id': 'd4', 'name': 'Sally Cab', 'vehicle': 'Hyundai Accent', 'plateNumber': 'ASD 345', 'totalRating': 3.5, 'status': 'Active', 'type': 'Taxi',
      'rides': [{'date': '2023-10-26', 'user': 'Bob Johnson', 'rating': 3, 'feedback': 'A bit slow.', 'fare': '₱150'}]
    },
    {
      'id': 'd8', 'name': 'Carlo Sedan', 'vehicle': 'Nissan Almera', 'plateNumber': 'FGH 678', 'totalRating': 4.5, 'status': 'Active', 'type': 'Taxi',
      'rides': [{'date': '2023-10-28', 'user': 'Fiona Gallagher', 'rating': 5, 'feedback': 'Clean car.', 'fare': '₱130'}]
    },
    {
      'id': 'd9', 'name': 'Dina Drive', 'vehicle': 'Mitsubishi Mirage', 'plateNumber': 'JKL 901', 'totalRating': 2.8, 'status': 'Active', 'type': 'Taxi',
      'rides': [{'date': '2023-10-29', 'user': 'George Costanza', 'rating': 2, 'feedback': 'Smelled weird.', 'fare': '₱110'}]
    },
    {
      'id': 'd10', 'name': 'Tony Wheels', 'vehicle': 'Kia Soluto', 'plateNumber': 'ZXC 234', 'totalRating': 4.0, 'status': 'Active', 'type': 'Taxi',
      'rides': [{'date': '2023-10-29', 'user': 'Hannah Abbott', 'rating': 4, 'feedback': 'Relaxing music.', 'fare': '₱140'}]
    },
  ];

  List<Map<String, dynamic>> _filteredDrivers = [];

  /// Initializes the state of the widget before it is built.
  @override
  void initState() {
    super.initState();
    _filteredDrivers = List.from(_allDrivers);
  }

  String _selectedType = 'All';

  /// Filters the driver list based on the search query and the selected vehicle type.
  /// Updates the [_filteredDrivers] state variable to immediately reflect in the UI.
  void _filterDrivers([String? query]) {
    final searchQuery = query ?? _searchController.text;
    setState(() {
      _filteredDrivers = _allDrivers.where((d) {
        final matchesSearch = d['name'].toLowerCase().contains(searchQuery.toLowerCase()) ||
            d['vehicle'].toLowerCase().contains(searchQuery.toLowerCase());
        
        final matchesType = _selectedType == 'All' || d['type'] == _selectedType;
        
        return matchesSearch && matchesType;
      }).toList();
    });
  }

  /// Displays a confirmation dialog and then fires a driver by removing them from the
  /// mock database. Also updates the UI and dashboard metrics if applicable.
  void _fireDriver(String driverId, String driverName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Fire Driver?'),
        content: Text('Are you sure you want to fire $driverName? This action cannot be undone and will revoke their access.'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                final index = _allDrivers.indexWhere((d) => d['id'] == driverId);
                if (index != -1) {
                  _allDrivers[index]['status'] = 'Fired';
                }
                _filterDrivers(_searchController.text);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$driverName has been fired.'),
                  backgroundColor: Colors.red,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('FIRE DRIVER'),
          ),
        ],
      ),
    );
  }

  /// Executes the logic for _showDriverDetails.
  void _showDriverDetails(Map<String, dynamic> driver) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final rides = driver['rides'] as List;
        
        // Calculate extra info
        final totalRides = rides.length;
        double totalEarnings = 0;
        for (var ride in rides) {
          final fareStr = ride['fare'].toString().replaceAll('₱', '');
          totalEarnings += double.tryParse(fareStr) ?? 0;
        }

        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Premium Header
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                      boxShadow: [
                        BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4)),
                      ],
                    ),
                    child: Column(
                      children: [
                        Center(
                          child: Container(
                            width: 50,
                            height: 5,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 35,
                              backgroundColor: Colors.blue.shade100,
                              child: Text(
                                driver['name'][0],
                                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        driver['name'],
                                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: driver['status'] == 'Active' ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          driver['status'].toUpperCase(),
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: driver['status'] == 'Active' ? Colors.green : Colors.red,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${driver['vehicle']} • ${driver['plateNumber']}',
                                    style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
                                  ),
                                  const SizedBox(height: 12),
                                  // Stats Row
                                  Row(
                                    children: [
                                      _buildStatItem(Icons.star, Colors.amber, 'Rating', driver['totalRating'].toString()),
                                      const SizedBox(width: 16),
                                      _buildStatItem(Icons.route, Colors.blue, 'Rides', totalRides.toString()),
                                      const SizedBox(width: 16),
                                      _buildStatItem(Icons.payments, Colors.green, 'Earnings', '₱${totalEarnings.toStringAsFixed(0)}'),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // Rides List
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                    child: const Text(
                      'Ride History & Feedback',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
                    ),
                  ),
                  Expanded(
                    child: rides.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.history_toggle_off, size: 60, color: Colors.grey.shade300),
                                const SizedBox(height: 16),
                                Text('No rides recorded yet.', style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
                              ],
                            ),
                          )
                        : ListView.builder(
                            controller: scrollController,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            itemCount: rides.length,
                            itemBuilder: (context, index) {
                              final ride = rides[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 16),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: BorderSide(color: Colors.grey.shade200),
                                ),
                                color: Colors.white,
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.grey.shade100,
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              ride['date'],
                                              style: TextStyle(color: Colors.grey.shade700, fontSize: 12, fontWeight: FontWeight.w600),
                                            ),
                                          ),
                                          Row(
                                            children: [
                                              const Icon(Icons.star_rounded, color: Colors.amber, size: 20),
                                              const SizedBox(width: 4),
                                              Text(
                                                ride['rating'].toString(),
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 16,
                                            backgroundColor: Colors.blue.shade50,
                                            child: Icon(Icons.person, size: 18, color: Colors.blue.shade400),
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            ride['user'],
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                          ),
                                          const Spacer(),
                                          Text(
                                            ride['fare'],
                                            style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.green, fontSize: 16),
                                          ),
                                        ],
                                      ),
                                      if (ride['feedback'] != null && ride['feedback'].toString().isNotEmpty) ...[
                                        const SizedBox(height: 16),
                                        Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Colors.amber.withValues(alpha: 0.05),
                                            borderRadius: BorderRadius.circular(10),
                                            border: Border.all(color: Colors.amber.withValues(alpha: 0.2)),
                                          ),
                                          child: Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Icon(Icons.format_quote_rounded, color: Colors.amber.shade700, size: 18),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  ride['feedback'],
                                                  style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey.shade800, fontSize: 13),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ]
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// Builds and returns the _buildStatItem custom widget component.
  Widget _buildStatItem(IconData icon, Color Color, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Color, size: 16),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 10)),
          ],
        ),
      ],
    );
  }

  /// Builds the visual structure of this widget, returning the widget tree.
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // "Folder" Tabs for vehicle types
        Container(
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: ['All', 'Motorcycle', 'Taxi'].map((type) {
              final isSelected = _selectedType == type;
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedType = type;
                      _filterDrivers();
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF4C8CFF) : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: Colors.blue.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              )
                            ]
                          : [],
                    ),
                    child: Center(
                      child: Text(
                        type,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            onChanged: _filterDrivers,
            decoration: InputDecoration(
              hintText: 'Search by Driver Name or Vehicle...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _filteredDrivers.length,
            itemBuilder: (context, index) {
              final driver = _filteredDrivers[index];
              final double rating = driver['totalRating'];
              final Color ratingColor = rating > 3
                  ? Colors.green
                  : (rating == 3 ? Colors.amber : Colors.red);
              final bool isFired = driver['status'] == 'Fired';

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 4,
                color: isFired ? Colors.grey.shade200 : Colors.white,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border(
                        left: BorderSide(
                          color: isFired ? Colors.grey : ratingColor,
                          width: 6,
                        ),
                      ),
                    ),
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  driver['name'],
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 18,
                                    color: isFired ? Colors.grey : const Color(0xFF1E3A8A),
                                    decoration: isFired ? TextDecoration.lineThrough : null,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${driver['vehicle']} • ${driver['plateNumber']}',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: isFired ? Colors.grey.shade300 : ratingColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.star,
                                    color: isFired ? Colors.grey.shade600 : ratingColor,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    rating.toStringAsFixed(1),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isFired ? Colors.grey.shade600 : ratingColor,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _showDriverDetails(driver),
                                icon: const Icon(Icons.history, size: 18),
                                label: const Text('View Rides & Feedback'),
                                style: OutlinedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                            if (!isFired) ...[
                              const SizedBox(width: 12),
                              ElevatedButton.icon(
                                onPressed: () => _fireDriver(driver['id'], driver['name']),
                                icon: const Icon(Icons.block, size: 18),
                                label: const Text('FIRE'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red.shade600,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

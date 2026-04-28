import 'package:flutter/material.dart';

/// A page for administrators to view and manage driver ratings and user feedback.
/// Displays a searchable list of entries featuring driver names, star ratings, and user comments.
class RatingsPage extends StatefulWidget {
  const RatingsPage({super.key});

  @override
  State<RatingsPage> createState() => _RatingsPageState();
}

class _RatingsPageState extends State<RatingsPage> {
  final TextEditingController _searchController = TextEditingController();
  final List<Map<String, dynamic>> _allRatings = [
    // Motorcycles (5)
    {'driver': 'Lito Fast', 'user': 'Rob Martin', 'rating': 5, 'comment': 'Awesome ride! Very fast and safe.', 'vehicle': 'Honda Click', 'type': 'Motorcycle'},
    {'driver': 'Maria Rider', 'user': 'Alice Smith', 'rating': 5, 'comment': 'Very professional and safe driving.', 'vehicle': 'Yamaha NMAX', 'type': 'Motorcycle'},
    {'driver': 'Jun Moto', 'user': 'Charlie Brown', 'rating': 2, 'comment': 'Rude and drove recklessly.', 'vehicle': 'Suzuki Burgman', 'type': 'Motorcycle'},
    {'driver': 'Kiko Wheels', 'user': 'David Lee', 'rating': 4, 'comment': 'Good driver, knows the shortcuts.', 'vehicle': 'Kawasaki Rouser', 'type': 'Motorcycle'},
    {'driver': 'Benji Zoom', 'user': 'Eva Green', 'rating': 4, 'comment': 'Smooth ride, nice motorcycle.', 'vehicle': 'Vespa Primavera', 'type': 'Motorcycle'},
    
    // Taxis (5)
    {'driver': 'Robert Driver', 'user': 'Jane Doe', 'rating': 3, 'comment': 'Comfortable car but took the long route.', 'vehicle': 'Toyota Vios', 'type': 'Taxi'},
    {'driver': 'Sally Cab', 'user': 'Bob Johnson', 'rating': 3, 'comment': 'A bit slow, but arrival was on time.', 'vehicle': 'Hyundai Accent', 'type': 'Taxi'},
    {'driver': 'Carlo Sedan', 'user': 'Fiona Gallagher', 'rating': 5, 'comment': 'Very clean car and polite driver.', 'vehicle': 'Nissan Almera', 'type': 'Taxi'},
    {'driver': 'Dina Drive', 'user': 'George Costanza', 'rating': 2, 'comment': 'Car smelled a bit weird.', 'vehicle': 'Mitsubishi Mirage', 'type': 'Taxi'},
    {'driver': 'Tony Wheels', 'user': 'Hannah Abbott', 'rating': 4, 'comment': 'Great trip, relaxing music.', 'vehicle': 'Kia Soluto', 'type': 'Taxi'},
  ];

  List<Map<String, dynamic>> _filteredRatings = [];

  @override
  void initState() {
    super.initState();
    _filteredRatings = _allRatings;
  }

  String _selectedType = 'All';

  /// Filters the ratings list based on the user's search query and selected vehicle type.
  void _filterRatings([String? query]) {
    final searchQuery = query ?? _searchController.text;
    setState(() {
      _filteredRatings = _allRatings.where((r) {
        final matchesSearch = r['driver'].toLowerCase().contains(searchQuery.toLowerCase()) ||
            r['user'].toLowerCase().contains(searchQuery.toLowerCase()) ||
            r['vehicle'].toLowerCase().contains(searchQuery.toLowerCase());
        
        final matchesType = _selectedType == 'All' || r['type'] == _selectedType;
        
        return matchesSearch && matchesType;
      }).toList();
    });
  }

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
                      _filterRatings();
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
            onChanged: _filterRatings,
            decoration: InputDecoration(
              hintText: 'Search by Driver, User, or Vehicle...',
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
            itemCount: _filteredRatings.length,
            itemBuilder: (context, index) {
              final rating = _filteredRatings[index];
              final int ratingValue = rating['rating'] as int;
              final Color ratingColor = ratingValue > 3
                  ? Colors.green
                  : (ratingValue == 3 ? Colors.amber : Colors.red);

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 4,
                shadowColor: Colors.black12,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border(
                        left: BorderSide(
                          color: ratingColor,
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
                            Text(
                              rating['driver'],
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 17,
                                color: Color(0xFF1E3A8A),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: ratingColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.star,
                                    color: ratingColor,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    ratingValue.toString(),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: ratingColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.person_outline,
                              size: 14,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${rating['user']}',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '•',
                              style: TextStyle(color: Colors.grey.shade400),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.directions_car_outlined,
                              size: 14,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${rating['vehicle']}',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 24, thickness: 0.5),
                        Text(
                          '"${rating['comment']}"',
                          style: TextStyle(
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                            color: Colors.grey.shade800,
                            height: 1.4,
                          ),
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

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
    {
      'driver': 'Lito Fast',
      'user': 'Rob Martin',
      'rating': 5,
      'comment': 'Awesome ride! Very fast and safe.',
      'vehicle': 'Honda Click',
    },
    {
      'driver': 'Robert Driver',
      'user': 'Jane Doe',
      'rating': 4,
      'comment': 'Comfortable car and clean interior.',
      'vehicle': 'Toyota Vios',
    },
    {
      'driver': 'Maria Rider',
      'user': 'Alice Smith',
      'rating': 5,
      'comment': 'Very professional and safe driving.',
      'vehicle': 'Yamaha NMAX',
    },
    {
      'driver': 'Sally Cab',
      'user': 'Bob Johnson',
      'rating': 3,
      'comment': 'A bit slow, but arrival was on time.',
      'vehicle': 'Hyundai Accent',
    },
    {
      'driver': 'Jun Moto',
      'user': 'Charlie Brown',
      'rating': 5,
      'comment': 'Great conversation and very polite.',
      'vehicle': 'Suzuki Burgman',
    },
  ];

  List<Map<String, dynamic>> _filteredRatings = [];

  @override
  void initState() {
    super.initState();
    _filteredRatings = _allRatings;
  }

  /// Filters the ratings list based on the user's search query.
  /// Matches the query against the driver name, user name, and vehicle type.
  void _filterRatings(String query) {
    setState(() {
      _filteredRatings = _allRatings
          .where(
            (r) =>
                r['driver'].toLowerCase().contains(query.toLowerCase()) ||
                r['user'].toLowerCase().contains(query.toLowerCase()) ||
                r['vehicle'].toLowerCase().contains(query.toLowerCase()),
          )
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
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

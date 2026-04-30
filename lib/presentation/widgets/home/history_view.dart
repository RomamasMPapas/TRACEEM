import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

/// A view showing the user's recent ride history.
/// Allows re-booking a ride by clicking on a history item.
class HistoryView extends StatelessWidget {
  final Function(String, LatLng, String, LatLng) onRebook;

  const HistoryView({super.key, required this.onRebook});

  @override
  Widget build(BuildContext context) {
    // Mock history data (matching the structure in BookView)
    final List<Map<String, dynamic>> rideHistory = [
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

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.only(top: 50, left: 20, right: 20, bottom: 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1E3A8A), Color(0xFF4C8CFF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: const Row(
              children: [
                Icon(Icons.history, color: Colors.white, size: 28),
                SizedBox(width: 15),
                Text(
                  'Ride History',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(15),
              itemCount: rideHistory.length,
              itemBuilder: (context, index) {
                final ride = rideHistory[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  elevation: 4,
                  shadowColor: Colors.black12,
                  child: InkWell(
                    onTap: () => onRebook(
                      ride['fromName'],
                      ride['fromCoords'],
                      ride['toName'],
                      ride['toCoords'],
                    ),
                    borderRadius: BorderRadius.circular(15),
                    child: Padding(
                      padding: const EdgeInsets.all(15),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.my_location, color: Colors.blue, size: 18),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  ride['fromName'],
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                ride['date'],
                                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                              ),
                            ],
                          ),
                          const Padding(
                            padding: EdgeInsets.only(left: 8.0),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Icon(Icons.more_vert, color: Colors.grey, size: 16),
                            ),
                          ),
                          Row(
                            children: [
                              const Icon(Icons.location_on, color: Colors.red, size: 18),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  ride['toName'],
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.blue),
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
      ),
    );
  }
}

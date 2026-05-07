import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


/// A page for administrators to manage drivers.
/// Displays driver ratings, feedback, ride history, and allows firing drivers.
class DriversPage extends StatefulWidget {
  const DriversPage({super.key});

  @override
  State<DriversPage> createState() => _DriversPageState();
}

class _DriversPageState extends State<DriversPage> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedType = 'All';

  // Base mock drivers - we will update their stats from Firestore
  final List<Map<String, dynamic>> _allDrivers = [
    {'id': 'd1', 'name': 'Lito Fast', 'vehicle': 'Honda Click', 'plateNumber': 'ABC 123', 'totalRating': 4.8, 'status': 'Active', 'type': 'Motorcycle', 'rides': []},
    {'id': 'd3', 'name': 'Maria Rider', 'vehicle': 'Yamaha NMAX', 'plateNumber': 'XYZ 123', 'totalRating': 4.9, 'status': 'Active', 'type': 'Motorcycle', 'rides': []},
    {'id': 'd5', 'name': 'Jun Moto', 'vehicle': 'Suzuki Burgman', 'plateNumber': 'QWE 456', 'totalRating': 2.5, 'status': 'Active', 'type': 'Motorcycle', 'rides': []},
    {'id': 'd6', 'name': 'Kiko Wheels', 'vehicle': 'Kawasaki Rouser', 'plateNumber': 'RTY 789', 'totalRating': 4.2, 'status': 'Active', 'type': 'Motorcycle', 'rides': []},
    {'id': 'd7', 'name': 'Benji Zoom', 'vehicle': 'Vespa Primavera', 'plateNumber': 'UIO 012', 'totalRating': 3.8, 'status': 'Active', 'type': 'Motorcycle', 'rides': []},
    {'id': 'd2', 'name': 'Robert Driver', 'vehicle': 'Toyota Vios', 'plateNumber': 'XYZ 987', 'totalRating': 3.0, 'status': 'Active', 'type': 'Taxi', 'rides': []},
    {'id': 'd4', 'name': 'Sally Cab', 'vehicle': 'Hyundai Accent', 'plateNumber': 'ASD 345', 'totalRating': 3.5, 'status': 'Active', 'type': 'Taxi', 'rides': []},
    {'id': 'd8', 'name': 'Carlo Sedan', 'vehicle': 'Nissan Almera', 'plateNumber': 'FGH 678', 'totalRating': 4.5, 'status': 'Active', 'type': 'Taxi', 'rides': []},
    {'id': 'd9', 'name': 'Dina Drive', 'vehicle': 'Mitsubishi Mirage', 'plateNumber': 'JKL 901', 'totalRating': 2.8, 'status': 'Active', 'type': 'Taxi', 'rides': []},
    {'id': 'd10', 'name': 'Tony Wheels', 'vehicle': 'Kia Soluto', 'plateNumber': 'ZXC 234', 'totalRating': 4.0, 'status': 'Active', 'type': 'Taxi', 'rides': []},
  ];

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('ratings').snapshots(),
      builder: (context, ratingsSnapshot) {
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('receipts').snapshots(),
          builder: (context, receiptsSnapshot) {
            if (ratingsSnapshot.connectionState == ConnectionState.waiting ||
                receiptsSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final realRatings = ratingsSnapshot.data?.docs ?? [];
            final realReceipts = receiptsSnapshot.data?.docs ?? [];

            // Update driver stats based on real data
            final updatedDrivers = _allDrivers.map((driver) {
              final driverName = driver['name'];
              
              // Filter real data for this driver
              final driverRatingsData = realRatings.where((doc) => (doc.data() as Map<String, dynamic>)['driver'] == driverName).toList();
              final driverReceiptsData = realReceipts.where((doc) => (doc.data() as Map<String, dynamic>)['driver'] == driverName).toList();

              // History list
              List<Map<String, dynamic>> history = [];
              for (var doc in driverRatingsData) {
                final data = doc.data() as Map<String, dynamic>;
                history.add({
                  'date': (data['timestamp'] as Timestamp?)?.toDate().toString().split(' ')[0] ?? '2026-05-02',
                  'user': data['user'] ?? 'Anonymous',
                  'rating': data['rating'] ?? 0,
                  'feedback': data['comment'] ?? '',
                  'fare': '₱0' // Will update from receipt if found
                });
              }

              // Match fares from receipts — safely handle empty lists (web safe)
              if (driverReceiptsData.isNotEmpty) {
                for (var i = 0; i < history.length; i++) {
                  final match = driverReceiptsData.cast<dynamic>().firstWhere(
                    (r) {
                      final d = r.data() as Map<String, dynamic>?;
                      return d != null && d['user'] == history[i]['user'];
                    },
                    orElse: () => null,
                  );
                  if (match != null) {
                    final matchData = match.data() as Map<String, dynamic>?;
                    history[i]['fare'] = '₱${(matchData?['amount'] as num?)?.toStringAsFixed(0) ?? '0'}';
                  }
                }
              }

              // Update aggregate rating
              double totalRating = driver['totalRating'];
              if (driverRatingsData.isNotEmpty) {
                double sum = driverRatingsData.fold(0, (prev, doc) => prev + ((doc.data() as Map<String, dynamic>)['rating'] as num).toDouble());
                totalRating = sum / driverRatingsData.length;
              }

              return {
                ...driver,
                'rides': history,
                'totalRating': totalRating,
              };
            }).toList();

            // Filter for search and tabs
            final searchQuery = _searchController.text.toLowerCase();
            final filtered = updatedDrivers.where((d) {
              final matchesSearch = d['name'].toLowerCase().contains(searchQuery) ||
                  d['vehicle'].toLowerCase().contains(searchQuery);
              final matchesType = _selectedType == 'All' || d['type'] == _selectedType;
              return matchesSearch && matchesType;
            }).toList();

            return Column(
              children: [
                _buildHeader(),
                _buildFilterTabs(),
                Expanded(
                  child: filtered.isEmpty
                      ? const Center(child: Text('No drivers found.'))
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) => _buildDriverCard(filtered[index]),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        children: [
          const Text(
            'Driver Management',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
          ),
          const Spacer(),
          Container(
            width: 300,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search by name or vehicle...',
                prefixIcon: Icon(Icons.search, color: Color(0xFF4C8CFF)),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 15),
              ),
              onChanged: (v) => setState(() {}),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: ['All', 'Motorcycle', 'Taxi'].map((type) {
          final isSelected = _selectedType == type;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedType = type),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF4C8CFF) : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: isSelected ? [BoxShadow(color: Colors.blue.withValues(alpha: 0.2), blurRadius: 8)] : null,
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
    );
  }

  Widget _buildDriverCard(Map<String, dynamic> driver) {
    final double rating = driver['totalRating'];
    final Color ratingColor = rating >= 4 ? Colors.green : (rating >= 3 ? Colors.amber : Colors.red);
    final bool isFired = driver['status'] == 'Fired';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Container(
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: isFired ? Colors.grey : ratingColor, width: 6)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.blue.shade50,
                    child: Text(driver['name'][0], style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A), fontSize: 20)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(driver['name'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
                        Text('${driver['vehicle']} • ${driver['plateNumber']}', style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(color: ratingColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      children: [
                        Icon(Icons.star, color: ratingColor, size: 18),
                        const SizedBox(width: 4),
                        Text(rating.toStringAsFixed(1), style: TextStyle(fontWeight: FontWeight.bold, color: ratingColor, fontSize: 16)),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 32),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showDriverDetails(driver),
                      icon: const Icon(Icons.analytics_outlined, size: 18),
                      label: const Text('Driver Stats & History'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (!isFired)
                    ElevatedButton.icon(
                      onPressed: () => _fireDriver(driver['id'], driver['name']),
                      icon: const Icon(Icons.person_off, size: 18),
                      label: const Text('FIRE'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _fireDriver(String id, String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Termination'),
        content: Text('Are you sure you want to fire $name? This action will revoke their access to the platform.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () {
              setState(() {
                final idx = _allDrivers.indexWhere((d) => d['id'] == id);
                if (idx != -1) _allDrivers[idx]['status'] = 'Fired';
              });
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('FIRE DRIVER'),
          ),
        ],
      ),
    );
  }

  void _showDriverDetails(Map<String, dynamic> driver) {
    final rides = driver['rides'] as List;
    double totalEarned = 0;
    for (var r in rides) {
      totalEarned += double.tryParse(r['fare'].toString().replaceAll('₱', '')) ?? 0;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)))),
            const SizedBox(height: 24),
            Text('${driver['name']} Analytics', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Row(
              children: [
                _statCard('Total Rides', rides.length.toString(), Icons.route, Colors.blue),
                const SizedBox(width: 16),
                _statCard('Total Earnings', '₱${totalEarned.toStringAsFixed(0)}', Icons.payments, Colors.green),
              ],
            ),
            const SizedBox(height: 32),
            const Text('Recent Feedback', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Expanded(
              child: rides.isEmpty
                  ? const Center(child: Text('No ride history found.'))
                  : ListView.builder(
                      itemCount: rides.length,
                      itemBuilder: (context, index) {
                        final ride = rides[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(ride['user'], style: const TextStyle(fontWeight: FontWeight.bold)),
                                  Text(ride['date'], style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: List.generate(5, (i) => Icon(Icons.star, size: 14, color: i < (ride['rating'] as int) ? Colors.amber : Colors.grey.shade300)),
                              ),
                              if (ride['feedback'].isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text('"${ride['feedback']}"', style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 13)),
                              ]
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16), border: Border.all(color: color.withValues(alpha: 0.2))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 12),
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

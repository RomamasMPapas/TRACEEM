import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// A page for administrators to view and search ride receipts and transaction logs.
/// Allows monitoring of revenue, ride types, and specific user/order details.
class ReceiptsPage extends StatefulWidget {
  const ReceiptsPage({super.key});

  @override
  State<ReceiptsPage> createState() => _ReceiptsPageState();
}

/// The [_ReceiptsPageState] class is responsible for managing its respective UI components and state.
class _ReceiptsPageState extends State<ReceiptsPage> {
  final TextEditingController _searchController = TextEditingController();
  final List<Map<String, dynamic>> _mockReceipts = [
    {
      'orderId': '#TEM-2026-X8',
      'user': 'Rob Martin',
      'date': DateTime.now().subtract(const Duration(hours: 2)),
      'amount': 150.0,
      'type': 'Motorcycle',
      'route': 'IT Park to Parkmall',
    },
    {
      'orderId': '#TEM-2026-X9',
      'user': 'Jane Doe',
      'date': DateTime.now().subtract(const Duration(hours: 5)),
      'amount': 450.0,
      'type': 'Taxi',
      'route': 'SM City to Airport',
    },
    {
      'orderId': '#TEM-2026-Y1',
      'user': 'Alice Smith',
      'date': DateTime.now().subtract(const Duration(days: 1)),
      'amount': 120.0,
      'type': 'Motorcycle',
      'route': 'Ayala to Colon',
    },
    {
      'orderId': '#TEM-2026-Y2',
      'user': 'Bob Johnson',
      'date': DateTime.now().subtract(const Duration(days: 1, hours: 3)),
      'amount': 380.0,
      'type': 'Taxi',
      'route': 'Fuente to Talisay',
    },
  ];

  String _selectedType = 'All';

  /// Triggers a rebuild to apply the current search and type filters.
  void _filterReceipts([String? query]) {
    setState(() {});
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
                      _filterReceipts();
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color:
                          isSelected ? const Color(0xFF4C8CFF) : Colors.transparent,
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
            onChanged: _filterReceipts,
            decoration: InputDecoration(
              hintText: 'Search by Order ID, User, or Vehicle...',
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
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('receipts')
                .orderBy('date', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              // Combine Firestore data with mock data for a full view
              final firestoreDocs = snapshot.data!.docs;
              final List<Map<String, dynamic>> firestoreReceipts = firestoreDocs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return {
                  'orderId': data['orderId'] ?? 'Unknown',
                  'user': data['user'] ?? 'Anonymous',
                  'date': (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
                  'amount': (data['amount'] as num?)?.toDouble() ?? 0.0,
                  'type': data['type'] ?? 'Motorcycle',
                  'route': data['route'] ?? 'Unknown route',
                };
              }).toList();

              final allReceipts = [...firestoreReceipts, ..._mockReceipts];
              
              // Apply filters
              final searchQuery = _searchController.text.toLowerCase();
              final filtered = allReceipts.where((r) {
                final matchesSearch =
                    r['orderId'].toLowerCase().contains(searchQuery) ||
                    r['user'].toLowerCase().contains(searchQuery) ||
                    r['type'].toLowerCase().contains(searchQuery);

                final matchesType = _selectedType == 'All' || r['type'] == _selectedType;

                return matchesSearch && matchesType;
              }).toList();

              if (filtered.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.receipt_long, size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text('No receipts found', style: TextStyle(color: Colors.grey.shade500)),
                    ],
                  ),
                );
              }

              return ListView.builder(
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final receipt = filtered[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    elevation: 4,
                    shadowColor: Colors.black12,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        leading: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: receipt['type'] == 'Motorcycle'
                                  ? [Colors.orange.shade300, Colors.orange.shade600]
                                  : [Colors.blue.shade300, Colors.blue.shade600],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: (receipt['type'] == 'Motorcycle'
                                        ? Colors.orange
                                        : Colors.blue)
                                    .withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(
                            receipt['type'] == 'Motorcycle'
                                ? Icons.two_wheeler
                                : Icons.local_taxi,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              receipt['orderId'],
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF1E3A8A),
                              ),
                            ),
                            Text(
                              '₱${receipt['amount'].toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.w900,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(Icons.person, size: 14, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text(
                                  '${receipt['user']}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                const Icon(Icons.map, size: 14, color: Colors.grey),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    '${receipt['route']}',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 12,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              DateFormat('MMM dd, yyyy • HH:mm').format(receipt['date']),
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade500,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

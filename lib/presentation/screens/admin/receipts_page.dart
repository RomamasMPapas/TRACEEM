import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
  final List<Map<String, dynamic>> _allReceipts = [
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

  List<Map<String, dynamic>> _filteredReceipts = [];

  /// Initializes the state of the widget before it is built.
  @override
  void initState() {
    super.initState();
    _filteredReceipts = _allReceipts;
  }

  /// Filters the receipts list based on the user's search query.
  /// Matches the query against the order ID, user name, and vehicle type.
  void _filterReceipts(String query) {
    setState(() {
      _filteredReceipts = _allReceipts
          .where((r) =>
              r['orderId'].toLowerCase().contains(query.toLowerCase()) ||
              r['user'].toLowerCase().contains(query.toLowerCase()) ||
              r['type'].toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  /// Builds the visual structure of this widget, returning the widget tree.
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
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
          child: ListView.builder(
            itemCount: _filteredReceipts.length,
            itemBuilder: (context, index) {
              final receipt = _filteredReceipts[index];
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
          ),
        ),
      ],
    );
  }
}

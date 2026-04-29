import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

/// Admin page that displays all registered users in a data table streamed from Firestore.
/// Shows their username, email, region, role, online status, and allows quick order creation.
/// The [UsersPage] class is responsible for managing its respective UI components and state.
class UsersPage extends StatelessWidget {
  const UsersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: Row(
            children: [
              const Text(
                'Registered Users',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4C8CFF),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('users').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text('No users found.'));
              }

              final users = snapshot.data!.docs;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minWidth: MediaQuery.of(context).size.width - 350,
                      ),
                      child: DataTable(
                        headingRowColor: WidgetStateProperty.all(
                          Colors.grey[100],
                        ),
                        columns: const [
                          DataColumn(label: Text('USERNAME')),
                          DataColumn(label: Text('EMAIL')),
                          DataColumn(label: Text('REGION')),
                          DataColumn(label: Text('ROLE')),
                          DataColumn(label: Text('STATUS')),
                          DataColumn(label: Text('ACTIONS')),
                        ],
                        rows: users.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final userId = doc.id;
                          final role = data['role'] ?? 'user';
                          final isOnline = data['isOnline'] ?? false;

                          return DataRow(
                            cells: [
                              DataCell(
                                Text(
                                  data['username'] ?? 'N/A',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              DataCell(Text(data['email'] ?? 'N/A')),
                              DataCell(Text(data['region'] ?? 'Region 7')),
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: role == 'admin'
                                        ? Colors.purple[100]
                                        : Colors.blue[100],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    role.toString().toUpperCase(),
                                    style: TextStyle(
                                      color: role == 'admin'
                                          ? Colors.purple[900]
                                          : Colors.blue[900],
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              DataCell(
                                Row(
                                  children: [
                                    Container(
                                      width: 10,
                                      height: 10,
                                      decoration: BoxDecoration(
                                        color: isOnline
                                            ? Colors.green
                                            : Colors.grey,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(isOnline ? 'Online' : 'Offline'),
                                  ],
                                ),
                              ),
                              DataCell(
                                ElevatedButton.icon(
                                  onPressed: () =>
                                      _createQuickOrder(context, userId),
                                  icon: const Icon(
                                    Icons.add_shopping_cart,
                                    size: 14,
                                  ),
                                  label: const Text(
                                    'SEND ORDER',
                                    style: TextStyle(fontSize: 11),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
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

  /// Creates a quick test order in Firestore assigned to [userId] starting from IT Park, Cebu.
  /// Shows a success or error snack bar after the operation.
  /// Asynchronously executes the logic for _createQuickOrder.
  Future<void> _createQuickOrder(BuildContext context, String userId) async {
    final random = Random();
    final orderNum =
        'ORD-${random.nextInt(1000000).toString().padLeft(6, '0')}';

    // Default start coords: IT Park, Cebu
    const startLat = 10.3297;
    const startLng = 123.9061;

    try {
      await FirebaseFirestore.instance.collection('orders').add({
        'userId': userId,
        'orderNumber': orderNum,
        'status': 'Preparing',
        'progress': 0.1,
        'date': FieldValue.serverTimestamp(),
        'region': 'Region 7',
        'driverLocation': [startLat, startLng],
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Test Order $orderNum sent to User!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}

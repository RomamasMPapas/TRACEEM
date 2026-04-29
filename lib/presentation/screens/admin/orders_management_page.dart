import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'dart:math';

/// Admin page that displays all orders in a data table streamed from Firestore.
/// Allows the admin to update order status/progress or delete orders.
/// The [OrdersManagementPage] class is responsible for managing its respective UI components and state.
class OrdersManagementPage extends StatelessWidget {
  const OrdersManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: Row(
            children: [
              const Text(
                'Order Management',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => _showCreateOrderDialog(context),
                icon: const Icon(Icons.add),
                label: const Text('CREATE TEST ORDER'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4C8CFF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('orders')
                .orderBy('date', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text('No orders found.'));
              }

              final orders = snapshot.data!.docs;

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
                          DataColumn(label: Text('ORDER #')),
                          DataColumn(label: Text('USER ID')),
                          DataColumn(label: Text('STATUS')),
                          DataColumn(label: Text('PROGRESS')),
                          DataColumn(label: Text('DATE')),
                          DataColumn(label: Text('ACTIONS')),
                        ],
                        rows: orders.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final docId = doc.id;
                          final progress = (data['progress'] ?? 0.0).toDouble();
                          final status = data['status'] ?? 'Pending';

                          return DataRow(
                            cells: [
                              DataCell(
                                Text(
                                  data['orderNumber'] ?? 'N/A',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  data['userId']?.toString().substring(0, 8) ??
                                      'N/A',
                                ),
                              ),
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.orange[50],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    status,
                                    style: TextStyle(
                                      color: Colors.orange[900],
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              DataCell(
                                SizedBox(
                                  width: 100,
                                  child: LinearProgressIndicator(
                                    value: progress,
                                    backgroundColor: Colors.grey[200],
                                    color: const Color(0xFF4C8CFF),
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  data['date'] != null
                                      ? DateFormat('MMM dd, HH:mm').format(
                                          (data['date'] as Timestamp).toDate(),
                                        )
                                      : '---',
                                ),
                              ),
                              DataCell(
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      tooltip: 'Update Status/Progress',
                                      icon: const Icon(
                                        Icons.edit,
                                        color: Color(0xFF4C8CFF),
                                      ),
                                      onPressed: () => _showUpdateDialog(
                                        context,
                                        docId,
                                        status,
                                        progress,
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: 'Delete Order',
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        color: Colors.red,
                                      ),
                                      onPressed: () => FirebaseFirestore
                                          .instance
                                          .collection('orders')
                                          .doc(docId)
                                          .delete(),
                                    ),
                                  ],
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

  /// Shows a dialog for the admin to update an order's status and delivery progress.
  void _showUpdateDialog(
    BuildContext context,
    String docId,
    String currentStatus,
    double currentProgress,
  ) {
    final statusList = [
      'Preparing',
      'Picked up',
      'On the way',
      'Arrived',
      'Delivered',
    ];
    String selectedStatus = currentStatus;
    double progressValue = currentProgress;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Manage Order Progress'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: statusList.contains(selectedStatus)
                    ? selectedStatus
                    : statusList[0],
                decoration: const InputDecoration(labelText: 'Order Status'),
                items: statusList
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (val) => setDialogState(() => selectedStatus = val!),
              ),
              const SizedBox(height: 25),
              Text('Progress: ${(progressValue * 100).toInt()}%'),
              Slider(
                value: progressValue,
                min: 0.0,
                max: 1.0,
                divisions: 10,
                activeColor: const Color(0xFF4C8CFF),
                onChanged: (val) => setDialogState(() => progressValue = val),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCEL'),
            ),
            ElevatedButton(
              onPressed: () async {
                await FirebaseFirestore.instance
                    .collection('orders')
                    .doc(docId)
                    .update({
                      'status': selectedStatus,
                      'progress': progressValue,
                    });
                if (context.mounted) Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4C8CFF),
                foregroundColor: Colors.white,
              ),
              child: const Text('UPDATE ORDER'),
            ),
          ],
        ),
      ),
    );
  }

  // ... (Original _showCreateOrderDialog and _createOrder logic remains same as requested)
  /// Shows a dialog for the admin to create a new test order assigned to a specific user ID.
  /// Executes the logic for _showCreateOrderDialog.
  void _showCreateOrderDialog(BuildContext context) {
    final userIdController = TextEditingController();
    final statusList = ['On the way', 'Preparing', 'Picked up', 'Delivered'];
    String selectedStatus = statusList[0];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Create Test Order'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: userIdController,
                decoration: const InputDecoration(
                  labelText: 'User ID (Target User)',
                  hintText: 'Paste User ID from Users tab',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: selectedStatus,
                decoration: const InputDecoration(
                  labelText: 'Initial Status',
                  border: OutlineInputBorder(),
                ),
                items: statusList.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setDialogState(() => selectedStatus = value);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCEL'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (userIdController.text.isNotEmpty) {
                  await _createOrder(userIdController.text, selectedStatus);
                  if (context.mounted) Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4C8CFF),
                foregroundColor: Colors.white,
              ),
              child: const Text('CREATE ORDER'),
            ),
          ],
        ),
      ),
    );
  }

  /// Creates a new order in Firestore for the given [userId] with a random order number.
  /// Asynchronously executes the logic for _createOrder.
  Future<void> _createOrder(String userId, String status) async {
    final random = Random();
    final orderNum =
        'ORD-${random.nextInt(1000000).toString().padLeft(6, '0')}';

    const startLat = 10.3297;
    const startLng = 123.9061;

    await FirebaseFirestore.instance.collection('orders').add({
      'userId': userId,
      'orderNumber': orderNum,
      'status': status,
      'progress': 0.1,
      'date': FieldValue.serverTimestamp(),
      'region': 'Region 7',
      'driverLocation': [startLat, startLng],
    });
  }
}

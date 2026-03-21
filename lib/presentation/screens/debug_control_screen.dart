import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// A developer-only screen for testing Firebase data directly.
/// Allows creating test orders, updating progress, and simulating live driver movement.
class DebugControlScreen extends StatefulWidget {
  const DebugControlScreen({super.key});

  @override
  State<DebugControlScreen> createState() => _DebugControlScreenState();
}

class _DebugControlScreenState extends State<DebugControlScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  Timer? _simulationTimer;
  bool _isSimulating = false;

  @override
  void dispose() {
    _simulationTimer?.cancel();
    super.dispose();
  }

  /// Creates a new test order in Firestore under the currently authenticated user.
  Future<void> _createTestOrder() async {
    final user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No user logged in')));
      return;
    }

    try {
      await _firestore.collection('orders').add({
        'userId': user.uid,
        'orderNumber': 'ORD-${DateTime.now().millisecondsSinceEpoch}',
        'status': 'Preparing',
        'progress': 0.1,
        'date': FieldValue.serverTimestamp(),
        'region': 'Region 7', // Default to Region 7 (Cebu)
        'driverLocation': const GeoPoint(10.3300, 123.9060), // Start at IT Park
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Test Order Created! Check "Track" tab'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  /// Increments an existing order's progress by 0.1 and updates its status label accordingly.
  /// Resets progress back to 0 if it exceeds 1.0.
  Future<void> _updateOrderProgress(
    String orderId,
    double currentProgress,
  ) async {
    double newProgress = currentProgress + 0.1;
    if (newProgress > 1.0) newProgress = 0.0;

    String status = 'In Transit';
    if (newProgress < 0.2) status = 'Preparing';
    if (newProgress > 0.9) status = 'Delivered';

    await _firestore.collection('orders').doc(orderId).update({
      'progress': newProgress,
      'status': status,
    });
  }

  /// Toggles a simulation timer that moves a driver marker between IT Park and Parkmall.
  /// Updates both Firestore and the FastAPI tracking server every 2 seconds.
  void _toggleSimulation(String orderId) {
    if (_isSimulating) {
      _simulationTimer?.cancel();
      setState(() => _isSimulating = false);
      return;
    }

    setState(() => _isSimulating = true);

    // Simulate movement from IT Park (10.33, 123.906) to Parkmall (10.325, 123.935)
    double progress = 0.0;
    const startLat = 10.3300;
    const startLng = 123.9060;
    const endLat = 10.3250;
    const endLng = 123.9350;

    _simulationTimer = Timer.periodic(const Duration(seconds: 2), (
      timer,
    ) async {
      progress += 0.05;
      if (progress > 1.0) progress = 0.0;

      final newLat = startLat + (endLat - startLat) * progress;
      final newLng = startLng + (endLng - startLng) * progress;

      // 1. Update Firestore (for existing UI)
      await _firestore.collection('orders').doc(orderId).update({
        'progress': progress,
        'driverLocation': GeoPoint(newLat, newLng),
        'status': progress > 0.9 ? 'Arriving' : 'On the way',
      });

      // 2. Update FastAPI (for real-time tracking demonstration)
      try {
        final String baseUrl = kIsWeb
            ? 'http://localhost:8000'
            : 'http://10.0.2.2:8000';

        await http.post(
          Uri.parse('$baseUrl/track'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'user_id': 'user_123',
            'latitude': newLat,
            'longitude': newLng,
            'region': 'Region 7', // Include region in tracking data
          }),
        );
      } catch (e) {
        debugPrint('Failed to sync with FastAPI: $e');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('🔥 Firebase Debug Console')),
      body: user == null
          ? const Center(child: Text('Please log in first'))
          : StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('orders')
                  .where('userId', isEqualTo: user.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final orders = snapshot.data!.docs;

                return ListView(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: ElevatedButton.icon(
                        onPressed: _createTestOrder,
                        icon: const Icon(Icons.add),
                        label: const Text('Create New Test Order'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.all(16),
                        ),
                      ),
                    ),
                    const Divider(),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Active Orders (Tap to update)',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    ...orders.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final progress = (data['progress'] ?? 0.0).toDouble();
                      final status = data['status'] ?? 'Unknown';

                      return Card(
                        margin: const EdgeInsets.all(8),
                        child: ListTile(
                          title: Text(data['orderNumber']),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Status: $status'),
                              LinearProgressIndicator(value: progress),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.update),
                                onPressed: () =>
                                    _updateOrderProgress(doc.id, progress),
                                tooltip: 'Increment Progress',
                              ),
                              IconButton(
                                icon: Icon(
                                  _isSimulating
                                      ? Icons.stop_circle
                                      : Icons.play_circle,
                                  color: _isSimulating
                                      ? Colors.red
                                      : Colors.blue,
                                ),
                                onPressed: () => _toggleSimulation(doc.id),
                                tooltip: 'Simulate Driver Movement',
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.grey,
                                ),
                                onPressed: () => _firestore
                                    .collection('orders')
                                    .doc(doc.id)
                                    .delete(),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                );
              },
            ),
    );
  }
}

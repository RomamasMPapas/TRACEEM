import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../domain/entities/user_entity.dart';

/// A view widget that displays a mixed list of static and dynamic (Firestore) notifications.
/// Dynamic entries show resolved complaint responses; static entries show welcome and promo messages.
class NotificationsView extends StatelessWidget {
  final UserEntity user;
  final VoidCallback onReportPressed;

  const NotificationsView({super.key, required this.user, required this.onReportPressed});

  /// Shows a full-detail dialog for an individual notification item.
  void _showNotificationDetail(
    BuildContext context,
    String title,
    String content,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        content: Text(
          content,
          style: const TextStyle(fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'GOT IT',
              style: TextStyle(
                color: Color(0xFF4C8CFF),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Column(
        children: [
          // Header
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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.notifications_active, color: Colors.white, size: 28),
                    SizedBox(width: 15),
                    Text(
                      'Notifications',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                // Report Button integrated here
                ElevatedButton.icon(
                  onPressed: onReportPressed,
                  icon: const Icon(Icons.report_problem, size: 16, color: Color(0xFF4C8CFF)),
                  label: const Text('REPORT', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF4C8CFF))),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                ),
              ],
            ),
          ),
          // Notifications List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('complaints')
                  .where('userId', isEqualTo: user.id)
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                List<Widget> items = [];

                // 1. ALWAYS ADD STATIC ITEMS FIRST
                items.add(
                  _buildStaticItem(
                    context,
                    'Welcome to TRACE EM!',
                    'Greetings for new user...',
                    'Just now',
                    Icons.star,
                    Colors.amber,
                    'Hello new user suffer with us',
                  ),
                );

                items.add(
                  _buildStaticItem(
                    context,
                    'Order Picked Up',
                    'Your order #ORD-082291 has been picked up.',
                    'Just now',
                    Icons.local_shipping,
                    Colors.blue,
                    'Your rider has arrived at the pickup location and is now heading to the destination.',
                  ),
                );

                // 2. ADD DYNAMIC ITEMS
                if (snapshot.hasData) {
                  for (var doc in snapshot.data!.docs) {
                    final data = doc.data() as Map<String, dynamic>;
                    final status = data['status']?.toString().toLowerCase() ?? 'pending';
                    final response = data['response'];
                    final timestamp = data['createdAt'] as Timestamp?;
                    final date = timestamp?.toDate() ?? DateTime.now();

                    if (status == 'resolved' && response != null) {
                      items.add(
                        _buildAdminResponseItem(
                          context,
                          'Report Resolved',
                          'Admin says: "$response"',
                          DateFormat('MMM dd, HH:mm').format(date),
                          response,
                        ),
                      );
                    }
                  }
                }

                return ListView.separated(
                  itemCount: items.length,
                  padding: const EdgeInsets.all(10),
                  separatorBuilder: (context, index) => const SizedBox(height: 10),
                  itemBuilder: (context, index) => items[index],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStaticItem(BuildContext context, String title, String msg, String time, IconData icon, Color color, String fullDetail) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        onTap: () => _showNotificationDetail(context, title, fullDetail),
        leading: CircleAvatar(backgroundColor: color.withValues(alpha: 0.1), child: Icon(icon, color: color, size: 20)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text(msg, style: const TextStyle(fontSize: 12)),
        trailing: Text(time, style: const TextStyle(color: Colors.grey, fontSize: 10)),
      ),
    );
  }

  Widget _buildAdminResponseItem(BuildContext context, String title, String responseShort, String time, String fullResponse) {
    return Card(
      color: Colors.green.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        onTap: () => _showNotificationDetail(context, title, fullResponse),
        leading: const CircleAvatar(backgroundColor: Colors.green, child: Icon(Icons.mark_chat_read, color: Colors.white, size: 20)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.green)),
        subtitle: Text(responseShort, style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
        trailing: Text(time, style: const TextStyle(color: Colors.grey, fontSize: 10)),
      ),
    );
  }
}

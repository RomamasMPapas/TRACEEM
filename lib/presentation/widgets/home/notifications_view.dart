import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../domain/entities/user_entity.dart';

/// A dialog widget that displays a mixed list of static and dynamic (Firestore) notifications.
/// Dynamic entries show resolved complaint responses; static entries show welcome and promo messages.
class NotificationsDialog extends StatelessWidget {
  final UserEntity user;

  const NotificationsDialog({super.key, required this.user});

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
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.notifications_active,
                        color: Color(0xFF4C8CFF),
                      ),
                      SizedBox(width: 10),
                      Text(
                        'Notifications',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Notifications List
            Flexible(
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
                      'Your rider has arrived at the pickup location and is now heading to the destination. You can track their real-time progress on the Track tab.',
                    ),
                  );

                  // 2. ADD DYNAMIC ITEMS OR ERROR/LOADING
                  if (snapshot.hasError) {
                    items.add(
                      Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: SelectableText(
                          'Error (Need Index): Copy this link to fix it in Firebase Console:\n\n${snapshot.error}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    );
                  } else if (snapshot.connectionState ==
                          ConnectionState.waiting &&
                      !snapshot.hasData) {
                    items.add(
                      const Padding(
                        padding: EdgeInsets.all(20.0),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    );
                  } else if (snapshot.hasData) {
                    for (var doc in snapshot.data!.docs) {
                      final data = doc.data() as Map<String, dynamic>;
                      final status =
                          data['status']?.toString().toLowerCase() ?? 'pending';
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

                  // 3. Promotion (BOTTOM)
                  items.add(
                    _buildStaticItem(
                      context,
                      'New Promotion!',
                      'Get 20% off with code TRACE20',
                      '1 hour ago',
                      Icons.sell,
                      Colors.orange,
                      'Limited time offer! Use the promo code TRACE20 on your next booking to enjoy a 20% discount. Valid for the first 100 users only!',
                    ),
                  );

                  return ListView.separated(
                    shrinkWrap: true,
                    itemCount: items.length,
                    padding: EdgeInsets.zero,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1),
                    itemBuilder: (context, index) => items[index],
                  );
                },
              ),
            ),
            // Footer
            Padding(
              padding: const EdgeInsets.all(15.0),
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'MARK ALL AS READ',
                  style: TextStyle(
                    color: Color(0xFF4C8CFF),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds a static notification list tile (e.g. welcome or promotion) that opens a detail dialog on tap.
  Widget _buildStaticItem(
    BuildContext context,
    String title,
    String msg,
    String time,
    IconData icon,
    Color color,
    String fullDetail,
  ) {
    return ListTile(
      onTap: () => _showNotificationDetail(context, title, fullDetail),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(
            msg,
            style: TextStyle(
              color: Colors.black.withValues(alpha: 0.7),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 6),
          Text(time, style: const TextStyle(color: Colors.grey, fontSize: 10)),
        ],
      ),
    );
  }

  /// Builds a dynamic notification tile for a resolved complaint with an admin response.
  Widget _buildAdminResponseItem(
    BuildContext context,
    String title,
    String responseShort,
    String time,
    String fullResponse,
  ) {
    return ListTile(
      onTap: () => _showNotificationDetail(context, title, fullResponse),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      tileColor: Colors.green.withValues(alpha: 0.05),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: const BoxDecoration(
          color: Colors.green,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.mark_chat_read, color: Colors.white, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
          color: Colors.green,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(
            responseShort,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 6),
          Text(time, style: const TextStyle(color: Colors.grey, fontSize: 10)),
        ],
      ),
    );
  }
}

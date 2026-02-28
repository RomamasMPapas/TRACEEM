import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ComplaintsPage extends StatelessWidget {
  const ComplaintsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: Row(
            children: [
              const Text(
                'Reports & Complaints',
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
            stream: FirebaseFirestore.instance
                .collection('complaints')
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text('No complaints found.'));
              }

              final complaints = snapshot.data!.docs;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: ListView.builder(
                  itemCount: complaints.length,
                  itemBuilder: (context, index) {
                    final data =
                        complaints[index].data() as Map<String, dynamic>;
                    final docId = complaints[index].id;
                    final date =
                        (data['createdAt'] as Timestamp?)?.toDate() ??
                        DateTime.now();
                    final status = data['status'] ?? 'pending';

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: ExpansionTile(
                        leading: CircleAvatar(
                          backgroundColor: status == 'resolved'
                              ? Colors.green[100]
                              : Colors.orange[100],
                          child: Icon(
                            status == 'resolved'
                                ? Icons.check
                                : Icons.warning_amber_rounded,
                            color: status == 'resolved'
                                ? Colors.green[900]
                                : Colors.orange[900],
                          ),
                        ),
                        title: Text(
                          data['userName'] ?? 'Unknown User',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          'Reported on ${DateFormat('MMM dd, yyyy HH:mm').format(date)}',
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: status == 'resolved'
                                ? Colors.green[100]
                                : Colors.orange[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            status.toString().toUpperCase(),
                            style: TextStyle(
                              color: status == 'resolved'
                                  ? Colors.green[900]
                                  : Colors.orange[900],
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'DESCRIPTION:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  data['description'] ??
                                      'No description provided.',
                                ),
                                const Divider(height: 32),
                                if (data['response'] != null) ...[
                                  const Text(
                                    'ADMIN RESPONSE:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: Colors.blue,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(data['response']),
                                  const SizedBox(height: 16),
                                ],
                                if (status == 'pending')
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      TextButton(
                                        onPressed: () =>
                                            _showResponseDialog(context, docId),
                                        child: const Text('RESPOND'),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showResponseDialog(BuildContext context, String docId) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Respond to Complaint'),
        content: TextField(
          controller: controller,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Enter your response here...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                await FirebaseFirestore.instance
                    .collection('complaints')
                    .doc(docId)
                    .update({
                      'response': controller.text,
                      'status': 'resolved',
                      'respondedAt': FieldValue.serverTimestamp(),
                    });
                if (context.mounted) Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4C8CFF),
              foregroundColor: Colors.white,
            ),
            child: const Text('SUBMIT RESPONSE'),
          ),
        ],
      ),
    );
  }
}

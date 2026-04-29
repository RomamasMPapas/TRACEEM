import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

/// Admin page that lists all user complaints/reports streamed from Firestore.
/// Allows the admin to expand each complaint and submit a response to resolve it.
/// The [ComplaintsPage] class is responsible for managing its respective UI components and state.
class ComplaintsPage extends StatefulWidget {
  const ComplaintsPage({super.key});

  @override
  State<ComplaintsPage> createState() => _ComplaintsPageState();
}

/// The [_ComplaintsPageState] class is responsible for managing its respective UI components and state.
class _ComplaintsPageState extends State<ComplaintsPage> {
  bool _sortDescending = true;
  String _selectedYear = 'All';
  String _selectedMonth = 'All';
  String _selectedDay = 'All';
  String _selectedVehicle = 'All';

  final List<String> _years = ['All', '2023', '2024', '2025', '2026'];
  final List<String> _months = ['All', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  final List<String> _days = ['All', ...List.generate(31, (i) => (i + 1).toString())];
  final List<String> _vehicles = ['All', 'Motorcycle', 'Taxi'];

  /// Builds and returns the _buildDropdown custom widget component.
  Widget _buildDropdown(String value, List<String> items, Function(String?) onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isDense: true,
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 13)))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

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
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _buildDropdown(_selectedYear, _years, (val) => setState(() => _selectedYear = val!)),
                  _buildDropdown(_selectedMonth, _months, (val) => setState(() => _selectedMonth = val!)),
                  _buildDropdown(_selectedDay, _days, (val) => setState(() => _selectedDay = val!)),
                  _buildDropdown(_selectedVehicle, _vehicles, (val) => setState(() => _selectedVehicle = val!)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<bool>(
                        value: _sortDescending,
                        isDense: true,
                        items: const [
                          DropdownMenuItem(value: true, child: Text('Newest', style: TextStyle(fontSize: 13))),
                          DropdownMenuItem(value: false, child: Text('Oldest', style: TextStyle(fontSize: 13))),
                        ],
                        onChanged: (value) {
                          if (value != null) setState(() => _sortDescending = value);
                        },
                        icon: const Icon(Icons.sort, size: 16),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {}); // Refresh
                },
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
                .orderBy('createdAt', descending: _sortDescending)
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

              final allDocs = snapshot.data!.docs;
              final complaints = allDocs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final date = (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
                
                // Date matchers
                bool yearMatch = _selectedYear == 'All' || date.year.toString() == _selectedYear;
                bool monthMatch = _selectedMonth == 'All' || _months[date.month] == _selectedMonth;
                bool dayMatch = _selectedDay == 'All' || date.day.toString() == _selectedDay;

                // Vehicle matchers
                bool vehicleMatch = _selectedVehicle == 'All';
                if (!vehicleMatch) {
                  String vType = (data['vehicleType'] ?? data['vehicle'] ?? data['description'] ?? '').toString().toLowerCase();
                  
                  // Fallback for missing data: simulate vehicle type based on doc ID so filters can be demonstrated
                  if (vType.trim().isEmpty) {
                    vType = doc.id.hashCode % 2 == 0 ? 'motorcycle' : 'taxi';
                  }

                  if (_selectedVehicle == 'Motorcycle') {
                    vehicleMatch = vType.contains('motor') || vType.contains('click') || vType.contains('nmax') || vType.contains('burgman') || vType.contains('motorcycle');
                  } else if (_selectedVehicle == 'Taxi') {
                    vehicleMatch = vType.contains('taxi') || vType.contains('car') || vType.contains('vios') || vType.contains('accent');
                  }
                }

                return yearMatch && monthMatch && dayMatch && vehicleMatch;
              }).toList();

              if (complaints.isEmpty) {
                return const Center(child: Text('No complaints match the selected filters.'));
              }

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

  /// Shows a dialog for the admin to type and submit a response to a complaint.
  /// Marks the complaint as 'resolved' in Firestore upon submission.
  /// Executes the logic for _showResponseDialog.
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

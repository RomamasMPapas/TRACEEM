import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

/// The [DashboardPage] provides the administrator with a high-level overview
/// of system metrics and analytics. It includes interactive charts such as
/// a Bar Chart showing individual driver ratings, a Pie Chart for satisfaction,
/// and a Line Chart for profit analysis.
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  String _selectedType = 'All';

  // Mock data for drivers with types
  // Mock data for drivers with types
  final List<Map<String, dynamic>> _mockDriverRatings = [
    {'name': 'Lito Fast', 'rating': 4.8, 'type': 'Motorcycle'},
    {'name': 'Maria Rider', 'rating': 4.9, 'type': 'Motorcycle'},
    {'name': 'Jun Moto', 'rating': 2.5, 'type': 'Motorcycle'},
    {'name': 'Kiko Wheels', 'rating': 4.2, 'type': 'Motorcycle'},
    {'name': 'Benji Zoom', 'rating': 3.8, 'type': 'Motorcycle'},
    {'name': 'Robert Driver', 'rating': 3.0, 'type': 'Taxi'},
    {'name': 'Sally Cab', 'rating': 3.5, 'type': 'Taxi'},
    {'name': 'Carlo Sedan', 'rating': 4.5, 'type': 'Taxi'},
    {'name': 'Dina Drive', 'rating': 2.8, 'type': 'Taxi'},
    {'name': 'Tony Wheels', 'rating': 4.0, 'type': 'Taxi'},
  ];

  int _touchedBarIndex = -1;
  int _touchedPieIndex = -1;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('ratings').snapshots(),
      builder: (context, ratingsSnapshot) {
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('receipts').snapshots(),
          builder: (context, receiptsSnapshot) {
            if (ratingsSnapshot.hasError || receiptsSnapshot.hasError) {
              return const Center(child: Text('Something went wrong'));
            }

            if (ratingsSnapshot.connectionState == ConnectionState.waiting ||
                receiptsSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            // --- PROCESS RATINGS ---
            final allRatings = [
              ..._mockDriverRatings,
            ]; // Include mock for fuller chart
            for (var doc in ratingsSnapshot.data!.docs) {
              final data = doc.data() as Map<String, dynamic>;
              allRatings.add({
                'name': data['driver'] ?? 'Unknown',
                'rating': (data['rating'] as num?)?.toDouble() ?? 0.0,
                'type': data['type'] ?? 'Motorcycle',
              });
            }

            final filteredDrivers = allRatings
                .where(
                  (d) => _selectedType == 'All' || d['type'] == _selectedType,
                )
                .toList();

            // Group by driver to get average
            Map<String, List<double>> grouped = {};
            for (var d in filteredDrivers) {
              grouped.putIfAbsent(d['name'], () => []).add(d['rating']);
            }

            List<Map<String, dynamic>> driverAverages = grouped.entries.map((
              e,
            ) {
              double avg = e.value.reduce((a, b) => a + b) / e.value.length;
              return {
                'name': e.key,
                'rating': avg,
                'type': filteredDrivers.firstWhere(
                  (d) => d['name'] == e.key,
                )['type'],
              };
            }).toList();

            // Calculate satisfaction
            final int satisfiedCount = driverAverages
                .where((d) => d['rating'] >= 4)
                .length;
            final int neutralCount = driverAverages
                .where((d) => d['rating'] >= 3 && d['rating'] < 4)
                .length;
            final int dissatisfiedCount = driverAverages
                .where((d) => d['rating'] < 3)
                .length;

            // --- PROCESS PROFITS ---
            double totalProfit = 0;
            Map<int, double> motoMonthly = {
              0: 12000,
              1: 15000,
              2: 11000,
              3: 18000,
              4: 22000,
              5: 25000,
            };
            Map<int, double> taxiMonthly = {
              0: 35000,
              1: 32000,
              2: 40000,
              3: 38000,
              4: 45000,
              5: 48000,
            };

            for (var doc in receiptsSnapshot.data!.docs) {
              final data = doc.data() as Map<String, dynamic>;
              final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
              final date =
                  (data['date'] as Timestamp?)?.toDate() ?? DateTime.now();
              final type = data['type'] ?? 'Motorcycle';

              totalProfit += amount;

              // Only add to June (index 5) for demo purposes of new data
              if (date.month == 5) {
                // May (index 4) or 6 for June
                if (type == 'Motorcycle') {
                  motoMonthly[5] = (motoMonthly[5] ?? 0) + amount;
                } else {
                  taxiMonthly[5] = (taxiMonthly[5] ?? 0) + amount;
                }
              }
            }

            final List<FlSpot> motoSpots = motoMonthly.entries
                .map((e) => FlSpot(e.key.toDouble(), e.value))
                .toList();
            final List<FlSpot> taxiSpots = taxiMonthly.entries
                .map((e) => FlSpot(e.key.toDouble(), e.value))
                .toList();

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Admin Dashboard Analytics',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E3A8A),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Vehicle Type Tabs
                  Container(
                    margin: const EdgeInsets.only(bottom: 24),
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
                                color: isSelected
                                    ? const Color(0xFF4C8CFF)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Text(
                                  type,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.grey.shade700,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  // First Row: Ratings & Satisfaction
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: _buildRatingsCard(driverAverages),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        flex: 1,
                        child: _buildSatisfactionCard(
                          satisfiedCount,
                          neutralCount,
                          dissatisfiedCount,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Second Row: Profit Chart
                  _buildProfitCard(
                    motoSpots,
                    taxiSpots,
                    totalProfit + 73000,
                  ), // Base mock + real
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildRatingsCard(List<Map<String, dynamic>> drivers) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Overall Ratings of Drivers',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Click on a bar to view details.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 300,
              child: BarChart(
                BarChartData(
                  maxY: 5,
                  barTouchData: BarTouchData(
                    touchCallback: (event, response) {
                      setState(() {
                        if (!event.isInterestedForInteractions ||
                            response == null ||
                            response.spot == null) {
                          _touchedBarIndex = -1;
                          return;
                        }
                        _touchedBarIndex = response.spot!.touchedBarGroupIndex;
                      });
                    },
                  ),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          int idx = value.toInt();
                          if (idx >= 0 && idx < drivers.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                drivers[idx]['name'].toString().split(' ')[0],
                                style: const TextStyle(fontSize: 10),
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                      ),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  barGroups: drivers.asMap().entries.map((e) {
                    return BarChartGroupData(
                      x: e.key,
                      barRods: [
                        BarChartRodData(
                          toY: e.value['rating'],
                          color: e.key == _touchedBarIndex
                              ? Colors.amber
                              : const Color(0xFF4C8CFF),
                          width: 18,
                          borderRadius: BorderRadius.circular(4),
                          backDrawRodData: BackgroundBarChartRodData(
                            show: true,
                            toY: 5,
                            color: Colors.grey.shade100,
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSatisfactionCard(int s, int n, int d) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const Text(
              'Ride Satisfaction',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  pieTouchData: PieTouchData(
                    touchCallback: (FlTouchEvent event, pieTouchResponse) {
                      setState(() {
                        if (!event.isInterestedForInteractions ||
                            pieTouchResponse == null ||
                            pieTouchResponse.touchedSection == null) {
                          _touchedPieIndex = -1;
                          return;
                        }
                        _touchedPieIndex = pieTouchResponse
                            .touchedSection!
                            .touchedSectionIndex;
                      });
                    },
                  ),
                  sections: [
                    PieChartSectionData(
                      color: Colors.green,
                      value: s.toDouble(),
                      title: 'S',
                      radius: _touchedPieIndex == 0 ? 60 : 50,
                      titleStyle: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    PieChartSectionData(
                      color: Colors.amber,
                      value: n.toDouble(),
                      title: 'N',
                      radius: _touchedPieIndex == 1 ? 60 : 50,
                      titleStyle: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    PieChartSectionData(
                      color: Colors.red,
                      value: d.toDouble(),
                      title: 'D',
                      radius: _touchedPieIndex == 2 ? 60 : 50,
                      titleStyle: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            _buildLegend(Colors.green, 'Satisfied'),
            _buildLegend(Colors.amber, 'Neutral'),
            _buildLegend(Colors.red, 'Dissatisfied'),
          ],
        ),
      ),
    );
  }

  Widget _buildProfitCard(
    List<FlSpot> motoSpots,
    List<FlSpot> taxiSpots,
    double total,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Monthly Profit Analysis',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E3A8A),
                      ),
                    ),
                    Text(
                      'Net revenue after platform fees',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
                Text(
                  'Total: ₱${NumberFormat('#,###').format(total)}',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Colors.green.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            SizedBox(
              height: 250,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (v) =>
                        FlLine(color: Colors.grey.shade200, strokeWidth: 1),
                  ),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (v, m) => Text(
                          ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'][v.toInt()],
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 45,
                        getTitlesWidget: (v, m) => Text(
                          '₱${(v / 1000).toInt()}k',
                          style: const TextStyle(fontSize: 10),
                        ),
                      ),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: motoSpots,
                      isCurved: true,
                      color: const Color(0xFF4C8CFF),
                      barWidth: 4,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: const Color(0xFF4C8CFF).withValues(alpha: 0.1),
                      ),
                    ),
                    LineChartBarData(
                      spots: taxiSpots,
                      isCurved: true,
                      color: Colors.green,
                      barWidth: 4,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.green.withValues(alpha: 0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_selectedType == 'All' || _selectedType == 'Motorcycle')
                  _buildLegend(Colors.orange, 'Motorcycle Profit'),
                if (_selectedType == 'All') const SizedBox(width: 24),
                if (_selectedType == 'All' || _selectedType == 'Taxi')
                  _buildLegend(const Color(0xFF4C8CFF), 'Taxi Profit'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend(Color c, String t) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: c,
          borderRadius: BorderRadius.circular(3),
        ),
      ),
      const SizedBox(width: 8),
      Text(
        t,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
      ),
    ],
  );
}

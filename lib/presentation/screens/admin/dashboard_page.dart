import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

/// The [DashboardPage] provides the administrator with a high-level overview
/// of system metrics and analytics. It includes interactive charts such as
/// a Bar Chart showing individual driver ratings and a Pie Chart summarizing
/// overall ride satisfaction levels (Satisfied, Neutral, Dissatisfied).
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  // Mock data matching the app's standard data
  final List<Map<String, dynamic>> _driverRatings = [
    {'name': 'Lito Fast', 'rating': 4.8},
    {'name': 'Maria Rider', 'rating': 4.9},
    {'name': 'Jun Moto', 'rating': 2.5},
    {'name': 'Kiko Wheels', 'rating': 4.2},
    {'name': 'Benji Zoom', 'rating': 3.8},
    {'name': 'Robert Driver', 'rating': 3.0},
    {'name': 'Sally Cab', 'rating': 3.5},
    {'name': 'Carlo Sedan', 'rating': 4.5},
    {'name': 'Dina Drive', 'rating': 2.8},
    {'name': 'Tony Wheels', 'rating': 4.0},
  ];

  int _touchedBarIndex = -1;
  int _touchedPieIndex = -1;

  @override
  Widget build(BuildContext context) {
    // Calculate satisfied vs dissatisfied based on driver ratings.
    // Satisfied: Rating >= 4
    // Neutral: Rating between 3 and 3.9
    // Dissatisfied: Rating < 3
    final int satisfiedCount = _driverRatings.where((d) => d['rating'] >= 4).length;
    final int neutralCount = _driverRatings.where((d) => d['rating'] >= 3 && d['rating'] < 4).length;
    final int dissatisfiedCount = _driverRatings.where((d) => d['rating'] < 3).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Admin Dashboard Analytics',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Bar Chart Section - Displays Overall Ratings of Drivers
              Expanded(
                flex: 2,
                child: Card(
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
                        const Text('Click on a bar to view the driver\'s exact rating.', style: TextStyle(color: Colors.grey)),
                        const SizedBox(height: 24),
                        SizedBox(
                          height: 300,
                          child: BarChart(
                            BarChartData(
                              alignment: BarChartAlignment.spaceAround,
                              maxY: 5,
                              barTouchData: BarTouchData(
                                enabled: true,
                                touchCallback: (FlTouchEvent event, barTouchResponse) {
                                  setState(() {
                                    if (!event.isInterestedForInteractions || barTouchResponse == null || barTouchResponse.spot == null) {
                                      _touchedBarIndex = -1;
                                      return;
                                    }
                                    _touchedBarIndex = barTouchResponse.spot!.touchedBarGroupIndex;
                                  });
                                },
                                touchTooltipData: BarTouchTooltipData(
                                  getTooltipColor: (_) => Colors.blueGrey.shade800,
                                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                    return BarTooltipItem(
                                      '${_driverRatings[groupIndex]['name']}\n',
                                      const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                      children: [
                                        TextSpan(
                                          text: rod.toY.toString(),
                                          style: const TextStyle(color: Colors.amber, fontSize: 16),
                                        ),
                                        const TextSpan(text: ' Stars', style: TextStyle(color: Colors.white70)),
                                      ],
                                    );
                                  },
                                ),
                              ),
                              titlesData: FlTitlesData(
                                show: true,
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (double value, TitleMeta meta) {
                                      final index = value.toInt();
                                      if (index >= 0 && index < _driverRatings.length) {
                                        return Padding(
                                          padding: const EdgeInsets.only(top: 8.0),
                                          child: Text(
                                            _driverRatings[index]['name'].toString().split(' ')[0], // Show first name only
                                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
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
                                    getTitlesWidget: (value, meta) {
                                      return Text('${value.toInt()}', style: const TextStyle(fontSize: 12));
                                    },
                                  ),
                                ),
                                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              ),
                              gridData: FlGridData(
                                show: true,
                                drawVerticalLine: false,
                                horizontalInterval: 1,
                                getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.shade200, strokeWidth: 1),
                              ),
                              borderData: FlBorderData(show: false),
                              barGroups: _driverRatings.asMap().entries.map((entry) {
                                final index = entry.key;
                                final rating = entry.value['rating'] as double;
                                final isTouched = index == _touchedBarIndex;
                                return BarChartGroupData(
                                  x: index,
                                  barRods: [
                                    BarChartRodData(
                                      toY: rating,
                                      color: isTouched ? Colors.amber : const Color(0xFF4C8CFF),
                                      width: 22,
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(6),
                                        topRight: Radius.circular(6),
                                      ),
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
                ),
              ),
              const SizedBox(width: 24),
              // Pie Chart Section - Displays Ride Satisfaction Categories
              Expanded(
                flex: 1,
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Ride Satisfaction',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        const Text('Based on total ride ratings.', style: TextStyle(color: Colors.grey)),
                        const SizedBox(height: 24),
                        SizedBox(
                          height: 220,
                          child: PieChart(
                            PieChartData(
                              pieTouchData: PieTouchData(
                                touchCallback: (FlTouchEvent event, pieTouchResponse) {
                                  setState(() {
                                    if (!event.isInterestedForInteractions || pieTouchResponse == null || pieTouchResponse.touchedSection == null) {
                                      _touchedPieIndex = -1;
                                      return;
                                    }
                                    _touchedPieIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                                  });
                                },
                              ),
                              sectionsSpace: 2,
                              centerSpaceRadius: 40,
                              sections: [
                                PieChartSectionData(
                                  color: Colors.green,
                                  value: satisfiedCount.toDouble(),
                                  title: 'Satisfied',
                                  radius: _touchedPieIndex == 0 ? 60.0 : 50.0,
                                  titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                                PieChartSectionData(
                                  color: Colors.amber,
                                  value: neutralCount.toDouble(),
                                  title: 'Neutral',
                                  radius: _touchedPieIndex == 1 ? 60.0 : 50.0,
                                  titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                                PieChartSectionData(
                                  color: Colors.red,
                                  value: dissatisfiedCount.toDouble(),
                                  title: 'Dissatisfied',
                                  radius: _touchedPieIndex == 2 ? 60.0 : 50.0,
                                  titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Legend for the Pie Chart
                        Row(
                          children: [
                            Container(width: 12, height: 12, color: Colors.green),
                            const SizedBox(width: 8),
                            const Text('Satisfied (>=4)'),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(width: 12, height: 12, color: Colors.amber),
                            const SizedBox(width: 8),
                            const Text('Neutral (3)'),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(width: 12, height: 12, color: Colors.red),
                            const SizedBox(width: 8),
                            const Text('Dissatisfied (<3)'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

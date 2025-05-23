import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart'; // Or Syncfusion charts
import 'package:mon_sirh_mobile/providers/conge_provider.dart'; // Example: Use leave data
import 'package:provider/provider.dart';

// Placeholder widget for displaying RH statistics
class StatsWidget extends StatelessWidget {
  const StatsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    // Access providers to get data for stats (e.g., CongeProvider)
    final congeProvider = Provider.of<CongeProvider>(context);

    // TODO: Calculate actual statistics based on provider data
    // Example calculations (replace with real logic):
    final totalRequests = congeProvider.congeRequests.length;
    final pendingRequests = congeProvider.congeRequests.where((c) => c.status == CongeStatus.enAttente).length;
    final approvedRequests = congeProvider.congeRequests.where((c) => c.status == CongeStatus.approuvee).length;
    // Calculate absenteeism rate (needs more data/definition)
    final absenteeismRate = 0.05; // Placeholder 5%

    return Card(
      elevation: 3.0,
      margin: const EdgeInsets.symmetric(vertical: 10.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Statistiques RH Rapides',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            // Row for key metrics
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Demandes en Attente', pendingRequests.toString(), Icons.hourglass_empty, Colors.orange),
                _buildStatItem('Demandes Approuvées', approvedRequests.toString(), Icons.check_circle, Colors.green),
                _buildStatItem('Taux d\'Absentéisme', '${(absenteeismRate * 100).toStringAsFixed(1)}%', Icons.trending_down, Colors.red),
              ],
            ),
            const SizedBox(height: 20),
            // Placeholder for a chart (e.g., Pie chart of leave types)
            Text(
              'Répartition des Types de Congés (Exemple)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 150,
              child: _buildLeaveTypeChart(context, congeProvider), // Placeholder chart
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String title, String value, IconData icon, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 30, color: color),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey), textAlign: TextAlign.center),
      ],
    );
  }

  // Example Pie Chart using fl_chart
  Widget _buildLeaveTypeChart(BuildContext context, CongeProvider congeProvider) {
    // Calculate data for the chart
    Map<CongeType, int> typeCounts = {};
    for (var req in congeProvider.congeRequests) {
      typeCounts[req.type] = (typeCounts[req.type] ?? 0) + 1;
    }

    if (typeCounts.isEmpty) {
      return const Center(child: Text('Aucune donnée pour le graphique.'));
    }

    List<PieChartSectionData> sections = [];
    double total = typeCounts.values.fold(0, (sum, item) => sum + item);
    final colors = [Colors.blue, Colors.green, Colors.red, Colors.purple, Colors.yellow];
    int colorIndex = 0;

    typeCounts.forEach((type, count) {
      final isTouched = false; // Add touch interaction later if needed
      final fontSize = isTouched ? 18.0 : 14.0;
      final radius = isTouched ? 60.0 : 50.0;
      final value = (count / total) * 100;

      sections.add(PieChartSectionData(
        color: colors[colorIndex % colors.length],
        value: value,
        title: '${value.toStringAsFixed(1)}%',
        radius: radius,
        titleStyle: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          shadows: [Shadow(color: Colors.black.withOpacity(0.5), blurRadius: 2)],
        ),
        // Optional: Add badge widget for type name
        // badgeWidget: Text(type.toString().split('.').last),
        // badgePositionPercentageOffset: .98,
      ));
      colorIndex++;
    });

    return PieChart(
      PieChartData(
        sections: sections,
        centerSpaceRadius: 40,
        sectionsSpace: 2,
        // Add touch interaction handling later
        // pieTouchData: PieTouchData(touchCallback: (FlTouchEvent event, pieTouchResponse) {
        //   // Handle touch
        // }),
      ),
    );
  }
}


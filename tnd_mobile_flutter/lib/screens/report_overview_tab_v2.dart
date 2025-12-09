import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/report_model.dart';

/// Modern Report Overview Tab
/// Analytics-style design with cards and donut chart
class ReportOverviewTabV2 extends StatelessWidget {
  final ReportOverview? overview;
  final VoidCallback onRefresh;
  final VoidCallback onExportPDF;

  const ReportOverviewTabV2({
    Key? key,
    required this.overview,
    required this.onRefresh,
    required this.onExportPDF,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (overview == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.analytics_outlined, size: 64, color: Color(0xFF95A5A6)),
            const SizedBox(height: 16),
            const Text(
              'No data available',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF7F8C8D),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5DADE2),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      color: const Color(0xFF5DADE2),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Statistics Cards
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Total Visits',
                    overview!.totalVisits.toString(),
                    Icons.check_circle_outline,
                    const Color(0xFF5DADE2),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Total Outlets',
                    overview!.totalOutlets.toString(),
                    Icons.store,
                    const Color(0xFF9B59B6),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Donut Chart Card
            _buildChartCard(),
            
            const SizedBox(height: 16),
            
            // Response Count Cards
            Row(
              children: [
                Expanded(
                  child: _buildResponseCard(
                    'OK',
                    overview!.okCount,
                    '${overview!.okPercentage.toStringAsFixed(1)}%',
                    const Color(0xFF27AE60),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildResponseCard(
                    'NOK',
                    overview!.nokCount,
                    '${overview!.nokPercentage.toStringAsFixed(1)}%',
                    const Color(0xFFE74C3C),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Recent Visits
            if (overview!.recentVisits.isNotEmpty) ...[
              _buildSectionHeader('Recent Visits'),
              const SizedBox(height: 12),
              ...overview!.recentVisits.map((visit) => _buildVisitCard(visit)),
            ],
            
            const SizedBox(height: 20),
            
            // Export PDF Button
            Center(
              child: ElevatedButton.icon(
                onPressed: onExportPDF,
                icon: const Icon(Icons.picture_as_pdf, size: 20),
                label: const Text(
                  'Export to PDF',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5DADE2),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 4,
                ),
              ),
            ),
            
            const SizedBox(height: 100), // Space for bottom nav
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withAlpha(26),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 24, color: color),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF7F8C8D),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartCard() {
    final hasData = overview!.okCount > 0 || overview!.nokCount > 0;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Response Distribution',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 20),
          
          if (!hasData)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Text(
                  'No responses yet',
                  style: TextStyle(color: Color(0xFF95A5A6)),
                ),
              ),
            )
          else
            SizedBox(
              height: 200,
              child: Row(
                children: [
                  // Donut Chart
                  Expanded(
                    flex: 3,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 50,
                        sections: [
                          PieChartSectionData(
                            color: const Color(0xFF27AE60),
                            value: overview!.okCount.toDouble(),
                            title: '',
                            radius: 40,
                          ),
                          PieChartSectionData(
                            color: const Color(0xFFE74C3C),
                            value: overview!.nokCount.toDouble(),
                            title: '',
                            radius: 40,
                          ),
                          if (overview!.naCount > 0)
                            PieChartSectionData(
                              color: const Color(0xFF95A5A6),
                              value: overview!.naCount.toDouble(),
                              title: '',
                              radius: 40,
                            ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Legend
                  Expanded(
                    flex: 2,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLegendItem(
                          'OK',
                          overview!.okCount,
                          const Color(0xFF27AE60),
                        ),
                        const SizedBox(height: 12),
                        _buildLegendItem(
                          'NOK',
                          overview!.nokCount,
                          const Color(0xFFE74C3C),
                        ),
                        if (overview!.naCount > 0) ...[
                          const SizedBox(height: 12),
                          _buildLegendItem(
                            'N/A',
                            overview!.naCount,
                            const Color(0xFF95A5A6),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, int count, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF7F8C8D),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '($count)',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2C3E50),
          ),
        ),
      ],
    );
  }

  Widget _buildResponseCard(String title, int count, String percentage, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withAlpha(77)),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            percentage,
            style: TextStyle(
              fontSize: 14,
              color: color.withAlpha(179),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Color(0xFF2C3E50),
      ),
    );
  }

  Widget _buildVisitCard(RecentVisit visit) {
    Color statusColor;
    if (visit.status == 'Good') {
      statusColor = const Color(0xFF27AE60);
    } else if (visit.status == 'Warning') {
      statusColor = const Color(0xFFF39C12);
    } else {
      statusColor = const Color(0xFFE74C3C);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E6ED)),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: statusColor.withAlpha(26),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.store,
              size: 24,
              color: statusColor,
            ),
          ),
          const SizedBox(width: 12),
          
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  visit.outletName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2C3E50),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('dd MMM yyyy, HH:mm').format(DateTime.parse(visit.visitDate)),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF95A5A6),
                  ),
                ),
              ],
            ),
          ),
          
          // Status Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withAlpha(26),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${visit.okPercentage.toStringAsFixed(0)}%',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

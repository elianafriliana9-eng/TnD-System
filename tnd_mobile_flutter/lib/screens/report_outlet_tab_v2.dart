import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/report_model.dart';

/// Modern Report Outlet Tab
/// Clean list design with search and status filters
class ReportOutletTabV2 extends StatefulWidget {
  final List<OutletReport> outlets;
  final VoidCallback onRefresh;
  final VoidCallback onExportPDF;

  const ReportOutletTabV2({
    Key? key,
    required this.outlets,
    required this.onRefresh,
    required this.onExportPDF,
  }) : super(key: key);

  @override
  State<ReportOutletTabV2> createState() => _ReportOutletTabV2State();
}

class _ReportOutletTabV2State extends State<ReportOutletTabV2> {
  String _searchQuery = '';
  String _statusFilter = 'All';

  List<OutletReport> get _filteredOutlets {
    return widget.outlets.where((outlet) {
      // Search filter
      final matchesSearch = outlet.outletName
          .toLowerCase()
          .contains(_searchQuery.toLowerCase());

      // Status filter
      final matchesStatus = _statusFilter == 'All' || outlet.status == _statusFilter;

      return matchesSearch && matchesStatus;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search and Filter Section
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Search Bar
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F7FA),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE0E6ED)),
                ),
                child: TextField(
                  onChanged: (value) => setState(() => _searchQuery = value),
                  decoration: const InputDecoration(
                    hintText: 'Search outlets...',
                    hintStyle: TextStyle(color: Color(0xFF95A5A6)),
                    prefixIcon: Icon(Icons.search, color: Color(0xFF95A5A6)),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Status Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('All'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Good'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Warning'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Critical'),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Outlet List
        Expanded(
          child: _filteredOutlets.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: () async => widget.onRefresh(),
                  color: const Color(0xFF5DADE2),
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    itemCount: _filteredOutlets.length + 1, // +1 for export button
                    itemBuilder: (context, index) {
                      if (index == _filteredOutlets.length) {
                        // Export button at the end
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: Center(
                            child: ElevatedButton.icon(
                              onPressed: widget.onExportPDF,
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
                        );
                      }
                      return _buildOutletCard(_filteredOutlets[index]);
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String status) {
    final isSelected = _statusFilter == status;
    Color color;
    
    switch (status) {
      case 'Good':
        color = const Color(0xFF27AE60);
        break;
      case 'Warning':
        color = const Color(0xFFF39C12);
        break;
      case 'Critical':
        color = const Color(0xFFE74C3C);
        break;
      default:
        color = const Color(0xFF5DADE2);
    }

    return GestureDetector(
      onTap: () => setState(() => _statusFilter = status),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color),
        ),
        child: Text(
          status,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : color,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.store_outlined, size: 64, color: Color(0xFF95A5A6)),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty || _statusFilter != 'All'
                ? 'No outlets found'
                : 'No outlet data available',
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF7F8C8D),
            ),
          ),
          if (_searchQuery.isNotEmpty || _statusFilter != 'All') ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                setState(() {
                  _searchQuery = '';
                  _statusFilter = 'All';
                });
              },
              child: const Text('Clear filters'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOutletCard(OutletReport outlet) {
    Color statusColor;
    if (outlet.status == 'Good') {
      statusColor = const Color(0xFF27AE60);
    } else if (outlet.status == 'Warning') {
      statusColor = const Color(0xFFF39C12);
    } else {
      statusColor = const Color(0xFFE74C3C);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showOutletDetail(outlet),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    // Icon
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: statusColor.withAlpha(26),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.store,
                        size: 24,
                        color: statusColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    
                    // Outlet Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            outlet.outletName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2C3E50),
                            ),
                          ),
                          if (outlet.address != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              outlet.address!,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF95A5A6),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
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
                        outlet.status,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Stats Grid
                Row(
                  children: [
                    Expanded(
                      child: _buildStatItem(
                        'Visits',
                        outlet.totalVisits.toString(),
                        Icons.history,
                      ),
                    ),
                    Expanded(
                      child: _buildStatItem(
                        'OK Rate',
                        '${outlet.okPercentage.toStringAsFixed(0)}%',
                        Icons.check_circle,
                      ),
                    ),
                    Expanded(
                      child: _buildStatItem(
                        'Items',
                        outlet.totalItems.toString(),
                        Icons.list_alt,
                      ),
                    ),
                  ],
                ),
                
                // Last Visit
                if (outlet.lastVisitDate != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F7FA),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.access_time,
                          size: 14,
                          color: Color(0xFF95A5A6),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Last visit: ${DateFormat('dd MMM yyyy').format(DateTime.parse(outlet.lastVisitDate!))}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF7F8C8D),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF5DADE2)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2C3E50),
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFF95A5A6),
          ),
        ),
      ],
    );
  }

  void _showOutletDetail(OutletReport outlet) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0E6ED),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                
                // Header
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              outlet.outletName,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2C3E50),
                              ),
                            ),
                            if (outlet.address != null)
                              Text(
                                outlet.address!,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF95A5A6),
                                ),
                              ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                
                const Divider(height: 1),
                
                // Content
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(20),
                    children: [
                      // Stats
                      Row(
                        children: [
                          Expanded(
                            child: _buildDetailStat(
                              'OK',
                              outlet.okCount.toString(),
                              const Color(0xFF27AE60),
                            ),
                          ),
                          Expanded(
                            child: _buildDetailStat(
                              'NOK',
                              outlet.nokCount.toString(),
                              const Color(0xFFE74C3C),
                            ),
                          ),
                          Expanded(
                            child: _buildDetailStat(
                              'N/A',
                              outlet.naCount.toString(),
                              const Color(0xFF95A5A6),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Top NOK Issues
                      if (outlet.topNokIssues.isNotEmpty) ...[
                        const Text(
                          'Top Issues',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2C3E50),
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...outlet.topNokIssues.map((issue) => _buildIssueItem(issue)),
                      ] else
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32.0),
                            child: Text(
                              'No issues found',
                              style: TextStyle(color: Color(0xFF95A5A6)),
                            ),
                          ),
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
  }

  Widget _buildDetailStat(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIssueItem(NokIssue issue) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF5F5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFFCDD2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFFE74C3C).withAlpha(26),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(
              Icons.warning_amber,
              size: 18,
              color: Color(0xFFE74C3C),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  issue.point,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2C3E50),
                  ),
                ),
                Text(
                  issue.category,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF95A5A6),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFE74C3C),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${issue.frequency}x',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

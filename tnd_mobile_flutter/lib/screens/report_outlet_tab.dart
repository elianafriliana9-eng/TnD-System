import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/user_model.dart';
import '../models/report_model.dart';

/// Report Outlet Tab
/// Shows list of outlets with their performance status
class ReportOutletTab extends StatefulWidget {
  final List<OutletReport> outletReports;
  final UserModel currentUser;
  final DateTime? startDate;
  final DateTime? endDate;
  final VoidCallback onRefresh;

  const ReportOutletTab({
    Key? key,
    required this.outletReports,
    required this.currentUser,
    this.startDate,
    this.endDate,
    required this.onRefresh,
  }) : super(key: key);

  @override
  State<ReportOutletTab> createState() => _ReportOutletTabState();
}

class _ReportOutletTabState extends State<ReportOutletTab> {
  String _searchQuery = '';
  String _sortBy = 'name'; // name, percentage, visits
  bool _sortAscending = true;
  String _filterStatus = 'all'; // all, good, warning, critical

  List<OutletReport> get _filteredAndSortedOutlets {
    var outlets = widget.outletReports;

    // Filter by search
    if (_searchQuery.isNotEmpty) {
      outlets = outlets.where((outlet) {
        return outlet.outletName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            (outlet.city?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
      }).toList();
    }

    // Filter by status
    if (_filterStatus != 'all') {
      outlets = outlets.where((outlet) {
        return outlet.status.toLowerCase() == _filterStatus.toLowerCase();
      }).toList();
    }

    // Sort
    outlets.sort((a, b) {
      int comparison = 0;
      
      switch (_sortBy) {
        case 'name':
          comparison = a.outletName.compareTo(b.outletName);
          break;
        case 'percentage':
          comparison = a.okPercentage.compareTo(b.okPercentage);
          break;
        case 'visits':
          comparison = a.totalVisits.compareTo(b.totalVisits);
          break;
      }

      return _sortAscending ? comparison : -comparison;
    });

    return outlets;
  }

  int get _goodCount => widget.outletReports.where((o) => o.status == 'Good').length;
  int get _warningCount => widget.outletReports.where((o) => o.status == 'Warning').length;
  int get _criticalCount => widget.outletReports.where((o) => o.status == 'Critical').length;

  @override
  Widget build(BuildContext context) {
    final filteredOutlets = _filteredAndSortedOutlets;

    return RefreshIndicator(
      onRefresh: () async => widget.onRefresh(),
      child: Column(
        children: [
          // Summary stats
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: _buildSummaryChip(
                    label: 'Good',
                    count: _goodCount,
                    color: Colors.green,
                    isSelected: _filterStatus == 'good',
                    onTap: () {
                      setState(() {
                        _filterStatus = _filterStatus == 'good' ? 'all' : 'good';
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildSummaryChip(
                    label: 'Warning',
                    count: _warningCount,
                    color: Colors.orange,
                    isSelected: _filterStatus == 'warning',
                    onTap: () {
                      setState(() {
                        _filterStatus = _filterStatus == 'warning' ? 'all' : 'warning';
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildSummaryChip(
                    label: 'Critical',
                    count: _criticalCount,
                    color: Colors.red,
                    isSelected: _filterStatus == 'critical',
                    onTap: () {
                      setState(() {
                        _filterStatus = _filterStatus == 'critical' ? 'all' : 'critical';
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          
          // Search and Sort
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search outlets...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                setState(() {
                                  _searchQuery = '';
                                });
                              },
                            )
                          : null,
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.sort),
                  tooltip: 'Sort by',
                  onSelected: (value) {
                    setState(() {
                      if (_sortBy == value) {
                        _sortAscending = !_sortAscending;
                      } else {
                        _sortBy = value;
                        _sortAscending = true;
                      }
                    });
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'name',
                      child: Row(
                        children: [
                          Icon(
                            _sortBy == 'name'
                                ? (_sortAscending ? Icons.arrow_upward : Icons.arrow_downward)
                                : Icons.sort_by_alpha,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          const Text('Name'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'percentage',
                      child: Row(
                        children: [
                          Icon(
                            _sortBy == 'percentage'
                                ? (_sortAscending ? Icons.arrow_upward : Icons.arrow_downward)
                                : Icons.percent,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          const Text('Performance'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'visits',
                      child: Row(
                        children: [
                          Icon(
                            _sortBy == 'visits'
                                ? (_sortAscending ? Icons.arrow_upward : Icons.arrow_downward)
                                : Icons.assignment,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          const Text('Visits'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const Divider(height: 1),
          
          // Outlet List
          Expanded(
            child: filteredOutlets.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(40.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.store_mall_directory_outlined,
                            size: 80,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _searchQuery.isNotEmpty || _filterStatus != 'all'
                                ? 'No outlets found'
                                : 'No outlet data available',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                            ),
                          ),
                          if (_searchQuery.isNotEmpty || _filterStatus != 'all')
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: TextButton(
                                onPressed: () {
                                  setState(() {
                                    _searchQuery = '';
                                    _filterStatus = 'all';
                                  });
                                },
                                child: const Text('Clear filters'),
                              ),
                            ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredOutlets.length,
                    itemBuilder: (context, index) {
                      return _buildOutletCard(filteredOutlets[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryChip({
    required String label,
    required int count,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withAlpha(51) : Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOutletCard(OutletReport outlet) {
    final statusColor = _parseColor(outlet.statusColor);
    final dateFormat = DateFormat('dd MMM yyyy');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          _showOutletDetail(outlet);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with name and status
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          outlet.outletName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (outlet.city != null && outlet.city!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.location_on,
                                  size: 14,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  outlet.city!,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      outlet.status,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Statistics
              Row(
                children: [
                  Expanded(
                    child: _buildOutletStat(
                      icon: Icons.percent,
                      label: 'OK Rate',
                      value: '${outlet.okPercentage.toStringAsFixed(1)}%',
                      color: statusColor,
                    ),
                  ),
                  Expanded(
                    child: _buildOutletStat(
                      icon: Icons.assignment,
                      label: 'Visits',
                      value: outlet.totalVisits.toString(),
                      color: Colors.blue,
                    ),
                  ),
                  Expanded(
                    child: _buildOutletStat(
                      icon: Icons.check_circle,
                      label: 'OK',
                      value: outlet.okCount.toString(),
                      color: Colors.green,
                    ),
                  ),
                  Expanded(
                    child: _buildOutletStat(
                      icon: Icons.cancel,
                      label: 'NOK',
                      value: outlet.nokCount.toString(),
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
              
              if (outlet.lastVisitDate != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Last visit: ${dateFormat.format(DateTime.parse(outlet.lastVisitDate!))}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOutletStat({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  void _showOutletDetail(OutletReport outlet) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Outlet name
                  Text(
                    outlet.outletName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (outlet.address != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        outlet.address!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 10),
                  
                  // Top NOK Issues
                  const Text(
                    'Top NOK Issues',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  Expanded(
                    child: outlet.topNokIssues.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.check_circle_outline,
                                  size: 64,
                                  color: Colors.green[300],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No NOK issues found!',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            controller: scrollController,
                            itemCount: outlet.topNokIssues.length,
                            itemBuilder: (context, index) {
                              final issue = outlet.topNokIssues[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.red[100],
                                    child: Text(
                                      '${index + 1}',
                                      style: TextStyle(
                                        color: Colors.red[700],
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  title: Text(issue.point),
                                  subtitle: Text(issue.category),
                                  trailing: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.red[50],
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '${issue.frequency}x',
                                      style: TextStyle(
                                        color: Colors.red[700],
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Close button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple[700],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Close'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Color _parseColor(String hexColor) {
    try {
      return Color(int.parse(hexColor.replaceFirst('#', '0xFF')));
    } catch (e) {
      return Colors.grey;
    }
  }
}

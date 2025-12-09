import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:share_plus/share_plus.dart';
import '../models/user_model.dart';
import '../models/report_model.dart';
import '../services/report_service.dart';
import '../services/pdf_report_service.dart';
import 'report_overview_tab_v2.dart';
import 'report_outlet_tab_v2.dart';
import 'report_history_tab.dart';

/// Modern Report Dashboard Screen
/// Redesigned with clean analytics-style UI
class ReportDashboardScreenV2 extends StatefulWidget {
  final UserModel currentUser;

  const ReportDashboardScreenV2({
    Key? key,
    required this.currentUser,
  }) : super(key: key);

  @override
  State<ReportDashboardScreenV2> createState() => _ReportDashboardScreenV2State();
}

class _ReportDashboardScreenV2State extends State<ReportDashboardScreenV2>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ReportService _reportService = ReportService();

  DateTime? _startDate;
  DateTime? _endDate;
  bool _isLoading = false;

  // Data holders
  ReportOverview? _overview;
  List<OutletReport> _outletReports = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this); // Changed from 2 to 3 tabs
    
    // Listen to tab changes to update button UI immediately
    _tabController.addListener(() {
      setState(() {
        // This will rebuild the UI when tab changes
      });
    });
    
    // Set default date range (last 30 days)
    _endDate = DateTime.now();
    _startDate = _endDate!.subtract(const Duration(days: 30));
    
    _loadReports();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadReports() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final startDateStr = _startDate != null 
          ? DateFormat('yyyy-MM-dd').format(_startDate!) 
          : null;
      final endDateStr = _endDate != null 
          ? DateFormat('yyyy-MM-dd').format(_endDate!) 
          : null;

      // Load both overview and outlet reports
      final results = await Future.wait([
        _reportService.getOverview(
          userId: widget.currentUser.id,
          startDate: startDateStr,
          endDate: endDateStr,
        ),
        _reportService.getOutletReports(
          userId: widget.currentUser.id,
          startDate: startDateStr,
          endDate: endDateStr,
        ),
      ]);

      setState(() {
        _overview = results[0] as ReportOverview;
        _outletReports = results[1] as List<OutletReport>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading reports: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _selectDateRange() async {
    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Date Range',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C3E50),
              ),
            ),
            const SizedBox(height: 20),
            
            // Quick Filters
            const Text(
              'Quick Filters',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF7F8C8D),
              ),
            ),
            const SizedBox(height: 12),
            
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildQuickFilterChip('Today', () {
                  final today = DateTime.now();
                  setState(() {
                    _startDate = DateTime(today.year, today.month, today.day);
                    _endDate = DateTime(today.year, today.month, today.day, 23, 59, 59);
                  });
                  Navigator.pop(context);
                  _loadReports();
                }),
                _buildQuickFilterChip('Last 7 Days', () {
                  final today = DateTime.now();
                  setState(() {
                    _endDate = today;
                    _startDate = today.subtract(const Duration(days: 7));
                  });
                  Navigator.pop(context);
                  _loadReports();
                }),
                _buildQuickFilterChip('Last 30 Days', () {
                  final today = DateTime.now();
                  setState(() {
                    _endDate = today;
                    _startDate = today.subtract(const Duration(days: 30));
                  });
                  Navigator.pop(context);
                  _loadReports();
                }),
                _buildQuickFilterChip('This Month', () {
                  final today = DateTime.now();
                  setState(() {
                    _startDate = DateTime(today.year, today.month, 1);
                    _endDate = DateTime(today.year, today.month + 1, 0, 23, 59, 59);
                  });
                  Navigator.pop(context);
                  _loadReports();
                }),
                _buildQuickFilterChip('Last Month', () {
                  final today = DateTime.now();
                  final lastMonth = DateTime(today.year, today.month - 1);
                  setState(() {
                    _startDate = DateTime(lastMonth.year, lastMonth.month, 1);
                    _endDate = DateTime(lastMonth.year, lastMonth.month + 1, 0, 23, 59, 59);
                  });
                  Navigator.pop(context);
                  _loadReports();
                }),
                _buildQuickFilterChip('All Time', () {
                  setState(() {
                    _startDate = null;
                    _endDate = null;
                  });
                  Navigator.pop(context);
                  _loadReports();
                }),
              ],
            ),
            
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            
            // Custom Range Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  Navigator.pop(context);
                  final DateTimeRange? picked = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                    initialDateRange: _startDate != null && _endDate != null
                        ? DateTimeRange(start: _startDate!, end: _endDate!)
                        : null,
                  );
                  
                  if (picked != null) {
                    setState(() {
                      _startDate = picked.start;
                      _endDate = picked.end;
                    });
                    _loadReports();
                  }
                },
                icon: const Icon(Icons.calendar_month),
                label: const Text('Custom Date Range'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5DADE2),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickFilterChip(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF5DADE2).withAlpha(26),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFF5DADE2).withAlpha(77),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Color(0xFF5DADE2),
          ),
        ),
      ),
    );
  }

  void _clearDateFilter() {
    setState(() {
      _startDate = null;
      _endDate = null;
    });
    _loadReports();
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Generating PDF...'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSuccessDialog(File file) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Color(0xFF27AE60)),
            SizedBox(width: 12),
            Text('PDF Generated'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Report saved successfully!',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Text(
              file.path,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          OutlinedButton.icon(
            onPressed: () async {
              Navigator.of(context).pop();
              // Share using share_plus package
              await Share.shareXFiles(
                [XFile(file.path)],
                text: 'T&D System Report',
              );
            },
            icon: const Icon(Icons.share),
            label: const Text('Share'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF5DADE2),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.of(context).pop();
              await OpenFile.open(file.path);
            },
            icon: const Icon(Icons.open_in_new),
            label: const Text('Open'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5DADE2),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportOverviewPDF() async {
    if (_overview == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No data to export'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      _showLoadingDialog();

      final pdfService = PdfReportService();
      final file = await pdfService.generateOverviewPDF(
        overview: _overview!,
        dateRange: _getDateRangeText(),
        userName: widget.currentUser.name,
        divisionName: widget.currentUser.divisionName,
      );

      // Close loading dialog
      if (mounted) Navigator.of(context).pop();

      // Show success dialog
      if (mounted) {
        _showSuccessDialog(file);
      }
    } catch (e) {
      // Close loading dialog if open
      if (mounted) Navigator.of(context).pop();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _exportOutletPDF() async {
    if (_outletReports.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No data to export'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Show filter dialog
    final String? selectedStatus = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Outlet Report'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select outlets to export:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            _buildStatusFilterOption('All Outlets', 'All', context),
            _buildStatusFilterOption('Good Performance Only', 'Good', context),
            _buildStatusFilterOption('Warning Performance Only', 'Warning', context),
            _buildStatusFilterOption('Critical Performance Only', 'Critical', context),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (selectedStatus == null) return; // User cancelled

    try {
      _showLoadingDialog();

      // Filter outlets based on selection
      final outletsToExport = selectedStatus == 'All'
          ? _outletReports
          : _outletReports.where((outlet) => outlet.status == selectedStatus).toList();

      if (outletsToExport.isEmpty) {
        if (mounted) Navigator.of(context).pop();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('No $selectedStatus outlets found'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      final pdfService = PdfReportService();
      final file = await pdfService.generateOutletPDF(
        outlets: outletsToExport,
        dateRange: _getDateRangeText(),
        userName: widget.currentUser.name,
        divisionName: widget.currentUser.divisionName,
        filterStatus: selectedStatus != 'All' ? selectedStatus : null,
      );

      // Close loading dialog
      if (mounted) Navigator.of(context).pop();

      // Show success dialog
      if (mounted) {
        _showSuccessDialog(file);
      }
    } catch (e) {
      // Close loading dialog if open
      if (mounted) Navigator.of(context).pop();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildStatusFilterOption(String label, String status, BuildContext context) {
    Color color;
    IconData icon;
    
    switch (status) {
      case 'Good':
        color = const Color(0xFF27AE60);
        icon = Icons.check_circle;
        break;
      case 'Warning':
        color = const Color(0xFFF39C12);
        icon = Icons.warning;
        break;
      case 'Critical':
        color = const Color(0xFFE74C3C);
        icon = Icons.error;
        break;
      default:
        color = const Color(0xFF5DADE2);
        icon = Icons.list_alt;
    }

    return InkWell(
      onTap: () => Navigator.pop(context, status),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withAlpha(26),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withAlpha(77)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: color.withAlpha(128)),
          ],
        ),
      ),
    );
  }

  String _getDateRangeText() {
    if (_startDate == null || _endDate == null) {
      return 'All Time';
    }
    
    final format = DateFormat('dd MMM yyyy');
    return '${format.format(_startDate!)} - ${format.format(_endDate!)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF2C3E50)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Statistics',
          style: TextStyle(
            color: Color(0xFF2C3E50),
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: CircleAvatar(
              radius: 20,
              backgroundColor: const Color(0xFF5DADE2),
              child: Text(
                widget.currentUser.name.isNotEmpty 
                    ? widget.currentUser.name[0].toUpperCase() 
                    : 'U',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF5DADE2)),
              ),
            )
          : Column(
              children: [
                // Date Filter Card
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(16),
                  child: _buildDateFilterCard(),
                ),
                const SizedBox(height: 8),
                
                // Tab Selector
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildTabButton('Overview', 0),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildTabButton('Per Outlet', 1),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildTabButton('Riwayat', 2),
                      ),
                    ],
                  ),
                ),
                
                // Content
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      ReportOverviewTabV2(
                        overview: _overview,
                        onRefresh: _loadReports,
                        onExportPDF: _exportOverviewPDF,
                      ),
                      ReportOutletTabV2(
                        outlets: _outletReports,
                        onRefresh: _loadReports,
                        onExportPDF: _exportOutletPDF,
                      ),
                      ReportHistoryTab(
                        currentUser: widget.currentUser,
                        startDate: _startDate,
                        endDate: _endDate,
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildDateFilterCard() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E6ED)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF5DADE2).withAlpha(26),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.calendar_today,
              size: 20,
              color: Color(0xFF5DADE2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Period',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF7F8C8D),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _getDateRangeText(),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2C3E50),
                  ),
                ),
              ],
            ),
          ),
          if (_startDate != null || _endDate != null)
            IconButton(
              icon: const Icon(Icons.close, size: 20, color: Color(0xFF95A5A6)),
              onPressed: _clearDateFilter,
            ),
          IconButton(
            icon: const Icon(Icons.edit, size: 20, color: Color(0xFF5DADE2)),
            onPressed: _selectDateRange,
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String title, int index) {
    final isSelected = _tabController.index == index;
    return GestureDetector(
      onTap: () => _tabController.animateTo(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF5DADE2) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF5DADE2) : const Color(0xFFE0E6ED),
          ),
        ),
        child: Center(
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : const Color(0xFF7F8C8D),
            ),
            child: Text(title),
          ),
        ),
      ),
    );
  }
}

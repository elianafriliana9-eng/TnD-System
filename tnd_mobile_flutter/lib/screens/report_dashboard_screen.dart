import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/user_model.dart';
import '../models/report_model.dart';
import '../services/report_service.dart';
import 'report_overview_tab.dart';
import 'report_outlet_tab.dart';

/// Report Dashboard Screen
/// Main screen for reports with tabs
class ReportDashboardScreen extends StatefulWidget {
  final UserModel currentUser;

  const ReportDashboardScreen({
    Key? key,
    required this.currentUser,
  }) : super(key: key);

  @override
  State<ReportDashboardScreen> createState() => _ReportDashboardScreenState();
}

class _ReportDashboardScreenState extends State<ReportDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ReportService _reportService = ReportService();

  DateTime? _startDate;
  DateTime? _endDate;
  bool _isLoading = false;

  // Data holders
  ReportOverview? _overview;
  List<OutletReport> _outletReports = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
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
      _errorMessage = null;
    });

    try {
      final startDateStr = _startDate != null 
          ? DateFormat('yyyy-MM-dd').format(_startDate!) 
          : null;
      final endDateStr = _endDate != null 
          ? DateFormat('yyyy-MM-dd').format(_endDate!) 
          : null;

      print('🔍 Loading reports for user ${widget.currentUser.id}');
      print('📅 Date range: $startDateStr to $endDateStr');

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
      
      print('✅ Reports loaded successfully');
      print('📊 Total visits: ${_overview?.totalVisits ?? 0}');
      print('🏪 Total outlets: ${_outletReports.length}');
    } catch (e) {
      print('❌ Error loading reports: $e');
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.blue[700]!,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _loadReports();
    }
  }

  void _clearDateFilter() {
    setState(() {
      _startDate = null;
      _endDate = null;
    });
    _loadReports();
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
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Reports'),
        backgroundColor: Colors.purple[700],
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Column(
            children: [
              // Date filter
              Container(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: _selectDateRange,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(51),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.white.withAlpha(128),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.calendar_today,
                                size: 18,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _getDateRangeText(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              if (_startDate != null)
                                GestureDetector(
                                  onTap: _clearDateFilter,
                                  child: const Icon(
                                    Icons.clear,
                                    size: 18,
                                    color: Colors.white,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.refresh, color: Colors.white),
                      onPressed: _loadReports,
                      tooltip: 'Refresh',
                    ),
                  ],
                ),
              ),
              
              // Tab bar
              Container(
                color: Colors.purple[700],
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: Colors.white,
                  indicatorWeight: 3,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white.withAlpha(179),
                  tabs: const [
                    Tab(
                      icon: Icon(Icons.dashboard),
                      text: 'Overview',
                    ),
                    Tab(
                      icon: Icon(Icons.store),
                      text: 'By Outlet',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading reports',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _loadReports,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple[700],
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    // Overview Tab
                    ReportOverviewTab(
                      overview: _overview,
                      currentUser: widget.currentUser,
                      startDate: _startDate,
                      endDate: _endDate,
                      onRefresh: _loadReports,
                    ),
                    
                    // Outlet Tab
                    ReportOutletTab(
                      outletReports: _outletReports,
                      currentUser: widget.currentUser,
                      startDate: _startDate,
                      endDate: _endDate,
                      onRefresh: _loadReports,
                    ),
                  ],
                ),
    );
  }
}

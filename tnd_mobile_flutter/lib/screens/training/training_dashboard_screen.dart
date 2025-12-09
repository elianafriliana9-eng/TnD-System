import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../services/training/training_service.dart';
import '../../services/division_service.dart';
import '../../models/division_model.dart';

class TrainingDashboardScreen extends StatefulWidget {
  const TrainingDashboardScreen({Key? key}) : super(key: key);

  @override
  State<TrainingDashboardScreen> createState() =>
      _TrainingDashboardScreenState();
}

class _TrainingDashboardScreenState extends State<TrainingDashboardScreen> {
  final TrainingService _trainingService = TrainingService();
  final DivisionService _divisionService = DivisionService();
  bool _isLoading = true;
  Map<String, dynamic>? _dashboardData;
  String _userName = '';
  String _userEmail = '';

  // Filter state
  List<DivisionModel> _divisions = [];
  int? _selectedDivisionId;
  String? _selectedDivisionName;
  String? _selectedMonth;
  DateTimeRange? _selectedDateRange;
  bool _isGeneratingPDF = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadDivisions();
    _loadDashboardData();
  }

  Future<void> _loadDivisions() async {
    final response = await _divisionService.getDivisions();
    if (response.success && response.data != null) {
      setState(() {
        _divisions = response.data!;
      });
    }
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('user_name') ?? 'User';
      _userEmail = prefs.getString('user_email') ?? '';
    });
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
    });

    // Prepare date range parameters
    String? dateFrom;
    String? dateTo;

    if (_selectedDateRange != null) {
      // Use date range directly
      dateFrom =
          '${_selectedDateRange!.start.year}-${_selectedDateRange!.start.month.toString().padLeft(2, '0')}-${_selectedDateRange!.start.day.toString().padLeft(2, '0')}';
      dateTo =
          '${_selectedDateRange!.end.year}-${_selectedDateRange!.end.month.toString().padLeft(2, '0')}-${_selectedDateRange!.end.day.toString().padLeft(2, '0')}';
    } else if (_selectedMonth != null) {
      // Convert month to date range
      final monthYear = _selectedMonth!.split(' ');
      final months = [
        'Januari',
        'Februari',
        'Maret',
        'April',
        'Mei',
        'Juni',
        'Juli',
        'Agustus',
        'September',
        'Oktober',
        'November',
        'Desember',
      ];
      final monthIndex = months.indexOf(monthYear[0]) + 1;
      final year = int.parse(monthYear[1]);

      final firstDay = DateTime(year, monthIndex, 1);
      final lastDay = DateTime(year, monthIndex + 1, 0);

      dateFrom =
          '${firstDay.year}-${firstDay.month.toString().padLeft(2, '0')}-${firstDay.day.toString().padLeft(2, '0')}';
      dateTo =
          '${lastDay.year}-${lastDay.month.toString().padLeft(2, '0')}-${lastDay.day.toString().padLeft(2, '0')}';
    }

    print(
      'DEBUG DASHBOARD: Requesting stats with dateFrom=$dateFrom, dateTo=$dateTo, division=$_selectedDivisionId',
    );

    final response = await _trainingService.getDashboardStats(
      dateFrom: dateFrom,
      dateTo: dateTo,
      divisionId: _selectedDivisionId,
    );

    if (response.success && response.data != null) {
      // DEBUG: Print dashboard data to see what we get
      print('DEBUG DASHBOARD: Full data = ${response.data}');
      print('DEBUG DASHBOARD: Summary = ${response.data?['summary']}');
      print(
        'DEBUG DASHBOARD: Pending sessions = ${response.data?['summary']?['pending_sessions']}',
      );
      print(
        'DEBUG DASHBOARD: Sessions by status = ${response.data?['sessions_by_status']}',
      );

      setState(() {
        _dashboardData = response.data;
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message ?? 'Error loading dashboard data'),
          ),
        );
      }
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Selamat Pagi';
    } else if (hour < 15) {
      return 'Selamat Siang';
    } else if (hour < 18) {
      return 'Selamat Sore';
    } else {
      return 'Selamat Malam';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadDashboardData,
                child: CustomScrollView(
                  slivers: [
                    // Custom Header
                    SliverToBoxAdapter(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF4A90E2), Color(0xFF357ABD)],
                          ),
                        ),
                        child: Column(
                          children: [
                            // Profile Header
                            Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 28,
                                        backgroundColor: Colors.white,
                                        child: Text(
                                          _userName.isNotEmpty
                                              ? _userName[0].toUpperCase()
                                              : 'U',
                                          style: TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF4A90E2),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _userName,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            _userEmail,
                                            style: TextStyle(
                                              color: Colors.white.withValues(
                                                alpha: 0.9,
                                              ),
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(
                                        alpha: 0.2,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: IconButton(
                                      icon: const Icon(
                                        Icons.notifications_outlined,
                                        color: Colors.white,
                                      ),
                                      onPressed: () {},
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Greeting Card
                            Padding(
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.1,
                                      ),
                                      blurRadius: 10,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _getGreeting(),
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            'Trainer SRT Corp',
                                            style: TextStyle(
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF4A90E2),
                                            ),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Color(0xFFE3F2FD),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Icon(
                                            Icons.touch_app,
                                            color: Color(0xFF4A90E2),
                                            size: 28,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Content
                    SliverPadding(
                      padding: const EdgeInsets.all(20),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          // Summary Cards
                          _buildSummaryCards(),

                          const SizedBox(height: 20),

                          // Quick Actions
                          _buildQuickActions(),

                          const SizedBox(height: 20),

                          // Charts
                          _buildChartCard(
                            title: 'Training (7 Hari Terakhir)',
                            chart: _buildBarChart(),
                          ),
                        ]),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Filter Report',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            if (_selectedDivisionId != null ||
                _selectedMonth != null ||
                _selectedDateRange != null)
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _selectedDivisionId = null;
                    _selectedDivisionName = null;
                    _selectedMonth = null;
                    _selectedDateRange = null;
                  });
                  _loadDashboardData();
                },
                icon: const Icon(Icons.clear, size: 18),
                label: const Text('Reset'),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
              ),
          ],
        ),
        const SizedBox(height: 12),

        // Filter Cards
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Per Division Filter
              _buildFilterRow(
                icon: Icons.business,
                label: 'Per Divisi',
                value: _selectedDivisionName ?? 'Semua Divisi',
                color: Colors.blue,
                onTap: _showDivisionPicker,
              ),
              const Divider(height: 24),

              // Per Month Filter
              Opacity(
                opacity: _selectedDateRange != null ? 0.5 : 1.0,
                child: _buildFilterRow(
                  icon: Icons.calendar_month,
                  label: 'Per Bulan',
                  value:
                      _selectedMonth ??
                      (_selectedDateRange != null
                          ? 'Tidak Tersedia'
                          : 'Pilih Bulan'),
                  color: _selectedDateRange != null
                      ? Colors.grey
                      : Colors.orange,
                  onTap: _showMonthPicker,
                ),
              ),
              const Divider(height: 24),

              // Date Range Filter
              Opacity(
                opacity: _selectedMonth != null ? 0.5 : 1.0,
                child: _buildFilterRow(
                  icon: Icons.date_range,
                  label: 'Rentang Waktu',
                  value: _selectedDateRange != null
                      ? '${_formatDate(_selectedDateRange!.start)} - ${_formatDate(_selectedDateRange!.end)}'
                      : (_selectedMonth != null
                            ? 'Tidak Tersedia'
                            : 'Pilih Rentang'),
                  color: _selectedMonth != null ? Colors.grey : Colors.purple,
                  onTap: _showDateRangePicker,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Generate PDF Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isGeneratingPDF ? null : _generatePDFReport,
            icon: _isGeneratingPDF
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.picture_as_pdf),
            label: Text(
              _isGeneratingPDF ? 'Membuat PDF...' : 'Generate Report PDF',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF4A90E2),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showDivisionPicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pilih Divisi'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blue.withValues(alpha: 0.1),
                  child: const Icon(Icons.all_inclusive, color: Colors.blue),
                ),
                title: const Text('Semua Divisi'),
                onTap: () {
                  setState(() {
                    _selectedDivisionId = null;
                    _selectedDivisionName = null;
                  });
                  Navigator.pop(context);
                  _loadDashboardData();
                },
              ),
              const Divider(),
              ..._divisions
                  .map(
                    (division) => ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.blue.withValues(alpha: 0.1),
                        child: Text(
                          division.name.substring(0, 1).toUpperCase(),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                      title: Text(division.name),
                      subtitle: division.description != null
                          ? Text(
                              division.description!,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            )
                          : null,
                      onTap: () {
                        setState(() {
                          _selectedDivisionId = division.id;
                          _selectedDivisionName = division.name;
                        });
                        Navigator.pop(context);
                        _loadDashboardData();
                      },
                    ),
                  )
                  .toList(),
            ],
          ),
        ),
      ),
    );
  }

  void _showMonthPicker() {
    // Check if date range is already selected
    if (_selectedDateRange != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Rentang waktu sudah dipilih. Reset filter untuk memilih bulan.',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pilih Bulan'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: months.length,
            itemBuilder: (context, index) {
              final year = DateTime.now().year;
              return ListTile(
                title: Text('${months[index]} $year'),
                onTap: () {
                  setState(() => _selectedMonth = '${months[index]} $year');
                  Navigator.pop(context);
                  _loadDashboardData();
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void _showDateRangePicker() async {
    // Check if month is already selected
    if (_selectedMonth != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Bulan sudah dipilih. Reset filter untuk memilih rentang waktu.',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _selectedDateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Color(0xFF4A90E2),
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _selectedDateRange = picked);
      _loadDashboardData();
    }
  }

  Future<void> _generatePDFReport() async {
    if (_dashboardData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tidak ada data untuk generate PDF'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isGeneratingPDF = true);

    try {
      final pdf = pw.Document();
      final summary = _dashboardData!['summary'] ?? {};
      final period = _dashboardData!['period'] ?? {};

      // Generate PDF pages
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(width: 2, color: PdfColors.blue900),
                  color: PdfColors.blue50,
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'LAPORAN STATISTIK TRAINING',
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue900,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      'TnD System - Training Dashboard Report',
                      style: pw.TextStyle(
                        fontSize: 12,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),

              // Period Info
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey200,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Periode Laporan',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text('Dari: ${period['from'] ?? 'N/A'}'),
                    pw.Text('Sampai: ${period['to'] ?? 'N/A'}'),
                    if (_selectedDivisionName != null)
                      pw.Text('Divisi: $_selectedDivisionName'),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),

              // Summary Statistics
              pw.Text(
                'Ringkasan Statistik',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 12),

              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey400),
                children: [
                  _buildTableRow(
                    'Total Sesi Training',
                    '${summary['total_sessions'] ?? 0}',
                  ),
                  _buildTableRow(
                    'Sesi Selesai',
                    '${summary['completed_sessions'] ?? 0}',
                  ),
                  _buildTableRow(
                    'Sesi Berlangsung',
                    '${summary['in_progress_sessions'] ?? 0}',
                  ),
                  _buildTableRow(
                    'Total Trainer',
                    '${summary['total_trainers'] ?? 0}',
                  ),
                  _buildTableRow(
                    'Rata-rata Score',
                    '${summary['overall_average_score'] ?? '0.0'}',
                  ),
                  _buildTableRow(
                    'Completion Rate',
                    '${summary['completion_rate'] ?? 0}%',
                  ),
                  _buildTableRow(
                    'Total Foto',
                    '${summary['total_photos'] ?? 0}',
                  ),
                ],
              ),

              pw.SizedBox(height: 20),

              // Footer
              pw.Spacer(),
              pw.Divider(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Dicetak oleh: $_userName',
                    style: const pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.grey600,
                    ),
                  ),
                  pw.Text(
                    'Tanggal: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                    style: const pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.grey600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );

      // Add photo attachments pages
      final photos = _dashboardData!['photos'] as List<dynamic>? ?? [];
      if (photos.isNotEmpty) {
        // Create photo pages (max 4 photos per page)
        for (int i = 0; i < photos.length; i += 4) {
          final pagePhotos = photos.skip(i).take(4).toList();

          // Load all photos for this page before building
          final photoWidgets = await Future.wait(
            pagePhotos.map((photo) => _buildPhotoItem(photo)).toList(),
          );

          pdf.addPage(
            pw.Page(
              pageFormat: PdfPageFormat.a4,
              margin: const pw.EdgeInsets.all(40),
              build: (context) => pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Header
                  pw.Container(
                    padding: const pw.EdgeInsets.all(12),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(width: 1, color: PdfColors.blue900),
                      color: PdfColors.blue50,
                    ),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'LAMPIRAN FOTO TRAINING',
                          style: pw.TextStyle(
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blue900,
                          ),
                        ),
                        pw.Text(
                          'Halaman ${(i ~/ 4) + 1}',
                          style: pw.TextStyle(
                            fontSize: 12,
                            color: PdfColors.grey700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  pw.SizedBox(height: 20),

                  // Photos grid (2x2)
                  pw.Expanded(
                    child: pw.GridView(
                      crossAxisCount: 2,
                      childAspectRatio: 1,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      children: photoWidgets,
                    ),
                  ),

                  pw.SizedBox(height: 10),
                  pw.Divider(),
                  pw.Text(
                    'Dicetak oleh: $_userName - ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                    style: const pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.grey600,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      }

      // Save PDF
      final output = await getTemporaryDirectory();
      final file = File(
        '${output.path}/training_report_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );
      await file.writeAsBytes(await pdf.save());

      if (mounted) {
        setState(() => _isGeneratingPDF = false);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('PDF Report berhasil dibuat!'),
            backgroundColor: Color(0xFF4A90E2),
            action: SnackBarAction(
              label: 'Buka',
              textColor: Colors.white,
              onPressed: () {
                OpenFile.open(file.path);
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isGeneratingPDF = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<pw.Widget> _buildPhotoItem(dynamic photo) async {
    try {
      final photoPath = photo['photo_path'] ?? '';
      final caption = photo['caption'] ?? 'No caption';
      final outletName = photo['outlet_name'] ?? 'N/A';
      final sessionDate = photo['session_date'] ?? 'N/A';

      // Load image from server
      final url = 'http://192.168.1.19/tnd_system/tnd_system/$photoPath';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final imageBytes = response.bodyBytes;
        final image = pw.MemoryImage(imageBytes);

        return pw.Container(
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey400),
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Container(
                  decoration: pw.BoxDecoration(
                    borderRadius: const pw.BorderRadius.only(
                      topLeft: pw.Radius.circular(8),
                      topRight: pw.Radius.circular(8),
                    ),
                  ),
                  child: pw.ClipRRect(
                    horizontalRadius: 8,
                    verticalRadius: 8,
                    child: pw.Image(image, fit: pw.BoxFit.cover),
                  ),
                ),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      caption,
                      style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: pw.TextOverflow.clip,
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Outlet: $outletName',
                      style: const pw.TextStyle(
                        fontSize: 8,
                        color: PdfColors.grey700,
                      ),
                      maxLines: 1,
                    ),
                    pw.Text(
                      'Tanggal: $sessionDate',
                      style: const pw.TextStyle(
                        fontSize: 8,
                        color: PdfColors.grey700,
                      ),
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      } else {
        // If image fails to load, show placeholder
        return _buildPhotoPlaceholder(caption, outletName, sessionDate);
      }
    } catch (e) {
      // If error occurs, show placeholder
      return _buildPhotoPlaceholder(
        photo['caption'] ?? 'Error loading',
        photo['outlet_name'] ?? 'N/A',
        photo['session_date'] ?? 'N/A',
      );
    }
  }

  pw.Widget _buildPhotoPlaceholder(
    String caption,
    String outletName,
    String sessionDate,
  ) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
        borderRadius: pw.BorderRadius.circular(8),
        color: PdfColors.grey200,
      ),
      child: pw.Column(
        mainAxisAlignment: pw.MainAxisAlignment.center,
        children: [
          pw.Icon(
            pw.IconData(0xe3f4), // camera icon
            size: 40,
            color: PdfColors.grey600,
          ),
          pw.SizedBox(height: 8),
          pw.Padding(
            padding: const pw.EdgeInsets.all(8),
            child: pw.Column(
              children: [
                pw.Text(
                  caption,
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                  ),
                  textAlign: pw.TextAlign.center,
                  maxLines: 2,
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Outlet: $outletName',
                  style: const pw.TextStyle(
                    fontSize: 8,
                    color: PdfColors.grey700,
                  ),
                  maxLines: 1,
                ),
                pw.Text(
                  'Tanggal: $sessionDate',
                  style: const pw.TextStyle(
                    fontSize: 8,
                    color: PdfColors.grey700,
                  ),
                  maxLines: 1,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.TableRow _buildTableRow(String label, String value) {
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text(
            label,
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
        ),
        pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(value)),
      ],
    );
  }

  Widget _buildSummaryCards() {
    if (_dashboardData == null) {
      return const Center(child: Text('Belum ada data'));
    }

    final summary = _dashboardData?['summary'] ?? {};

    // Parse with proper type conversion - backend might return string or int
    int totalSessions =
        int.tryParse(summary['total_sessions']?.toString() ?? '0') ?? 0;
    int completedSessions =
        int.tryParse(summary['completed_sessions']?.toString() ?? '0') ?? 0;
    int pendingSessions =
        int.tryParse(summary['pending_sessions']?.toString() ?? '0') ?? 0;
    int trainers =
        int.tryParse(summary['total_trainers']?.toString() ?? '0') ?? 0;

    // DEBUG: Print raw and parsed values
    print('DEBUG SUMMARY RAW: $summary');
    print(
      'DEBUG SUMMARY CARDS: totalSessions=$totalSessions, completedSessions=$completedSessions, pendingSessions=$pendingSessions, trainers=$trainers',
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Overview',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                title: 'Total Sesi',
                value: totalSessions.toString(),
                icon: Icons.assignment,
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                title: 'Selesai',
                value: completedSessions.toString(),
                icon: Icons.check_circle,
                color: Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                title: 'Pending',
                value: pendingSessions.toString(),
                icon: Icons.pending,
                color: Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                title: 'Trainer',
                value: trainers.toString(),
                icon: Icons.person,
                color: Colors.purple,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartCard({required String title, required Widget chart}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Icon(Icons.more_vert, color: Colors.grey[400]),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(height: 200, child: chart),
        ],
      ),
    );
  }

  Widget _buildBarChart() {
    final dailyTrend = _dashboardData?['daily_trend'] as List<dynamic>? ?? [];

    if (dailyTrend.isEmpty) {
      return const Center(child: Text('Belum ada data'));
    }

    final List<BarChartGroupData> barGroups = [];
    double maxY = 10;

    for (int i = 0; i < dailyTrend.length && i < 7; i++) {
      final trend = dailyTrend[i];
      final count = (trend['sessions_count'] ?? 0).toDouble();
      if (count > maxY) maxY = count;

      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [BarChartRodData(toY: count, color: Colors.blue, width: 12)],
        ),
      );
    }

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: (maxY + 5).ceilToDouble(),
        barTouchData: BarTouchData(enabled: false),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() < dailyTrend.length) {
                  final date = dailyTrend[value.toInt()]['date'];
                  return Text(
                    date.toString().substring(5, 10),
                    style: const TextStyle(fontSize: 10),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) => Text(
                value.toInt().toString(),
                style: const TextStyle(fontSize: 10),
              ),
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
        ),
        gridData: FlGridData(
          show: true,
          drawHorizontalLine: true,
          drawVerticalLine: true,
        ),
        barGroups: barGroups,
      ),
    );
  }
}

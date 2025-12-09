import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/user_model.dart';
import '../models/outlet_model.dart';
import '../models/visit_model.dart';
import '../services/visit_service.dart';

class VisitDetailScreen extends StatefulWidget {
  final VisitModel visit;
  final OutletModel outlet;
  final UserModel currentUser;

  const VisitDetailScreen({
    super.key,
    required this.visit,
    required this.outlet,
    required this.currentUser,
  });

  @override
  State<VisitDetailScreen> createState() => _VisitDetailScreenState();
}

class _VisitDetailScreenState extends State<VisitDetailScreen> {
  final _visitService = VisitService();
  
  Map<String, List<Map<String, dynamic>>> _groupedResponses = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    print('🕐 Visit check_in_time: ${widget.visit.checkInTime}');
    print('🕐 Visit visitDate: ${widget.visit.visitDate}');
    print('🕐 Visit status: ${widget.visit.status}');
    print('💰 Visit financial data:');
    print('   - uangOmsetModal: ${widget.visit.uangOmsetModal}');
    print('   - cash: ${widget.visit.cash}');
    print('   - total: ${widget.visit.total}');
    print('📊 Visit assessment data:');
    print('   - crewInCharge: ${widget.visit.crewInCharge}');
    print('   - kategoric: ${widget.visit.kategoric}');
    print('   - statusKeuangan: ${widget.visit.statusKeuangan}');
    _loadVisitDetails();
  }

  Future<void> _loadVisitDetails() async {
    setState(() => _isLoading = true);
    try {
      print('🔵 Loading visit details for visit ID: ${widget.visit.id}');
      // Get visit responses grouped by category
      final response = await _visitService.getVisitResponses(widget.visit.id);
      
      print('🔵 Visit responses success: ${response.success}');
      print('🔵 Visit responses data count: ${response.data?.length ?? 0}');
      
      if (response.success && response.data != null) {
        // Group responses by category
        final Map<String, List<Map<String, dynamic>>> grouped = {};
        
        for (var item in response.data!) {
          final categoryName = item['category_name'] ?? 'Uncategorized';
          if (!grouped.containsKey(categoryName)) {
            grouped[categoryName] = [];
          }
          grouped[categoryName]!.add(item);
        }
        
        print('🔵 Grouped responses: ${grouped.keys.toList()}');
        print('🔵 Total categories: ${grouped.length}');
        print('🔵 _groupedResponses.isEmpty BEFORE: ${_groupedResponses.isEmpty}');
        
        setState(() {
          _groupedResponses = grouped;
          _isLoading = false;
        });
        
        print('🔵 _groupedResponses.isEmpty AFTER: ${_groupedResponses.isEmpty}');
      } else {
        print('❌ Failed to load responses: ${response.message}');
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('❌ Error loading visit details: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Visit Detail'),
        elevation: 0,
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: Theme.of(context).primaryColor,
              ),
            )
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Visit Info Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(24),
                        bottomRight: Radius.circular(24),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha(51),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.store,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.outlet.name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    widget.outlet.code,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildInfoRow(
                          Icons.calendar_today,
                          _formatDate(widget.visit.visitDate),
                        ),
                        const SizedBox(height: 8),
                        _buildInfoRow(
                          Icons.access_time,
                          _formatTime(widget.visit.visitDate),
                        ),
                        const SizedBox(height: 8),
                        _buildInfoRow(
                          Icons.info_outline,
                          _formatStatus(widget.visit.status),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Financial & Assessment Section
                  if (widget.visit.uangOmsetModal != null || 
                      widget.visit.kategoric != null ||
                      widget.visit.crewInCharge != null)
                    _buildFinancialAssessmentSection(),

                  const SizedBox(height: 24),

                  // Checklist Results
                  Builder(
                    builder: (context) {
                      print('🏗️ Building checklist section...');
                      print('🏗️ _groupedResponses.isEmpty: ${_groupedResponses.isEmpty}');
                      print('🏗️ _groupedResponses.length: ${_groupedResponses.length}');
                      print('🏗️ _groupedResponses.keys: ${_groupedResponses.keys.toList()}');
                      
                      if (_groupedResponses.isEmpty) {
                        print('⚠️ Showing "No Checklist Data" message');
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(48),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.checklist_outlined,
                                  size: 80,
                                  color: Colors.grey[300],
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  'No Checklist Data',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'This visit has no checklist responses yet.\nPlease complete the checklist during your visit.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[500],
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      } else {
                        print('✅ Building ${_groupedResponses.length} category sections');
                        return Column(
                          children: _groupedResponses.entries.map((entry) {
                            print('📦 Building category: ${entry.key} with ${entry.value.length} items');
                            return _buildCategorySection(
                              entry.key,
                              entry.value,
                            );
                          }).toList(),
                        );
                      }
                    },
                  ),

                  const SizedBox(height: 100),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.white70),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildCategorySection(String categoryName, List<Map<String, dynamic>> items) {
    print('🎯 Building category section: $categoryName');
    print('🎯 Total items: ${items.length}');
    
    // Calculate statistics - handle both 'ok'/'not_ok' and 'pass'/'fail'
    int totalItems = items.length;
    int passedItems = items.where((item) {
      final val = (item['response_value'] ?? '').toString().toLowerCase();
      final isPassed = val == 'pass' || val == 'ok';
      if (isPassed) print('   ✅ ${item['item_text']}: $val');
      return isPassed;
    }).length;
    int failedItems = items.where((item) {
      final val = (item['response_value'] ?? '').toString().toLowerCase();
      final isFailed = val == 'fail' || val == 'not_ok' || val == 'not ok';
      if (isFailed) print('   ❌ ${item['item_text']}: $val');
      return isFailed;
    }).length;
    int naItems = items.where((item) {
      final val = (item['response_value'] ?? '').toString().toLowerCase();
      final isNa = val == 'na' || val == 'n/a';
      if (isNa) print('   ⚪ ${item['item_text']}: $val');
      return isNa;
    }).length;
    
    print('🎯 Stats: Pass=$passedItems, Fail=$failedItems, NA=$naItems');
    
    double percentage = totalItems > 0 ? (passedItems / totalItems * 100) : 0;

    return Container(
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withAlpha(13),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        categoryName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$totalItems items',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getPercentageColor(percentage).withAlpha(26),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${percentage.toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _getPercentageColor(percentage),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Statistics
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    '✓',
                    passedItems.toString(),
                    'Pass',
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    '✗',
                    failedItems.toString(),
                    'Fail',
                    Colors.red,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'N/A',
                    naItems.toString(),
                    'N/A',
                    Colors.grey,
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Items List
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = items[index];
              return _buildChecklistItem(item);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String symbol, String count, String label, Color color) {
    return Column(
      children: [
        Text(
          symbol,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          count,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildChecklistItem(Map<String, dynamic> item) {
    final responseValue = (item['response_value'] ?? '').toString().toLowerCase();
    final itemText = item['item_text'] ?? '';
    final notes = item['notes'];
    final photoUrl = item['photo_url'];
    
    print('📷 Item: $itemText, Photo URL: $photoUrl');

    IconData icon;
    Color color;

    // Handle both 'ok'/'not_ok'/'na' (from DB) and 'pass'/'fail'/'na' (from app)
    if (responseValue == 'pass' || responseValue == 'ok') {
      icon = Icons.check_circle;
      color = Colors.green;
    } else if (responseValue == 'fail' || responseValue == 'not_ok' || responseValue == 'not ok') {
      icon = Icons.cancel;
      color = Colors.red;
    } else if (responseValue == 'na' || responseValue == 'n/a') {
      icon = Icons.remove_circle;
      color = Colors.grey;
    } else {
      icon = Icons.help_outline;
      color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withAlpha(13),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(51)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                              decoration: BoxDecoration(
                                color: color.withAlpha(26),
                                shape: BoxShape.circle,
                              ),                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      itemText,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (notes != null && notes.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.note, size: 14, color: Colors.grey[600]),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                notes,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (photoUrl != null && photoUrl.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          photoUrl,
                          height: 120,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              height: 120,
                              color: Colors.grey[200],
                              child: Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                                ),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            print('❌ Error loading photo: $error');
                            print('❌ Photo URL: $photoUrl');
                            return Container(
                              height: 120,
                              color: Colors.grey[200],
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.broken_image,
                                    color: Colors.grey[400],
                                    size: 48,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Failed to load image',
                                    style: TextStyle(
                                      color: Colors.grey[500],
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getPercentageColor(double percentage) {
    if (percentage >= 80) return Colors.green;
    if (percentage >= 60) return Colors.orange;
    return Colors.red;
  }

  String _formatStatus(String status) {
    switch (status) {
      case 'completed':
        return 'Completed';
      case 'in_progress':
        return 'In Progress';
      case 'scheduled':
        return 'Scheduled';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatTime(DateTime date) {
    // Use check_in_time if available, otherwise use visit_date time
    final checkInTime = widget.visit.checkInTime;
    if (checkInTime != null && checkInTime.isNotEmpty) {
      // Parse HH:mm:ss format
      final parts = checkInTime.split(':');
      if (parts.length >= 2) {
        return '${parts[0]}:${parts[1]}';
      }
    }
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildFinancialAssessmentSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.orange.withAlpha(26),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.assessment,
                      color: Colors.orange,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Financial & Assessment',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 16),

              // Financial Data Section
              if (widget.visit.uangOmsetModal != null ||
                  widget.visit.cash != null ||
                  widget.visit.total != null) ...[
                const Text(
                  '💰 Data Keuangan',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                
                if (widget.visit.uangOmsetModal != null)
                  _buildFinancialItem('Uang Omset + Modal', widget.visit.uangOmsetModal!),
                if (widget.visit.uangDitukar != null)
                  _buildFinancialItem('Uang Ditukar', widget.visit.uangDitukar!),
                if (widget.visit.cash != null)
                  _buildFinancialItem('Cash', widget.visit.cash!),
                if (widget.visit.qris != null)
                  _buildFinancialItem('QRIS', widget.visit.qris!),
                if (widget.visit.debitKredit != null)
                  _buildFinancialItem('Debit/Kredit', widget.visit.debitKredit!),
                
                const SizedBox(height: 8),
                const Divider(thickness: 1.5),
                const SizedBox(height: 8),
                
                if (widget.visit.total != null)
                  _buildFinancialItem('TOTAL', widget.visit.total!, isBold: true),
                
                const SizedBox(height: 20),
              ],

              // Assessment Data Section
              if (widget.visit.kategoric != null ||
                  widget.visit.leadtime != null ||
                  widget.visit.statusKeuangan != null ||
                  widget.visit.crewInCharge != null) ...[
                const Text(
                  '📊 Data Assessment',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),

                if (widget.visit.crewInCharge != null)
                  _buildAssessmentItem('Crew in Charge', widget.visit.crewInCharge!),
                
                if (widget.visit.kategoric != null)
                  _buildAssessmentItem('Kategoric', _formatKategoric(widget.visit.kategoric!)),
                
                if (widget.visit.leadtime != null)
                  _buildAssessmentItem('Leadtime', '${widget.visit.leadtime} hari'),
                
                if (widget.visit.statusKeuangan != null)
                  _buildAssessmentItem('Status', _formatStatusKeuangan(widget.visit.statusKeuangan!)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFinancialItem(String label, double value, {bool isBold = false}) {
    final formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            formatter.format(value),
            style: TextStyle(
              fontSize: 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: isBold ? Colors.green[700] : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssessmentItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatKategoric(String kategoric) {
    switch (kategoric) {
      case 'minor':
        return 'Minor';
      case 'major':
        return 'Major';
      case 'ZT':
        return 'Zero Tolerance (ZT)';
      default:
        return kategoric;
    }
  }

  String _formatStatusKeuangan(String status) {
    switch (status) {
      case 'open':
        return 'Open';
      case 'close':
        return 'Close';
      default:
        return status;
    }
  }
}

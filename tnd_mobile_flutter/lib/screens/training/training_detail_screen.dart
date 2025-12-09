import 'package:flutter/material.dart';
import '../../models/training/training_models.dart';
import '../../models/api_response.dart';
import '../../services/training/training_service.dart';

class TrainingDetailScreen extends StatefulWidget {
  final TrainingScheduleModel schedule;

  const TrainingDetailScreen({
    Key? key,
    required this.schedule,
  }) : super(key: key);

  @override
  State<TrainingDetailScreen> createState() => _TrainingDetailScreenState();
}

class _TrainingDetailScreenState extends State<TrainingDetailScreen> {
  final TrainingService _trainingService = TrainingService();
  List<TrainingChecklistCategory> _categories = [];
  bool _isLoadingCategories = false;
  String? _crewLeaderName;
  
  // Cache for items to avoid repeated API calls
  final Map<int, Future<ApiResponse<List<TrainingChecklistItem>>>> _itemsFutureCache = {};

  @override
  void initState() {
    super.initState();
    _loadTrainingCategories();
  }

  Future<void> _loadTrainingCategories() async {
    setState(() {
      _isLoadingCategories = true;
    });

    try {
      // Try to load from session detail first (includes items)
      final detailResponse = await _trainingService.getSessionDetail(widget.schedule.id);
      if (detailResponse.success && detailResponse.data != null) {
        final data = detailResponse.data!;
        print('Session Detail Response: $data');
        
        // Extract crew leader name from signatures
        if (data['signatures'] is Map && data['signatures']['leader'] is Map) {
          setState(() {
            _crewLeaderName = data['signatures']['leader']['name'];
          });
          print('Crew Leader Name from signatures: $_crewLeaderName');
        }

        // Extract categories from evaluation_summary (has full structure with points)
        if (data['evaluation_summary'] is List && (data['evaluation_summary'] as List).isNotEmpty) {
          final summaryList = List<Map<String, dynamic>>.from(data['evaluation_summary']);
          List<TrainingChecklistCategory> loadedCategories = [];
          
          print('=== LOADING CATEGORIES FROM SESSION DETAIL ===');
          print('evaluation_summary has ${summaryList.length} items');

          for (var item in summaryList) {
            print('Category item keys: ${item.keys}');
            print('Category item: $item');
            
            final categoryId = item['category_id'] ?? item['id'] ?? 0;
            print('Extracted category_id: $categoryId (from category_id: ${item['category_id']}, from id: ${item['id']})');
            
            final category = TrainingChecklistCategory(
              id: categoryId,
              name: item['category_name'] ?? item['name'] ?? 'Unknown',
              description: item['description'],
              isActive: true,
              createdAt: DateTime.now(),
            );
            loadedCategories.add(category);
          }
          
          print('=== LOADED ${loadedCategories.length} CATEGORIES ===');
          for (var cat in loadedCategories) {
            print('Category: id=${cat.id}, name=${cat.name}');
          }

          setState(() {
            _categories = loadedCategories;
          });
          return;
        }
      }

      // Fallback: load categories separately
      final response = await _trainingService.getChecklistCategories();
      if (response.success && response.data != null) {
        setState(() {
          _categories = response.data!;
        });
      }
    } catch (e) {
      print('Error loading training categories: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading training categories: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoadingCategories = false;
      });
    }
  }

  /// Load full details including items for PDF generation
  Future<List<Map<String, dynamic>>> _loadFullCategoriesWithItems() async {
    try {
      print('DEBUG: Loading full categories with items for PDF...');
      
      // First, try to get from session detail (which has evaluation_summary with full structure)
      final detailResponse = await _trainingService.getSessionDetail(widget.schedule.id);
      
      if (detailResponse.success && detailResponse.data != null) {
        final data = detailResponse.data!;
        
        // Check if evaluation_summary has the full structure with points
        if (data['evaluation_summary'] is List && (data['evaluation_summary'] as List).isNotEmpty) {
          final summaryList = List<Map<String, dynamic>>.from(data['evaluation_summary']);
          
          // Verify the structure has points
          if (summaryList.first['points'] != null) {
            print('✓ evaluation_summary has full structure with ${summaryList.length} categories');
            return summaryList;
          }
        }
      }
      
      // Fallback: Load categories and items separately
      print('Loading categories and items separately...');
      final categoryResponse = await _trainingService.getChecklistCategories();
      
      if (categoryResponse.success && categoryResponse.data != null) {
        List<Map<String, dynamic>> fullCategories = [];
        
        for (final category in categoryResponse.data!) {
          final itemsResponse = await _trainingService.getChecklistItems(categoryId: category.id);
          
          final points = itemsResponse.success && itemsResponse.data != null
            ? itemsResponse.data!
                .map((item) => {
                  'id': item.id,
                  'point_text': item.itemText,
                  'rating': null,
                  'notes': null
                })
                .toList()
            : [];
          
          fullCategories.add({
            'category_id': category.id,
            'category_name': category.name,
            'description': category.description,
            'points': points
          });
        }
        
        print('✓ Loaded ${fullCategories.length} categories with items separately');
        return fullCategories;
      }
      
      print('✗ Failed to load categories');
      return [];
      
    } catch (e) {
      print('ERROR loading full categories: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          // Modern Gradient Header
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.blue[700]!,
                      Colors.blue[500]!,
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 60, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.schedule.outletName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.calendar_today, color: Colors.white, size: 14),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${widget.schedule.scheduledDate.day}/${widget.schedule.scheduledDate.month}/${widget.schedule.scheduledDate.year}',
                                    style: const TextStyle(color: Colors.white, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.access_time, color: Colors.white, size: 14),
                                  const SizedBox(width: 6),
                                  Text(
                                    widget.schedule.scheduledTime,
                                    style: const TextStyle(color: Colors.white, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                _getStatusColor(widget.schedule.status),
                                _getStatusColor(widget.schedule.status).withValues(alpha: 0.8),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: _getStatusColor(widget.schedule.status).withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _getStatusIcon(widget.schedule.status),
                                color: Colors.white,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _formatStatus(widget.schedule.status),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            backgroundColor: Colors.blue[700],
            ),
          
          // Details Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Quick Info Grid
                  Row(
                    children: [
                      Expanded(
                        child: _buildQuickInfoCard(
                          icon: Icons.store,
                          title: 'Outlet',
                          value: widget.schedule.outletName,
                          gradient: [Colors.blue[400]!, Colors.blue[600]!],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildQuickInfoCard(
                          icon: Icons.person,
                          title: 'Trainer',
                          value: widget.schedule.trainerName ?? 'N/A',
                          gradient: [Colors.green[400]!, Colors.green[600]!],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Trainer Information Card
                  _buildModernCard(
                    title: 'Informasi Trainer',
                    icon: Icons.person_outline,
                    color: Colors.green,
                    children: [
                      _buildInfoRow(Icons.person, 'Nama Trainer', widget.schedule.trainerName ?? 'N/A', Colors.green),
                      if (widget.schedule.trainerId != null) ...[
                        const SizedBox(height: 8),
                        _buildInfoRow(Icons.badge, 'ID Trainer', widget.schedule.trainerId.toString(), Colors.green),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Crew Leader Information Card
                  _buildModernCard(
                    title: 'Informasi Crew Leader',
                    icon: Icons.supervisor_account,
                    color: Colors.orange,
                    children: [
                      _buildInfoRow(
                        Icons.supervisor_account,
                        'Nama Crew Leader',
                        _crewLeaderName != null && _crewLeaderName!.isNotEmpty
                            ? _crewLeaderName!
                            : 'TBD',
                        Colors.orange,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Date and Time Card
                  _buildModernCard(
                    title: 'Waktu & Tanggal',
                    icon: Icons.calendar_today,
                    color: Colors.purple,
                    children: [
                      _buildInfoRow(
                        Icons.calendar_today,
                        'Tanggal',
                        '${widget.schedule.scheduledDate.day}/${widget.schedule.scheduledDate.month}/${widget.schedule.scheduledDate.year}',
                        Colors.purple,
                      ),
                      const SizedBox(height: 8),
                      _buildInfoRow(Icons.access_time, 'Waktu', widget.schedule.scheduledTime, Colors.purple),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Status Information Card
                  _buildModernCard(
                    title: 'Status',
                    icon: Icons.info_outline,
                    color: Colors.blue,
                    children: [
                      _buildInfoRow(Icons.info, 'Status Jadwal', _formatStatus(widget.schedule.status), Colors.blue),
                      const SizedBox(height: 8),
                      _buildInfoRow(
                        Icons.access_time,
                        'Dibuat Pada',
                        widget.schedule.createdAt != null
                            ? '${widget.schedule.createdAt!.day}/${widget.schedule.createdAt!.month}/${widget.schedule.createdAt!.year}'
                            : 'N/A',
                        Colors.blue,
                      ),
                      if (widget.schedule.updatedAt != null) ...[
                        const SizedBox(height: 8),
                        _buildInfoRow(
                          Icons.update,
                          'Diperbarui Pada',
                          '${widget.schedule.updatedAt!.day}/${widget.schedule.updatedAt!.month}/${widget.schedule.updatedAt!.year}',
                          Colors.blue,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),                  // Training Categories
                  _buildModernCard(
                    title: 'Kategori Training',
                    icon: Icons.checklist,
                    color: Colors.teal,
                    trailing: _isLoadingCategories
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : null,
                    children: [
                      if (_categories.isEmpty && !_isLoadingCategories)
                        Center(
                          child: Column(
                            children: [
                              Icon(Icons.folder_open, size: 48, color: Colors.grey[400]),
                              const SizedBox(height: 8),
                              Text(
                                'Belum ada kategori training',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (_isLoadingCategories)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(
                              'Memuat kategori training...',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ),
                      if (!_isLoadingCategories && _categories.isNotEmpty)
                        Column(
                          children: _categories.map((category) {
                            return _buildCategoryWithItems(category);
                          }).toList(),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Info message - PDF only available from reports
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.blue[50]!,
                          Colors.blue[100]!.withValues(alpha: 0.3),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.blue[200]!, width: 1),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.blue[700],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.info_outline, color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'PDF laporan training dapat diakses melalui menu Report',
                              style: TextStyle(
                                color: Colors.blue[900],
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickInfoCard({
    required IconData icon,
    required String title,
    required String value,
    required List<Color> gradient,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: gradient[0].withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.white, size: 28),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernCard({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
    Widget? trailing,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            color.withValues(alpha: 0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color, color.withValues(alpha: 0.7)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                if (trailing != null) trailing,
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatStatus(String status) {
    switch (status) {
      case 'scheduled':
        return 'Dijadwalkan';
      case 'ongoing':
        return 'Sedang Berlangsung';
      case 'completed':
        return 'Selesai';
      case 'cancelled':
        return 'Dibatalkan';
      case 'expired':
        return 'Kadaluarsa';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'scheduled':
        return Colors.blue;
      case 'ongoing':
        return Colors.orange;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'expired':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'scheduled':
        return Icons.schedule;
      case 'ongoing':
        return Icons.play_circle;
      case 'completed':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel;
      case 'expired':
        return Icons.access_time;
      default:
        return Icons.help;
    }
  }

  /// Get checklist items with caching to avoid repeated API calls
  Future<ApiResponse<List<TrainingChecklistItem>>> _getChecklistItemsWithCache(int categoryId) {
    // Return cached future if available
    if (_itemsFutureCache.containsKey(categoryId)) {
      print('Using cached future for category $categoryId');
      return _itemsFutureCache[categoryId]!;
    }

    // Create new future and cache it
    final future = _trainingService.getChecklistItems(categoryId: categoryId);
    _itemsFutureCache[categoryId] = future;
    
    print('Created new future for category $categoryId');
    return future;
  }

  /// Build category card with expandable items
  Widget _buildCategoryWithItems(TrainingChecklistCategory category) {
    return Column(
          children: [
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: ExpansionTile(
                title: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.blue[100],
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        Icons.category,
                        color: Colors.blue[700],
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  category.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.blue[50],
                                  border: Border.all(color: Colors.blue[300]!),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'ID: ${category.id}',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.blue[700],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (category.description != null && category.description!.isNotEmpty)
                            Text(
                              category.description!,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 11,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                children: [
                  FutureBuilder<ApiResponse<List<TrainingChecklistItem>>>(
                    future: _getChecklistItemsWithCache(category.id),
                    builder: (context, snapshot) {
                      // Show loading state
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[700]!),
                            ),
                          ),
                        );
                      }

                      // Handle errors and exceptions
                      if (snapshot.hasError) {
                        print('Error loading items for category ${category.id}: ${snapshot.error}');
                        return Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Gagal memuat items',
                                style: TextStyle(
                                  color: Colors.red[600],
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${snapshot.error}',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      // Check if response is successful
                      if (snapshot.hasData) {
                        final response = snapshot.data!;
                        
                        if (!response.success || response.data == null) {
                          print('API response not successful for category ${category.id}: ${response.message}');
                          return Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Gagal memuat items',
                                  style: TextStyle(
                                    color: Colors.red[600],
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  response.message ?? 'Unknown error',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        final items = response.data!;
                        
                        if (items.isEmpty) {
                          return Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(
                              'Tidak ada item checklist',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          );
                        }

                        return Column(
                          children: items.map((item) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.green[100],
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Icon(
                                      Icons.check_circle_outline,
                                      color: Colors.green[700],
                                      size: 16,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      item.itemText,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey[800],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        );
                      }

                      // Default error state
                      return Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          'Tidak ada data',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        );
  }
}


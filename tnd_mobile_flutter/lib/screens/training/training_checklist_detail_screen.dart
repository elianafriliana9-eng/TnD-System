import 'package:flutter/material.dart';
import '../../services/training/training_service.dart';
import '../../models/api_response.dart';
import 'training_category_form_screen.dart';
import 'training_item_form_screen.dart';

class TrainingChecklistDetailScreen extends StatefulWidget {
  final int checklistId;
  final String checklistName;

  const TrainingChecklistDetailScreen({
    Key? key,
    required this.checklistId,
    required this.checklistName,
  }) : super(key: key);

  @override
  State<TrainingChecklistDetailScreen> createState() => _TrainingChecklistDetailScreenState();
}

class _TrainingChecklistDetailScreenState extends State<TrainingChecklistDetailScreen> {
  final TrainingService _trainingService = TrainingService();
  late Future<ApiResponse<Map<String, dynamic>>> _checklistDetailFuture;
  Map<String, dynamic>? _checklistDetail;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadChecklistDetail();
  }

  void _loadChecklistDetail() {
    setState(() {
      _isLoading = true;
    });
    _checklistDetailFuture = _trainingService.getChecklistDetail(widget.checklistId);
    _checklistDetailFuture.then((response) {
      if (response.success && response.data != null) {
        setState(() {
          _checklistDetail = response.data;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        _showError(response.message ?? 'Failed to load checklist');
      }
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  Future<void> _addCategory() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => const TrainingCategoryFormScreen(),
      ),
    );

    if (result == true) {
      _showSuccess('Kategori berhasil ditambahkan');
      _loadChecklistDetail();
    }
  }

  Future<void> _addItem(int categoryId) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => TrainingItemFormScreen(categoryId: categoryId),
      ),
    );

    if (result == true) {
      _showSuccess('Item berhasil ditambahkan');
      _loadChecklistDetail();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.checklistName),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _checklistDetail == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      const Text('Gagal memuat data checklist'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadChecklistDetail,
                        child: const Text('Coba Lagi'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      // Header Info
                      Card(
                        margin: const EdgeInsets.all(16),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.checklistName,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              if (_checklistDetail?['description'] != null) ...[
                                const SizedBox(height: 8),
                                Text(
                                  _checklistDetail!['description'],
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  _StatCard(
                                    label: 'Total Kategori',
                                    value: '${_checklistDetail?['categories']?.length ?? 0}',
                                    icon: Icons.category,
                                  ),
                                  _StatCard(
                                    label: 'Total Item',
                                    value: '${_getTotalItems()}',
                                    icon: Icons.checklist,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Categories List
                      if (_checklistDetail?['categories'] != null && (_checklistDetail!['categories'] as List).isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Kategori & Item',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 12),
                              ..._buildCategoriesList(),
                            ],
                          ),
                        )
                      else
                        Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            children: [
                              Icon(Icons.inbox, size: 64, color: Colors.grey[400]),
                              const SizedBox(height: 16),
                              const Text('Belum ada kategori'),
                            ],
                          ),
                        ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addCategory,
        backgroundColor: Colors.green[700],
        child: const Icon(Icons.add),
        tooltip: 'Tambah Kategori',
      ),
    );
  }

  int _getTotalItems() {
    int total = 0;
    if (_checklistDetail?['categories'] is List) {
      for (var category in _checklistDetail!['categories'] as List) {
        if (category['points'] is List) {
          total += (category['points'] as List).length;
        }
      }
    }
    return total;
  }

  List<Widget> _buildCategoriesList() {
    if (_checklistDetail?['categories'] is! List) return [];

    return (_checklistDetail!['categories'] as List).asMap().entries.map((entry) {
      Map<String, dynamic> category = entry.value;

      return _CategoryCard(
        categoryName: category['name'] ?? 'Unknown',
        categoryDescription: category['description'],
        categoryId: category['id'] ?? 0,
        items: category['points'] is List ? category['points'] as List : [],
        onAddItem: () => _addItem(category['id'] ?? 0),
      );
    }).toList();
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        elevation: 0,
        color: Colors.green[50],
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Icon(icon, color: Colors.green[700], size: 28),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[700],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryCard extends StatefulWidget {
  final String categoryName;
  final String? categoryDescription;
  final int categoryId;
  final List<dynamic> items;
  final VoidCallback onAddItem;

  const _CategoryCard({
    required this.categoryName,
    this.categoryDescription,
    required this.categoryId,
    required this.items,
    required this.onAddItem,
  });

  @override
  State<_CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<_CategoryCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.green[700],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.categoryName,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.green[700],
                              ),
                        ),
                        if (widget.categoryDescription != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            widget.categoryDescription!,
                            style: Theme.of(context).textTheme.bodySmall,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${widget.items.length}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.items.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            Icon(Icons.list, size: 48, color: Colors.grey[300]),
                            const SizedBox(height: 12),
                            const Text('Belum ada item'),
                          ],
                        ),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: widget.items.length,
                      itemBuilder: (context, index) {
                        var item = widget.items[index];
                        return _ItemTile(
                          itemNumber: index + 1,
                          itemText: item['item_text'] ?? item['question'] ?? 'Unknown',
                          itemDescription: item['description'],
                        );
                      },
                    ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: widget.onAddItem,
                      icon: const Icon(Icons.add),
                      label: const Text('Tambah Item'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[700],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ItemTile extends StatelessWidget {
  final int itemNumber;
  final String itemText;
  final String? itemDescription;

  const _ItemTile({
    required this.itemNumber,
    required this.itemText,
    this.itemDescription,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(
            color: Colors.green[700]!,
            width: 4,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green[700],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  itemNumber.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  itemText,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (itemDescription != null && itemDescription!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              itemDescription!,
              style: Theme.of(context).textTheme.bodySmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}

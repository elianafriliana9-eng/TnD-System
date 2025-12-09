import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter/material.dart';
import 'dart:ui';
import '../../services/training/training_service.dart';
import '../../models/training/training_models.dart';
import 'training_category_form_screen.dart';
import 'training_item_form_screen.dart';

class TrainingChecklistManagementScreen extends StatefulWidget {
  const TrainingChecklistManagementScreen({Key? key}) : super(key: key);

  @override
  State<TrainingChecklistManagementScreen> createState() =>
      _TrainingChecklistManagementScreenState();
}

class _TrainingChecklistManagementScreenState
    extends State<TrainingChecklistManagementScreen> {
  final TrainingService _trainingService = TrainingService();
  List<TrainingChecklistCategory> _categories = [];
  Map<int, List<TrainingChecklistItem>> _itemsByCategory = {};
  Map<int, bool> _expandedCategories = {}; // Track expanded state
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    final categoriesResponse = await _trainingService.getChecklistCategories();
    if (categoriesResponse.success && categoriesResponse.data != null) {
      _categories = categoriesResponse.data!;

      // Load items for each category
      _itemsByCategory = {};
      for (var category in _categories) {
        final itemsResponse = await _trainingService.getChecklistItems(
          categoryId: category.id,
        );
        if (itemsResponse.success && itemsResponse.data != null) {
          _itemsByCategory[category.id] = itemsResponse.data!;
        } else {
          _itemsByCategory[category.id] = [];
        }
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _addCategory() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const TrainingCategoryFormScreen(),
      ),
    );

    if (result == true) {
      _loadData();
    }
  }

  Future<void> _addItem(int categoryId) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TrainingItemFormScreen(categoryId: categoryId),
      ),
    );

    if (result == true) {
      _loadData();
    }
  }

  void _showDeleteConfirm(int itemId, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Item'),
        content: const Text('Apakah Anda yakin ingin menghapus item ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteItem(int itemId) async {
    try {
      final response = await _trainingService.deleteChecklistItem(itemId);

      if (response.success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Item berhasil dihapus'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
          await _loadData();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.message ?? 'Gagal menghapus item'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                // Glass Morphism Header
                SliverAppBar(
                  expandedHeight: 200,
                  floating: false,
                  pinned: true,
                  backgroundColor: Colors.transparent,
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF26A69A),
                            Color(0xFF00897B),
                          ],
                        ),
                      ),
                      child: SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.checklist_rounded,
                                      color: Colors.white,
                                      size: 32,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Manajemen Checklist',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          '${_categories.length} Kategori',
                                          style: TextStyle(
                                            color: Colors.white.withValues(alpha: 0.9),
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  actions: [
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: _addCategory,
                        color: Colors.white,
                        iconSize: 28,
                      ),
                    ),
                  ],
                ),
                
                // Content
                SliverToBoxAdapter(
                  child: RefreshIndicator(
                    onRefresh: _loadData,
                    child: _categories.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(40),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.checklist_rounded,
                                    size: 80,
                                    color: Colors.grey[300],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Belum ada kategori checklist',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: const EdgeInsets.all(16),
                            itemCount: _categories.length,
                            itemBuilder: (context, catIndex) {
                              final category = _categories[catIndex];
                              final items = _itemsByCategory[category.id] ?? [];
                              final isExpanded =
                                  _expandedCategories[category.id] ?? false;

                              return _buildGlassCard(
                                category: category,
                                items: items,
                                isExpanded: isExpanded,
                                catIndex: catIndex,
                              );
                            },
                          ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildGlassCard({
    required TrainingChecklistCategory category,
    required List<TrainingChecklistItem> items,
    required bool isExpanded,
    required int catIndex,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.9),
                  Colors.white.withValues(alpha: 0.7),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.5),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Color(0xFF26A69A).withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: InkWell(
              onTap: () {
                setState(() {
                  _expandedCategories[category.id] = !isExpanded;
                });
              },
              borderRadius: BorderRadius.circular(20),
              child: Column(
                children: [
                  // Header Section
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        // Icon Container
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Color(0xFF26A69A),
                                Color(0xFF00897B),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Color(0xFF26A69A).withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.folder_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Category Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                category.name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF263238),
                                ),
                              ),
                              if (category.description != null &&
                                  category.description!.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    category.description!,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey[600],
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        // Badge & Actions
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Color(0xFF26A69A).withValues(alpha: 0.2),
                                    Color(0xFF00897B).withValues(alpha: 0.2),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Color(0xFF26A69A).withValues(alpha: 0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.list_alt,
                                    size: 14,
                                    color: Color(0xFF26A69A),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${items.length}',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF26A69A),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.edit_note_rounded),
                                iconSize: 20,
                                color: Color(0xFF26A69A),
                                onPressed: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          TrainingCategoryFormScreen(
                                        category: category,
                                      ),
                                    ),
                                  );
                                  if (result == true) {
                                    _loadData();
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 4),
                            AnimatedRotation(
                              turns: isExpanded ? 0.5 : 0,
                              duration: const Duration(milliseconds: 200),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.expand_more,
                                  color: Color(0xFF26A69A),
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // Divider
                  if (isExpanded)
                    Container(
                      height: 1,
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            Color(0xFF26A69A).withValues(alpha: 0.3),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  
                  // Expanded Content
                  if (isExpanded)
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0xFFE0F2F1).withValues(alpha: 0.3),
                            Color(0xFFE0F2F1).withValues(alpha: 0.1),
                          ],
                        ),
                      ),
                      child: Column(
                        children: [
                          // Items List
                          if (items.isEmpty)
                            Padding(
                              padding: const EdgeInsets.all(32),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.inbox_outlined,
                                    size: 48,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Belum ada item',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: items.length,
                                separatorBuilder: (context, index) => const SizedBox(height: 12),
                                itemBuilder: (context, itemIndex) {
                                  final item = items[itemIndex];
                                  return Slidable(
                                    key: ValueKey(item.id),
                                    endActionPane: ActionPane(
                                      motion: const ScrollMotion(),
                                      children: [
                                        SlidableAction(
                                          onPressed: (context) async {
                                            final result = await Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    TrainingItemFormScreen(
                                                  categoryId: category.id,
                                                  item: item,
                                                ),
                                              ),
                                            );
                                            if (result == true) {
                                              _loadData();
                                            }
                                          },
                                          backgroundColor: Color(0xFF26A69A),
                                          foregroundColor: Colors.white,
                                          icon: Icons.edit,
                                          label: 'Edit',
                                          borderRadius: BorderRadius.circular(12),
                                        ),

                                        SlidableAction(
                                          onPressed: (context) {
                                            _showDeleteConfirm(
                                              item.id,
                                              () {
                                                _deleteItem(item.id);
                                              },
                                            );
                                          },
                                          backgroundColor: Colors.red[400]!,
                                          foregroundColor: Colors.white,
                                          icon: Icons.delete,
                                          label: 'Delete',
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ],
                                    ),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.8),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Color(0xFF26A69A).withValues(alpha: 0.2),
                                        ),
                                      ),
                                      child: ListTile(
                                        contentPadding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 8,
                                        ),
                                        leading: Container(
                                          width: 36,
                                          height: 36,
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                Color(0xFF26A69A).withValues(alpha: 0.2),
                                                Color(0xFF00897B).withValues(alpha: 0.2),
                                              ],
                                            ),
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: Color(0xFF26A69A).withValues(alpha: 0.3),
                                            ),
                                          ),

                                          child: Center(
                                            child: Text(
                                              '${itemIndex + 1}',
                                              style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF26A69A),
                                              ),
                                            ),
                                          ),
                                        ),
                                        title: Text(
                                          item.itemText,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            color: Color(0xFF263238),
                                          ),
                                        ),
                                        subtitle: item.description != null &&
                                                item.description!.isNotEmpty
                                            ? Text(
                                                item.description!,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[600],
                                                ),
                                              )
                                            : null,
                                        trailing: Icon(
                                          Icons.chevron_right,
                                          color: Color(0xFF26A69A).withValues(alpha: 0.5),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          // Add Item Button
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Color(0xFF26A69A),
                                    Color(0xFF00897B),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Color(0xFF26A69A).withValues(alpha: 0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () => _addItem(category.id),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: const [
                                        Icon(
                                          Icons.add_circle_outline,
                                          color: Colors.white,
                                          size: 22,
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          'Tambah Item Baru',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
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
    );
  }
}

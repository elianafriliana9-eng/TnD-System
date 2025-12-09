import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/outlet_model.dart';
import '../models/user_model.dart';
import '../models/checklist_model.dart';
import '../models/visit_model.dart';
import '../services/visit_service.dart';
import '../services/checklist_service.dart';

/// Checklist Screen
/// Fill checklist items with responses (✓/✗/N/A)
class ChecklistScreen extends StatefulWidget {
  final OutletModel outlet;
  final ChecklistTemplateModel template;
  final UserModel currentUser;

  const ChecklistScreen({
    super.key,
    required this.outlet,
    required this.template,
    required this.currentUser,
  });

  @override
  State<ChecklistScreen> createState() => _ChecklistScreenState();
}

class _ChecklistScreenState extends State<ChecklistScreen> {
  final _visitService = VisitService();
  final _checklistService = ChecklistService();
  final _imagePicker = ImagePicker();

  VisitModel? _currentVisit;
  ChecklistTemplateModel? _templateWithItems;
  Map<int, String> _responses = {}; // checklist_item_id -> response ('ok', 'not_ok', 'na')
  Map<int, String> _notes = {}; // checklist_item_id -> notes
  Map<int, List<File>> _photos = {}; // checklist_item_id -> list of photos
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializeVisit();
  }

  Future<void> _initializeVisit() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Get template with items
      final templateResponse = await _checklistService.getTemplateById(widget.template.id);
      
      if (!templateResponse.success || templateResponse.data == null) {
        throw Exception(templateResponse.message ?? 'Failed to load checklist');
      }

      // Create visit
      final visitResponse = await _visitService.createVisit(
        outletId: widget.outlet.id,
        notes: 'Visit to ${widget.outlet.name}',
      );

      if (!mounted) return;

      if (visitResponse.success && visitResponse.data != null) {
        setState(() {
          _currentVisit = visitResponse.data;
          _templateWithItems = templateResponse.data;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = visitResponse.message ?? 'Failed to create visit';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _saveResponse(int itemId, String response) async {
    if (_currentVisit == null) return;

    setState(() {
      _responses[itemId] = response;
    });

    // Save to backend
    try {
      await _visitService.saveChecklistResponse(
        visitId: _currentVisit!.id,
        checklistItemId: itemId,
        response: response,
        notes: _notes[itemId],
      );
    } catch (e) {
      print('Error saving response: $e');
    }
  }

  Future<void> _addPhoto(int itemId) async {
    if (_currentVisit == null) return;

    final XFile? photo = await _imagePicker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1280,    // Reduced from 1920
      maxHeight: 720,    // Reduced from 1080
      imageQuality: 70,  // Reduced from 85 for better compression
    );

    if (photo == null) return;

    final file = File(photo.path);

    // Upload photo
    setState(() => _isSubmitting = true);

    try {
      final response = await _visitService.uploadPhoto(
        visitId: _currentVisit!.id,
        photoFile: file,
        checklistItemId: itemId,
        description: 'Finding for item',
      );

      if (!mounted) return;

      if (response.success) {
        setState(() {
          _photos[itemId] = [...(_photos[itemId] ?? []), file];
          _isSubmitting = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Photo uploaded successfully')),
        );
      } else {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response.message ?? 'Upload failed')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _completeVisit() async {
    if (_currentVisit == null) return;

    // Check if all required items are answered
    final totalItems = _templateWithItems?.items?.length ?? 0;
    final answeredItems = _responses.length;

    if (answeredItems < totalItems) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Incomplete Checklist'),
          content: Text(
            'You have answered $answeredItems out of $totalItems items.\n\nDo you want to submit anyway?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Submit'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;
    }

    setState(() => _isSubmitting = true);

    try {
      final response = await _visitService.completeVisit(
        visitId: _currentVisit!.id,
        notes: 'Completed visit',
      );

      if (!mounted) return;

      if (response.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Visit completed successfully!')),
        );
        Navigator.of(context).pop(); // Return to previous screen
      } else {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response.message ?? 'Failed to complete visit')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  // Helper methods for grouped display
  Map<String, List<ChecklistItemModel>> _getGroupedItems() {
    final items = _templateWithItems?.items ?? [];
    final Map<String, List<ChecklistItemModel>> grouped = {};
    
    for (final item in items) {
      final category = item.category ?? 'Uncategorized';
      if (!grouped.containsKey(category)) {
        grouped[category] = [];
      }
      grouped[category]!.add(item);
    }
    
    return grouped;
  }

  int _getListItemCount() {
    final grouped = _getGroupedItems();
    int count = 0;
    
    for (final entry in grouped.entries) {
      count++; // Category header
      count += entry.value.length; // Items in category
    }
    
    return count;
  }

  Widget _buildListItem(int index) {
    final grouped = _getGroupedItems();
    int currentIndex = 0;
    
    for (final entry in grouped.entries) {
      // Category header
      if (currentIndex == index) {
        return _buildCategoryHeader(entry.key);
      }
      currentIndex++;
      
      // Items in this category
      for (final item in entry.value) {
        if (currentIndex == index) {
          return _buildChecklistItem(item);
        }
        currentIndex++;
      }
    }
    
    return const SizedBox.shrink();
  }

  Widget _buildCategoryHeader(String category) {
    // Get category progress
    final items = _getGroupedItems()[category] ?? [];
    final answeredInCategory = items.where((item) => _responses.containsKey(item.id)).length;
    final totalInCategory = items.length;
    
    return Container(
      margin: const EdgeInsets.only(top: 16, bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade700, Colors.blue.shade500],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withAlpha(77),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(51),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.folder_outlined,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$answeredInCategory / $totalInCategory items completed',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withAlpha(230),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(51),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$totalInCategory',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final answeredItems = _responses.length;
    final totalItems = _templateWithItems?.items?.length ?? 0;
    final progress = totalItems > 0 ? answeredItems / totalItems : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.outlet.name),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey[300],
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                      const SizedBox(height: 16),
                      Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _initializeVisit,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.all(16),
                      color: Theme.of(context).primaryColor.withAlpha(26),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _templateWithItems?.name ?? '',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Progress: $answeredItems / $totalItems items',
                                  style: TextStyle(
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Checklist Items
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _getListItemCount(),
                        itemBuilder: (context, index) {
                          return _buildListItem(index);
                        },
                      ),
                    ),

                    // Complete Button
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(26),
                            blurRadius: 4,
                            offset: const Offset(0, -2),
                          ),
                        ],
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : _completeVisit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isSubmitting
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Text(
                                  'Complete Visit',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildChecklistItem(ChecklistItemModel item) {
    final response = _responses[item.id];
    final photos = _photos[item.id] ?? [];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: response == 'ok'
              ? Colors.green.withAlpha(128)
              : response == 'not_ok'
                  ? Colors.red.withAlpha(128)
                  : response == 'na'
                      ? Colors.grey.withAlpha(77)
                      : Colors.grey.withAlpha(26),
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Item Text with status indicator
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${item.itemOrder}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item.itemText,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
                  ),
                ),
                if (response != null)
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: response == 'ok'
                          ? Colors.green.withAlpha(26)
                          : response == 'not_ok'
                              ? Colors.red.withAlpha(26)
                              : Colors.grey.withAlpha(26),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      response == 'ok'
                          ? Icons.check_circle
                          : response == 'not_ok'
                              ? Icons.cancel
                              : Icons.remove_circle_outline,
                      size: 20,
                      color: response == 'ok'
                          ? Colors.green
                          : response == 'not_ok'
                              ? Colors.red
                              : Colors.grey,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Response Buttons
            Row(
              children: [
                Expanded(
                  child: _buildResponseButton(
                    item.id,
                    'ok',
                    '✓',
                    Colors.green,
                    response == 'ok',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildResponseButton(
                    item.id,
                    'not_ok',
                    '✗',
                    Colors.red,
                    response == 'not_ok',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildResponseButton(
                    item.id,
                    'na',
                    'N/A',
                    Colors.grey,
                    response == 'na',
                  ),
                ),
              ],
            ),

            // Add Photo Button (shown for not_ok responses)
            if (response == 'not_ok') ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _isSubmitting ? null : () => _addPhoto(item.id),
                icon: const Icon(Icons.camera_alt),
                label: Text('Add Photo (${photos.length})'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.orange,
                ),
              ),
            ],

            // Show uploaded photos
            if (photos.isNotEmpty) ...[
              const SizedBox(height: 12),
              SizedBox(
                height: 80,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: photos.length,
                  itemBuilder: (context, index) {
                    return Container(
                      margin: const EdgeInsets.only(right: 8),
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        image: DecorationImage(
                          image: FileImage(photos[index]),
                          fit: BoxFit.cover,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResponseButton(
    int itemId,
    String value,
    String label,
    Color color,
    bool isSelected,
  ) {
    return ElevatedButton(
      onPressed: () => _saveResponse(itemId, value),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? color : Colors.white,
        foregroundColor: isSelected ? Colors.white : color,
        side: BorderSide(color: color),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

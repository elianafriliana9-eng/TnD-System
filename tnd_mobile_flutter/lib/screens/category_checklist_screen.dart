import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/outlet_model.dart';
import '../models/user_model.dart';
import '../models/category_model.dart';
import '../models/visit_model.dart';
import '../services/category_service.dart';
import '../services/visit_service.dart';

/// Category Checklist Screen
/// Fill checklist items for a specific category
class CategoryChecklistScreen extends StatefulWidget {
  final OutletModel outlet;
  final UserModel currentUser;
  final VisitModel visit;
  final ChecklistCategoryModel category;
  final VoidCallback? onCompleted;

  const CategoryChecklistScreen({
    super.key,
    required this.outlet,
    required this.currentUser,
    required this.visit,
    required this.category,
    this.onCompleted,
  });

  @override
  State<CategoryChecklistScreen> createState() => _CategoryChecklistScreenState();
}

class _CategoryChecklistScreenState extends State<CategoryChecklistScreen> {
  final _categoryService = CategoryService();
  final _visitService = VisitService();
  final _imagePicker = ImagePicker();

  List<CategoryItemModel> _items = [];
  Map<int, String> _responses = {}; // item_id -> response ('ok', 'not_ok', 'na')
  Map<int, String> _notes = {}; // item_id -> notes
  Map<int, String> _nokRemarks = {}; // item_id -> NOK remarks (catatan kenapa NOK)
  Map<int, TextEditingController> _nokRemarksControllers = {}; // Controllers for NOK remarks
  Map<int, List<File>> _photos = {}; // item_id -> list of LOCAL photos (not uploaded yet)
  Map<int, int> _serverPhotoCount = {}; // item_id -> count of photos already on server
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  @override
  void dispose() {
    // Dispose all NOK remarks controllers
    for (var controller in _nokRemarksControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadItems() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load category items
      final response = await _categoryService.getCategoryItems(widget.category.id);

      if (!mounted) return;

      if (response.success && response.data != null) {
        setState(() {
          _items = response.data!;
        });
        
        // Load saved responses for this visit
        await _loadSavedResponses();
        
        if (!mounted) return;
        setState(() {
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = response.message ?? 'Failed to load items';
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

  Future<void> _loadSavedResponses() async {
    try {
      print('🔵 Loading saved responses for visit ${widget.visit.id}');
      
      // Get visit responses
      final responsesResult = await _visitService.getVisitResponses(widget.visit.id);
      
      print('📊 API Response: ${responsesResult.success}');
      print('📊 API Data: ${responsesResult.data}');
      
      if (responsesResult.success && responsesResult.data != null) {
        final responses = responsesResult.data!;
        
        print('📊 Total responses from API: ${responses.length}');
        
        // Load saved responses and photos
        for (var resp in responses) {
          print('🔍 Processing response: $resp');
          
          final itemId = resp['checklist_item_id'] as int;
          final response = resp['response_value']?.toString() ?? ''; // Use response_value, not response
          
          print('🔍 Item ID: $itemId, Raw response: "$response"');
          
          // Map database format (OK/NOT OK/N/A) to app format (ok/not_ok/na)
          String mappedResponse = 'na';
          final responseLower = response.toLowerCase().trim();
          
          if (responseLower == 'ok') {
            mappedResponse = 'ok';
          } else if (responseLower == 'not ok' || responseLower == 'not_ok' || responseLower == 'notok') {
            mappedResponse = 'not_ok';
          } else if (responseLower == 'n/a' || responseLower == 'na') {
            mappedResponse = 'na';
          } else {
            print('⚠️ Unknown response format: "$response" - defaulting to N/A');
          }
          
          _responses[itemId] = mappedResponse;
          if (resp['notes'] != null && resp['notes'].toString().isNotEmpty) {
            _notes[itemId] = resp['notes'].toString();
          }
          
          // Load NOK remarks if exists
          if (resp['nok_remarks'] != null && resp['nok_remarks'].toString().isNotEmpty) {
            final remarks = resp['nok_remarks'].toString();
            _nokRemarks[itemId] = remarks;
            // Create controller with pre-filled value
            _nokRemarksControllers[itemId] = TextEditingController(text: remarks);
            print('📝 Loaded NOK remarks for item $itemId: "$remarks"');
          }
          
          // Track server photos count (photos already uploaded)
          if (resp['photo_url'] != null && resp['photo_url'].toString().isNotEmpty) {
            _serverPhotoCount[itemId] = (_serverPhotoCount[itemId] ?? 0) + 1;
            print('📷 Photo exists for item $itemId: ${resp['photo_url']}');
          }
          
          print('✅ Loaded response for item $itemId: "$response" -> "$mappedResponse"');
        }
        
        print('✅ Loaded ${_responses.length} saved responses');
        print('📷 Loaded ${_serverPhotoCount.values.fold(0, (a, b) => a + b)} server photos');
        print('📊 Final _responses map: $_responses');
      } else {
        print('⚠️ No saved responses found or failed to load');
      }
    } catch (e) {
      print('⚠️ Error loading saved responses: $e');
      // Don't throw error, just continue with empty responses
    }
  }

  Future<void> _saveResponse(int itemId, String response) async {
    // CRITICAL FIX: Prevent changing response if photos already uploaded for NOT OK
    final currentResponse = _responses[itemId];
    final hasPhotos = (_serverPhotoCount[itemId] ?? 0) > 0 || (_photos[itemId]?.isNotEmpty ?? false);
    
    // If changing FROM not_ok TO ok/na AND has photos, show warning
    if (currentResponse == 'not_ok' && response != 'not_ok' && hasPhotos) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange),
              SizedBox(width: 12),
              Text('Confirm Change'),
            ],
          ),
          content: Text(
            'This item has ${_serverPhotoCount[itemId] ?? 0} photo(s) uploaded.\n\n'
            'Changing from "NOT OK" to "${response.toUpperCase()}" will DELETE all associated photos.\n\n'
            'Are you sure you want to continue?',
            style: TextStyle(height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
              ),
              child: Text('Yes, Delete Photos'),
            ),
          ],
        ),
      );
      
      if (confirmed != true) {
        print('⚠️ User cancelled response change to prevent photo deletion');
        return; // Don't change response
      }
      
      // Clear local photos if user confirmed
      setState(() {
        _photos[itemId] = [];
        _serverPhotoCount[itemId] = 0;
      });
    }
    
    setState(() {
      _responses[itemId] = response;
      
      // If NOT changing to NOT OK, clear NOK remarks
      if (response != 'not_ok') {
        _nokRemarks.remove(itemId);
        _nokRemarksControllers[itemId]?.clear();
      } else {
        // Initialize controller if not exists for NOT OK
        if (!_nokRemarksControllers.containsKey(itemId)) {
          _nokRemarksControllers[itemId] = TextEditingController();
        }
      }
    });

    // Save to backend
    try {
      print('🔵 Saving response for item $itemId: $response');
      final result = await _visitService.saveChecklistResponse(
        visitId: widget.visit.id,
        checklistItemId: itemId,
        response: response,
        notes: _notes[itemId],
        nokRemarks: _nokRemarks[itemId], // Send NOK remarks
      );
      
      if (result.success) {
        print('✅ Response saved successfully');
      } else {
        print('❌ Failed to save response: ${result.message}');
      }
    } catch (e) {
      print('❌ Error saving response: $e');
    }
  }

  Future<void> _addPhoto(int itemId) async {
    final XFile? photo = await _imagePicker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1280,    // Reduced from 1920
      maxHeight: 720,    // Reduced from 1080
      imageQuality: 70,  // Reduced from 85 for better compression
    );

    if (photo == null) {
      print('📷 Photo capture cancelled');
      return;
    }

    final file = File(photo.path);
    print('📷 Photo selected: ${photo.path}');
    print('📷 File size: ${await file.length()} bytes');

    setState(() => _isSubmitting = true);

    try {
      print('📷 Uploading photo for visit ${widget.visit.id}, item $itemId');
      final response = await _visitService.uploadPhoto(
        visitId: widget.visit.id,
        photoFile: file,
        checklistItemId: itemId,
        description: 'Finding for item',
      );

      if (!mounted) return;

      if (response.success) {
        print('✅ Photo uploaded successfully: ${response.data}');
        setState(() {
          _photos[itemId] = [...(_photos[itemId] ?? []), file];
          _isSubmitting = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Photo uploaded successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        print('❌ Photo upload failed: ${response.message}');
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message ?? 'Upload failed'),
            backgroundColor: Colors.red,
          ),
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

  void _finishCategory() {
    widget.onCompleted?.call();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final answeredItems = _responses.length;
    final totalItems = _items.length;
    final progress = totalItems > 0 ? answeredItems / totalItems : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category.name),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.white.withAlpha(77),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
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
                      Text(_error!, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadItems,
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
                      color: Colors.blue.shade50,
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.outlet.name,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
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
                        itemCount: _items.length,
                        itemBuilder: (context, index) {
                          final item = _items[index];
                          return _buildChecklistItem(item);
                        },
                      ),
                    ),

                    // Done Button
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
                          onPressed: _finishCategory,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade700,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Done',
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

  Widget _buildChecklistItem(CategoryItemModel item) {
    final response = _responses[item.id];
    final localPhotos = _photos[item.id] ?? [];
    final serverPhotoCount = _serverPhotoCount[item.id] ?? 0;
    final totalPhotos = localPhotos.length + serverPhotoCount;

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

            // NOK Remarks TextField (shown when NOT OK selected)
            if (response == 'not_ok') ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.orange.shade200,
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.edit_note,
                          size: 18,
                          color: Colors.orange.shade700,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Catatan NOK (opsional)',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.orange.shade900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _nokRemarksControllers[item.id],
                      decoration: InputDecoration(
                        hintText: 'Contoh: Lantai kotor, wastafel rusak...',
                        hintStyle: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade500,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.orange.shade400, width: 2),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.all(12),
                      ),
                      maxLines: 3,
                      style: const TextStyle(fontSize: 14),
                      onChanged: (value) {
                        // Update NOK remarks in real-time
                        setState(() {
                          _nokRemarks[item.id] = value;
                        });
                        // Auto-save to backend (only if response is not null)
                        if (response != null) {
                          _visitService.saveChecklistResponse(
                            visitId: widget.visit.id,
                            checklistItemId: item.id,
                            response: response,
                            notes: _notes[item.id],
                            nokRemarks: value.isNotEmpty ? value : null,
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],

            // Add Photo Button (shown for not_ok responses)
            if (response == 'not_ok') ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _isSubmitting ? null : () => _addPhoto(item.id),
                icon: const Icon(Icons.camera_alt),
                label: Text('Add Photo ($totalPhotos)${serverPhotoCount > 0 ? ' · $serverPhotoCount uploaded' : ''}'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.orange,
                ),
              ),
            ],

            // Show LOCAL photos (newly added, not yet uploaded)
            if (localPhotos.isNotEmpty) ...[
              const SizedBox(height: 12),
              SizedBox(
                height: 80,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: localPhotos.length,
                  itemBuilder: (context, index) {
                    return Container(
                      margin: const EdgeInsets.only(right: 8),
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        image: DecorationImage(
                          image: FileImage(localPhotos[index]),
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

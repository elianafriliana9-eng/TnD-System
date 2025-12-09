import 'package:flutter/material.dart';
import '../models/outlet_model.dart';
import '../models/user_model.dart';
import '../models/checklist_model.dart';
import '../services/outlet_service.dart';
import '../services/checklist_service.dart';
import 'checklist_screen.dart';

/// Outlet Selection Screen
/// User selects outlet to visit and checklist template
class OutletSelectionScreen extends StatefulWidget {
  final UserModel currentUser;

  const OutletSelectionScreen({
    super.key,
    required this.currentUser,
  });

  @override
  State<OutletSelectionScreen> createState() => _OutletSelectionScreenState();
}

class _OutletSelectionScreenState extends State<OutletSelectionScreen> {
  final _outletService = OutletService();
  final _checklistService = ChecklistService();

  List<OutletModel> _outlets = [];
  List<ChecklistTemplateModel> _templates = [];
  OutletModel? _selectedOutlet;
  ChecklistTemplateModel? _selectedTemplate;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load outlets filtered by user's division (with no limit to show all)
      final outletsResponse = await _outletService.getOutlets(
        divisionId: widget.currentUser.divisionId,
        limit: -1, // Get all outlets instead of just 10
      );

      // Load checklist templates
      final templatesResponse = await _checklistService.getTemplates();

      if (!mounted) return;

      if (outletsResponse.success && templatesResponse.success) {
        setState(() {
          _outlets = outletsResponse.data ?? [];
          _templates = templatesResponse.data ?? [];
          _isLoading = false;

          // Auto-select first template if only one available
          if (_templates.length == 1) {
            _selectedTemplate = _templates.first;
          }
        });
      } else {
        setState(() {
          _error = outletsResponse.message ?? templatesResponse.message ?? 'Failed to load data';
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

  Future<void> _startVisit() async {
    if (_selectedOutlet == null || _selectedTemplate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select outlet and checklist template')),
      );
      return;
    }

    // Navigate to checklist screen
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChecklistScreen(
          outlet: _selectedOutlet!,
          template: _selectedTemplate!,
          currentUser: widget.currentUser,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Start Visit'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
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
                        _error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadData,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Outlet Selection
                      Text(
                        'Select Outlet',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 12),
                      if (_outlets.isEmpty)
                        const Card(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Text('No outlets available'),
                          ),
                        )
                      else
                        ...(_outlets.map((outlet) => _buildOutletCard(outlet))),
                      const SizedBox(height: 24),

                      // Template Selection
                      Text(
                        'Select Checklist',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 12),
                      if (_templates.isEmpty)
                        const Card(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Text('No checklist templates available'),
                          ),
                        )
                      else
                        ...(_templates.map((template) => _buildTemplateCard(template))),
                      const SizedBox(height: 32),

                      // Start Visit Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _selectedOutlet != null && _selectedTemplate != null
                              ? _startVisit
                              : null,
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Start Visit',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildOutletCard(OutletModel outlet) {
    final isSelected = _selectedOutlet?.id == outlet.id;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: isSelected ? Theme.of(context).primaryColor.withAlpha(26) : null,
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedOutlet = outlet;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                Icons.store,
                color: isSelected ? Theme.of(context).primaryColor : Colors.grey,
                size: 32,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      outlet.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Theme.of(context).primaryColor : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      outlet.displayLocation,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    if (outlet.divisionName != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        outlet.divisionName!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: Theme.of(context).primaryColor,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTemplateCard(ChecklistTemplateModel template) {
    final isSelected = _selectedTemplate?.id == template.id;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: isSelected ? Theme.of(context).primaryColor.withAlpha(26) : null,
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedTemplate = template;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                Icons.checklist,
                color: isSelected ? Theme.of(context).primaryColor : Colors.grey,
                size: 32,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      template.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Theme.of(context).primaryColor : null,
                      ),
                    ),
                    if (template.description != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        template.description!,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: Theme.of(context).primaryColor,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

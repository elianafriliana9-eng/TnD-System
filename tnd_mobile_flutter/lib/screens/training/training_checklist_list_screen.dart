import 'package:flutter/material.dart';
import '../../services/training/training_service.dart';
import 'training_checklist_detail_screen.dart';
import 'training_category_form_screen.dart';

class TrainingChecklistListScreen extends StatefulWidget {
  const TrainingChecklistListScreen({Key? key}) : super(key: key);

  @override
  State<TrainingChecklistListScreen> createState() => _TrainingChecklistListScreenState();
}

class _TrainingChecklistListScreenState extends State<TrainingChecklistListScreen> {
  final TrainingService _trainingService = TrainingService();
  List<Map<String, dynamic>> _checklists = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadChecklists();
  }

  void _loadChecklists() {
    setState(() {
      _isLoading = true;
    });
    _trainingService.getChecklistCategories().then((response) {
      if (response.success && response.data != null) {
        setState(() {
          _checklists = response.data?.asMap().entries.map((entry) {
            var item = entry.value;
            return {
              'id': item.id,
              'name': item.name,
              'description': item.description,
              'isActive': item.isActive,
            };
          }).toList() ?? [];
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        _showError(response.message ?? 'Failed to load checklists');
      }
    }).catchError((error) {
      setState(() {
        _isLoading = false;
      });
      _showError('Error: $error');
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

  Future<void> _createChecklist() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => const TrainingCategoryFormScreen(),
      ),
    );

    if (result == true) {
      _showSuccess('Checklist berhasil dibuat');
      _loadChecklists();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Checklist Training'),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _checklists.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.folder_open, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      const Text('Belum ada checklist'),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _createChecklist,
                        icon: const Icon(Icons.add),
                        label: const Text('Buat Checklist'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[700],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () async {
                    _loadChecklists();
                    await Future.delayed(const Duration(milliseconds: 500));
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _checklists.length,
                    itemBuilder: (context, index) {
                      var checklist = _checklists[index];
                      return _ChecklistCard(
                        id: checklist['id'],
                        name: checklist['name'],
                        description: checklist['description'],
                        isActive: checklist['isActive'] ?? true,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TrainingChecklistDetailScreen(
                                checklistId: checklist['id'],
                                checklistName: checklist['name'],
                              ),
                            ),
                          ).then((_) {
                            _loadChecklists();
                          });
                        },
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createChecklist,
        backgroundColor: Colors.green[700],
        child: const Icon(Icons.add),
        tooltip: 'Buat Checklist Baru',
      ),
    );
  }
}

class _ChecklistCard extends StatelessWidget {
  final int id;
  final String name;
  final String? description;
  final bool isActive;
  final VoidCallback onTap;

  const _ChecklistCard({
    required this.id,
    required this.name,
    this.description,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.checklist,
                      color: Colors.green[700],
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (description != null && description!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            description!,
                            style: Theme.of(context).textTheme.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (isActive)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Aktif',
                        style: TextStyle(
                          color: Colors.green[700],
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Tekan untuk melihat detail',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                  ),
                  Icon(Icons.arrow_forward, color: Colors.grey[400], size: 18),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

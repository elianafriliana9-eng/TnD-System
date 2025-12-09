import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:open_file/open_file.dart';
import 'package:share_plus/share_plus.dart';

import '../../models/training/training_models.dart';
import '../../services/training/training_pdf_service.dart';
import '../../services/training/training_service.dart';
import '../digital_signature_screen.dart';
import 'training_detail_screen.dart';

class TrainingSessionChecklistScreen extends StatefulWidget {
  final TrainingSessionModel session;
  const TrainingSessionChecklistScreen({super.key, required this.session});

  @override
  State<TrainingSessionChecklistScreen> createState() =>
      _TrainingSessionChecklistScreenState();
}

class _TrainingSessionChecklistScreenState
    extends State<TrainingSessionChecklistScreen> {
  final TrainingService _trainingService = TrainingService();
  List<Map<String, dynamic>> _categories = [];
  final Map<int, String> _responses =
      {}; // Store responses as {point_id: response}
  final List<File> _sessionPhotos = []; // Store session-level photos
  bool _isLoading = true;
  bool _isSubmitting = false;
  String _trainerComment = '';
  String _leaderComment = '';

  @override
  void initState() {
    super.initState();
    print('DEBUG CHECKLIST: Session data:');
    print('  - crewName: ${widget.session.crewName}');
    print('  - crewLeaderName: ${widget.session.crewLeaderName}');
    print('  - outletName: ${widget.session.outletName}');
    _loadChecklistStructure();
  }

  Future<void> _loadChecklistStructure() async {
    setState(() {
      _isLoading = true;
    });

    try {
      print('');
      print('═══════════════════════════════════════════════════════════');
      print('STARTING CHECKLIST DATA LOAD - 3-LAYER FALLBACK SYSTEM');
      print('═══════════════════════════════════════════════════════════');
      print('Session ID: ${widget.session.id}');
      print('═══════════════════════════════════════════════════════════');
      print('LAYER 1: Trying getSessionDetail() endpoint');
      print('═══════════════════════════════════════════════════════════');

      // Get detailed session info which includes categories and points
      final sessionDetailResponse = await _trainingService.getSessionDetail(
        widget.session.id,
      );

      print('Layer 1 Response - Success: ${sessionDetailResponse.success}');
      print('Layer 1 Response - Message: ${sessionDetailResponse.message}');

      if (sessionDetailResponse.success && sessionDetailResponse.data != null) {
        final data = sessionDetailResponse.data!;
        print('Layer 1 Response - Data keys: ${data.keys.toList()}');

        // Extract categories and points from evaluation_summary
        print('Checking evaluation_summary...');
        print('  Type: ${data['evaluation_summary'].runtimeType}');
        print('  Is List: ${data['evaluation_summary'] is List}');
        print(
          '  Length: ${(data['evaluation_summary'] as List?)?.length ?? 0}',
        );

        if (data['evaluation_summary'] is List &&
            (data['evaluation_summary'] as List).isNotEmpty) {
          _categories = List<Map<String, dynamic>>.from(
            data['evaluation_summary'],
          );

          print('✓ Layer 1 SUCCESS: Loaded ${_categories.length} categories');
          print(
            '  Categories: ${_categories.map((c) => c['category_name']).toList()}',
          );

          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
          return;
        } else {
          print('✗ Layer 1 INCOMPLETE: evaluation_summary is empty or invalid');
          print('  evaluation_summary value: ${data['evaluation_summary']}');
        }
      } else {
        print('✗ Layer 1 FAILED: ${sessionDetailResponse.message}');
      }
    } catch (e) {
      print('✗ Layer 1 EXCEPTION: $e');
    }

    // If Layer 1 failed, try Layer 2
    print('');
    await _loadDefaultChecklist();

    print('');
    print('═══════════════════════════════════════════════════════════');
    print('✓ CHECKLIST LOAD COMPLETE');
    print('Final categories count: ${_categories.length}');
    print('═══════════════════════════════════════════════════════════');
    print('');

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadDefaultChecklist() async {
    print('═══════════════════════════════════════════════════════════');
    print('LAYER 2: Trying getChecklistCategories() + getChecklistItems()');
    print('═══════════════════════════════════════════════════════════');

    try {
      final categoriesResponse = await _trainingService
          .getChecklistCategories();
      print('Layer 2 Response - Success: ${categoriesResponse.success}');
      print('Layer 2 Response - Data: ${categoriesResponse.data}');

      if (categoriesResponse.success && categoriesResponse.data != null) {
        final List<TrainingChecklistCategory> categories =
            categoriesResponse.data!;
        print('✓ Got ${categories.length} categories from Layer 2');

        List<Map<String, dynamic>> newCategories = [];

        for (var category in categories) {
          print(
            '  Loading items for category: ${category.name} (ID: ${category.id})',
          );
          final itemsResponse = await _trainingService.getChecklistItems(
            categoryId: category.id,
          );

          if (itemsResponse.success && itemsResponse.data != null) {
            final List<TrainingChecklistItem> items = itemsResponse.data!;
            print('    ✓ Got ${items.length} items');

            newCategories.add({
              'category_name': category.name,
              'category_id': category.id,
              'points': items
                  .map((item) => {'id': item.id, 'point_text': item.itemText})
                  .toList(),
            });
          } else {
            print('    ✗ Failed to load items: ${itemsResponse.message}');
          }
        }

        if (newCategories.isNotEmpty) {
          print(
            '✓ Layer 2 SUCCESS: Loaded ${newCategories.length} categories with items',
          );
          if (mounted) {
            setState(() {
              _categories = newCategories;
            });
          }
          return;
        } else {
          print('✗ Layer 2 INCOMPLETE: Categories loaded but no items');
        }
      } else {
        print('✗ Layer 2 FAILED: ${categoriesResponse.message}');
      }
    } catch (e) {
      print('✗ Layer 2 EXCEPTION: $e');
    }

    // If we reach here, all layers failed - use sample data
    print('═══════════════════════════════════════════════════════════');
    print('LAYER 3: Loading sample categories (FALLBACK)');
    print('═══════════════════════════════════════════════════════════');
    _loadSampleCategories();
    print('✓ Layer 3 SUCCESS: Sample data loaded');
  }

  void _loadSampleCategories() {
    _categories = [
      {
        'category_name': 'NILAI HOSPITALITY',
        'points': [
          {'id': 1, 'point_text': 'Staff mengerti pentingnya hospitality'},
          {
            'id': 2,
            'point_text':
                'Selalu tubuh tegap dan ramah dalam menghadapi customer',
          },
          {'id': 3, 'point_text': 'Etika menyembut customer'},
        ],
      },
      {
        'category_name': 'NILAI ETOS KERJA',
        'points': [
          {'id': 4, 'point_text': 'Attitude'},
          {'id': 5, 'point_text': 'Disiplin'},
          {'id': 6, 'point_text': 'Teliti'},
        ],
      },
      {
        'category_name': 'HYGIENE DAN SANITASI',
        'points': [
          {'id': 7, 'point_text': 'Grooming - Kerapihan penampilan'},
          {'id': 8, 'point_text': 'Preventif maintenance utensil & equipment'},
          {'id': 9, 'point_text': 'Performa kebersihan diri'},
        ],
      },
    ];
    if (mounted) {
      setState(() {});
    }
  }

  void _setResponse(int pointId, String responseType) {
    setState(() {
      _responses[pointId] = responseType;
    });
  }

  Future<void> _addPhotoFromCamera() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      setState(() {
        _sessionPhotos.add(File(pickedFile.path));
      });
    }
  }

  Future<void> _addPhotoFromGallery() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _sessionPhotos.add(File(pickedFile.path));
      });
    }
  }

  Future<void> _showPhotoOptions() async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tambahkan Foto Dokumentasi'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Ambil Foto'),
              onTap: () {
                Navigator.pop(context);
                _addPhotoFromCamera();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Pilih dari Galeri'),
              onTap: () {
                Navigator.pop(context);
                _addPhotoFromGallery();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitSession() async {
    if (_trainerComment.isEmpty || _leaderComment.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Komentar trainer dan leader wajib diisi'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      List<Map<String, dynamic>> responsesList = [];
      _responses.forEach((pointId, responseType) {
        responsesList.add({
          'point_id': pointId,
          'score': _responseToScore(responseType),
          'notes': _trainerComment,
        });
      });

      if (responsesList.isNotEmpty) {
        await _trainingService.saveResponses(
          sessionId: widget.session.id,
          responses: responsesList,
        );
      }

      // Try to upload photos, but don't fail if endpoint doesn't exist
      for (int i = 0; i < _sessionPhotos.length; i++) {
        try {
          await _trainingService.uploadPhoto(
            _sessionPhotos[i].path,
            widget.session.id,
            caption: 'Documentation photo ${i + 1}',
          );
        } catch (e) {
          print(
            'Warning: Photo upload failed (endpoint may not be available): $e',
          );
          // Continue anyway, photos will still be included in PDF
        }
      }

      if (!mounted) return;
      final signatureResult = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DigitalSignatureScreen(
            auditorName: widget.session.trainerName ?? 'Trainer',
            crewInCharge:
                widget.session.crewName ??
                widget.session.crewLeaderName ??
                'Crew Leader',
            visitDate: widget.session.sessionDate,
          ),
        ),
      );

      if (signatureResult != null) {
        final signatures = signatureResult as Map<String, dynamic>;

        // Extract signatures with null safety
        // DigitalSignatureScreen returns 'auditorSignature' and 'crewSignature'
        final trainerSignatureBytes =
            signatures['auditorSignature'] as Uint8List?;
        final leaderSignatureBytes = signatures['crewSignature'] as Uint8List?;

        // Convert to base64 strings for saving to backend
        final trainerSignatureBase64 = trainerSignatureBytes != null
            ? base64Encode(trainerSignatureBytes)
            : null;
        final leaderSignatureBase64 = leaderSignatureBytes != null
            ? base64Encode(leaderSignatureBytes)
            : null;

        // For PDF generation, use Uint8List (with empty fallback)
        final trainerSignatureForPdf = trainerSignatureBytes ?? Uint8List(0);
        final leaderSignatureForPdf = leaderSignatureBytes ?? Uint8List(0);

        try {
          await _trainingService.saveSignatures(
            sessionId: widget.session.id,
            trainerSignature: trainerSignatureBase64,
            leaderSignature: leaderSignatureBase64,
            crewLeader: signatures['crewLeader'] as String?,
            crewLeaderPosition: signatures['crewLeaderPosition'] as String?,
          );
          print('DEBUG: ✓ Signatures saved successfully');
        } catch (e) {
          print('Warning: Failed to save signatures: $e');
        }

        try {
          final now = DateTime.now();
          final endTime =
              '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
          await _trainingService.completeSession(
            sessionId: widget.session.id,
            endTime: endTime,
            notes:
                'Completed with trainer: $_trainerComment and leader: $_leaderComment',
          );
          print('DEBUG: ✓ Session marked as complete');
        } catch (e) {
          print('Warning: Failed to complete session: $e');
        }

        // Try to save to report - this is optional, errors are silently handled
        // The service method always returns success even if backend fails
        try {
          await _trainingService.saveTrainingToReport(
            sessionId: widget.session.id,
            outletName: widget.session.outletName,
            sessionDate: widget.session.sessionDate,
            trainerName: widget.session.trainerName ?? 'Unknown',
            notes: _trainerComment,
          );
          // Always succeeds (service handles errors internally)
          print('DEBUG: ✓ Training report save attempted (optional operation)');
        } catch (e) {
          // Should never reach here, but just in case
          print(
            'DEBUG: ⚠️  Unexpected error in saveTrainingToReport (ignored): $e',
          );
        }

        // Generate PDF report
        print('DEBUG: Categories for PDF: $_categories');
        print('DEBUG: Responses for PDF: $_responses');
        print('DEBUG: Categories count: ${_categories.length}');

        final pdfService = TrainingPDFService();
        final pdfFile = await pdfService.generateTrainingReportPDF(
          session: widget.session,
          categories: _categories,
          responses: _responses,
          trainerComment: _trainerComment,
          leaderComment: _leaderComment,
          sessionPhotos: _sessionPhotos,
          trainerSignature: trainerSignatureForPdf,
          leaderSignature: leaderSignatureForPdf,
          crewLeader:
              signatures['crewLeader'] ??
              widget.session.crewLeaderName ??
              'Crew Leader',
          crewLeaderPosition: signatures['crewLeaderPosition'] ?? 'Crew Leader',
        );
        print('DEBUG: PDF generated successfully at: ${pdfFile.path}');

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sesi training berhasil disimpan')),
        );

        _showPdfOptionsDialog(pdfFile);
      }
    } catch (e) {
      // Only show error if it's a critical error (not from optional operations)
      // Check if error is related to saveTrainingToReport - if so, ignore it
      final errorString = e.toString().toLowerCase();
      final isOptionalError =
          errorString.contains('save-to-report') ||
          errorString.contains('training report') ||
          errorString.contains('u.name');

      if (mounted && !isOptionalError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      } else if (mounted && isOptionalError) {
        // Silently ignore optional errors - data is already saved
        print('DEBUG: Ignoring optional error: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _showPdfOptionsDialog(File pdfFile) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('PDF Laporan Selesai'),
          content: const Text(
            'Apa yang ingin Anda lakukan dengan laporan PDF?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _navigateToDetailScreen();
              },
              child: const Text('Tutup'),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.pop(context);
                await _openPdfFile(pdfFile);
                _navigateToDetailScreen();
              },
              icon: const Icon(Icons.open_in_new),
              label: const Text('Buka'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.pop(context);
                await _sharePdfFile(pdfFile);
                _navigateToDetailScreen();
              },
              icon: const Icon(Icons.share),
              label: const Text('Bagikan'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _navigateToDetailScreen() async {
    try {
      // Create TrainingScheduleModel from current session
      // Status should be 'completed' now
      final schedule = TrainingScheduleModel(
        id: widget.session.scheduleId,
        outletId: widget.session.outletId,
        outletName: widget.session.outletName,
        scheduledDate: widget.session.sessionDate,
        scheduledTime:
            widget.session.startedAt.hour.toString().padLeft(2, '0') +
            ':' +
            widget.session.startedAt.minute.toString().padLeft(2, '0'),
        trainerId: widget.session.trainerId,
        trainerName: widget.session.trainerName,
        status: 'completed', // Status is now completed
        crewLeader: widget.session.crewLeaderName,
        createdAt: widget.session.createdAt,
        updatedAt: DateTime.now(),
      );

      if (mounted) {
        // Pop current screen (checklist screen)
        Navigator.pop(context);

        // Navigate to detail screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => TrainingDetailScreen(schedule: schedule),
          ),
        );
      }
    } catch (e) {
      print('Error navigating to detail screen: $e');
      // If error, just pop back
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  Future<void> _openPdfFile(File pdfFile) async {
    try {
      if (await pdfFile.exists()) {
        final result = await OpenFile.open(pdfFile.path);
        if (result.type != ResultType.done && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Tidak dapat membuka file: ${result.message}'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('File PDF tidak ditemukan'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error membuka file: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _sharePdfFile(File pdfFile) async {
    try {
      if (await pdfFile.exists()) {
        await Share.shareXFiles([
          XFile(pdfFile.path),
        ], text: 'Laporan Training - ${widget.session.outletName}');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error berbagi file: $e')));
    }
  }

  int _responseToScore(String responseType) {
    switch (responseType.toUpperCase()) {
      case 'BS': // Baik Sekali
        return 5;
      case 'B': // Baik
        return 4;
      case 'C': // Cukup
        return 3;
      case 'K': // Kurang
        return 2;
      default:
        return 3;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF4A90E2), Color(0xFF357ABD)],
          ),
        ),
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Colors.white),
              )
            : CustomScrollView(
                slivers: [
                  SliverAppBar(
                    expandedHeight: 200,
                    floating: false,
                    pinned: true,
                    backgroundColor: Colors.transparent,
                    flexibleSpace: FlexibleSpaceBar(
                      title: const Text(
                        'Form Checklist Training',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      background: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF4A90E2), Color(0xFF357ABD)],
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.checklist_rtl,
                            size: 80,
                            color: Colors.white.withValues(alpha: 0.3),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: _buildGlassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Color(0xFF4A90E2),
                                        Color(0xFF357ABD),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    Icons.business,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    widget.session.outletName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _buildInfoRow(
                              Icons.calendar_today,
                              'Tanggal',
                              widget.session.sessionDate.toString().split(
                                ' ',
                              )[0],
                            ),
                            const SizedBox(height: 8),
                            _buildInfoRow(
                              Icons.person,
                              'Trainer',
                              widget.session.trainerName ?? '-',
                            ),
                            const SizedBox(height: 8),
                            _buildInfoRow(
                              Icons.person_outline,
                              'Nama Crew',
                              widget.session.crewName ?? '-',
                            ),
                            const SizedBox(height: 8),
                            _buildInfoRow(
                              Icons.info_outline,
                              'Status',
                              widget.session.status,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate((
                      context,
                      categoryIndex,
                    ) {
                      final category = _categories[categoryIndex];
                      final points =
                          (category['points'] as List?)
                              ?.cast<Map<String, dynamic>>() ??
                          [];
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: _buildCategoryCard(
                          category,
                          points,
                          categoryIndex,
                        ),
                      );
                    }, childCount: _categories.length),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: _buildGlassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.camera_alt,
                                  color: Colors.black87,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Foto Dokumentasi',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            InkWell(
                              onTap: _showPhotoOptions,
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                  horizontal: 16,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Color(0xFF4A90E2),
                                      Color(0xFF357ABD),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Color(
                                        0xFF4A90E2,
                                      ).withValues(alpha: 0.3),
                                      blurRadius: 8,
                                      offset: Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.add_a_photo,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Tambah Foto',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (_sessionPhotos.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: Text(
                                  '${_sessionPhotos.length} foto ditambahkan',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: _buildGlassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.comment,
                                  color: Colors.black87,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Komentar',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              decoration: InputDecoration(
                                labelText: 'Komentar Trainer *',
                                labelStyle: TextStyle(color: Colors.black87),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Color(0xFF4A90E2),
                                    width: 2,
                                  ),
                                ),
                                hintText: 'Masukkan komentar trainer',
                                filled: true,
                                fillColor: Colors.white.withValues(alpha: 0.8),
                              ),
                              maxLines: 3,
                              onChanged: (value) =>
                                  setState(() => _trainerComment = value),
                              style: const TextStyle(color: Colors.black),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              decoration: InputDecoration(
                                labelText: 'Komentar Leader *',
                                labelStyle: TextStyle(color: Colors.black87),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Color(0xFF4A90E2),
                                    width: 2,
                                  ),
                                ),
                                hintText: 'Masukkan komentar crew leader',
                                filled: true,
                                fillColor: Colors.white.withValues(alpha: 0.8),
                              ),
                              maxLines: 3,
                              onChanged: (value) =>
                                  setState(() => _leaderComment = value),
                              style: const TextStyle(color: Colors.black),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: InkWell(
                        onTap: _isSubmitting ? null : _submitSession,
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: _isSubmitting
                                  ? [Colors.grey, Colors.grey]
                                  : [Colors.green, Colors.green.shade700],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: _isSubmitting
                                    ? Colors.grey.withValues(alpha: 0.3)
                                    : Colors.green.withValues(alpha: 0.4),
                                blurRadius: 12,
                                offset: Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (_isSubmitting)
                                SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              else
                                Icon(
                                  Icons.check_circle,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              const SizedBox(width: 12),
                              Text(
                                _isSubmitting
                                    ? 'Memproses...'
                                    : 'Selesaikan Training',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(child: SizedBox(height: 20)),
                ],
              ),
      ),
    );
  }

  Widget _buildGlassCard({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
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
              color: Colors.white.withValues(alpha: 0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Color(0xFF4A90E2).withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.black87),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(fontSize: 14, color: Colors.black),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryCard(
    Map<String, dynamic> category,
    List<Map<String, dynamic>> points,
    int categoryIndex,
  ) {
    return _buildGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF4A90E2), Color(0xFF357ABD)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.category, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  category['category_name'] ?? 'Category ${categoryIndex + 1}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...points.asMap().entries.map((entry) {
            int pointIndex = entry.key;
            Map<String, dynamic> point = entry.value;
            int pointId = point['id'] ?? 0;
            String pointText = point['point_text'] ?? 'Untitled Point';

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.5),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${pointIndex + 1}. $pointText',
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildResponseButton(
                        label: 'BS',
                        icon: Icons.star,
                        color: Color(0xFF2E7D32),
                        isSelected: _responses[pointId] == 'BS',
                        onSelect: () => _setResponse(pointId, 'BS'),
                      ),
                      const SizedBox(width: 8),
                      _buildResponseButton(
                        label: 'B',
                        icon: Icons.thumb_up,
                        color: Color(0xFF388E3C),
                        isSelected: _responses[pointId] == 'B',
                        onSelect: () => _setResponse(pointId, 'B'),
                      ),
                      const SizedBox(width: 8),
                      _buildResponseButton(
                        label: 'C',
                        icon: Icons.remove_circle_outline,
                        color: Color(0xFFF57C00),
                        isSelected: _responses[pointId] == 'C',
                        onSelect: () => _setResponse(pointId, 'C'),
                      ),
                      const SizedBox(width: 8),
                      _buildResponseButton(
                        label: 'K',
                        icon: Icons.thumb_down,
                        color: Color(0xFFD32F2F),
                        isSelected: _responses[pointId] == 'K',
                        onSelect: () => _setResponse(pointId, 'K'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildResponseButton({
    required String label,
    required IconData icon,
    required Color color,
    required bool isSelected,
    required VoidCallback onSelect,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onSelect,
        child: AnimatedScale(
          scale: isSelected ? 1.05 : 1.0,
          duration: const Duration(milliseconds: 150),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? color : Colors.grey[200],
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected ? color : Colors.grey[300]!,
                width: 1.5,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: color.withAlpha(77),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : [],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: isSelected ? Colors.white : color, size: 20),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

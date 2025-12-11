import 'dart:io';
import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import '../../models/training/training_models.dart';

/// Training PDF Report Service - Multi Page Version
/// Generates comprehensive training reports with all checklist items and photos
/// Optimized for complete documentation (max 2 pages)
class TrainingPDFService {
  static final TrainingPDFService _instance = TrainingPDFService._internal();
  factory TrainingPDFService() => _instance;
  TrainingPDFService._internal();

  /// Generate comprehensive Training Report PDF
  Future<File> generateTrainingReportPDF({
    required TrainingSessionModel session,
    required List<Map<String, dynamic>> categories,
    required Map<int, String> responses,
    required String trainerComment,
    required String leaderComment,
    required List<File> sessionPhotos,
    required Uint8List trainerSignature,
    required Uint8List leaderSignature,
    required String crewLeader,
    required String crewLeaderPosition,
  }) async {
    // Log generation start
    _logGenerationStart(session, categories, responses);

    // DEBUG: Log crew info
    print('DEBUG PDF: crewLeader parameter = "$crewLeader"');
    print('DEBUG PDF: session.crewName = "${session.crewName}"');

    // DEBUG: Check if categories is empty
    print('DEBUG PDF SERVICE: Received ${categories.length} categories');
    if (categories.isEmpty) {
      print(
        '⚠️  WARNING: Categories list is EMPTY! Using sample data instead.',
      );
      // Use sample data as fallback
      final sampleCategories = _getSampleCategories();
      print('✓ Loaded ${sampleCategories.length} sample categories');
      return generateTrainingReportPDF(
        session: session,
        categories: sampleCategories,
        responses: responses,
        trainerComment: trainerComment,
        leaderComment: leaderComment,
        sessionPhotos: sessionPhotos,
        trainerSignature: trainerSignature,
        leaderSignature: leaderSignature,
        crewLeader: crewLeader,
        crewLeaderPosition: crewLeaderPosition,
      );
    }

    final pdf = pw.Document();

    // Convert signatures to PDF images
    final trainerSignatureImage = pw.MemoryImage(trainerSignature);
    final leaderSignatureImage = pw.MemoryImage(leaderSignature);

    // Convert session photos to PDF images
    final List<pw.MemoryImage> photoImages = [];
    for (var photoFile in sessionPhotos) {
      try {
        final bytes = await photoFile.readAsBytes();
        photoImages.add(pw.MemoryImage(bytes));
      } catch (e) {
        print('⚠️  Error loading photo: $e');
      }
    }

    // ===== MULTI PAGE: Complete Training Report with Photos =====
    // Page 1: Header, Info, Summary, Checklist (compact)
    // Page 2: Comments, Signatures, and Documentation Photos
    
    // PAGE 1: Main Report with Checklist
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(25),
        build: (pw.Context context) {
          return [
            // Compact Header
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(width: 1.5, color: PdfColors.blue900),
                color: PdfColors.blue50,
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'LAPORAN TRAINING',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue900,
                    ),
                  ),
                  pw.Text(
                    DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now()),
                    style: pw.TextStyle(
                      fontSize: 9,
                      color: PdfColors.grey600,
                    ),
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 12),

            // Compact Info & Summary in one row
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Left column: Training Info
                pw.Expanded(
                  flex: 3,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'INFO TRAINING',
                        style: pw.TextStyle(
                          fontSize: 11,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue900,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      _buildCompactInfoTable([
                        ['Outlet', session.outletName],
                        [
                          'Tanggal',
                          _formatDate(session.sessionDate.toString()),
                        ],
                        ['Trainer', session.trainerName ?? '-'],
                        ['Nama Crew', session.crewName ?? '-'],
                      ]),
                    ],
                  ),
                ),
                pw.SizedBox(width: 10),
                // Right column: Results Summary
                pw.Expanded(
                  flex: 2,
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(8),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.grey100,
                      border: pw.Border.all(
                        width: 1,
                        color: PdfColors.grey300,
                      ),
                    ),
                    child: pw.Column(
                      children: [
                        pw.Text(
                          'HASIL',
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blue900,
                          ),
                        ),
                        pw.SizedBox(height: 6),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                          children: [
                            _buildCompactStatBox(
                              'BS',
                              _countBSResponses(responses),
                            ),
                            _buildCompactStatBox(
                              'B',
                              _countBResponses(responses),
                            ),
                          ],
                        ),
                        pw.SizedBox(height: 4),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                          children: [
                            _buildCompactStatBox(
                              'C',
                              _countCResponses(responses),
                            ),
                            _buildCompactStatBox(
                              'K',
                              _countKResponses(responses),
                            ),
                          ],
                        ),
                        pw.SizedBox(height: 6),
                        pw.Text(
                          'Rata-rata: ${_calculateAverage(responses).toStringAsFixed(1)}',
                          style: pw.TextStyle(
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blue900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            pw.SizedBox(height: 12),

            // Checklist Results (Detailed with Points)
            pw.Text(
              'HASIL CHECKLIST DETAIL',
              style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue900,
              ),
            ),
            pw.SizedBox(height: 4),

            // Display each category with its points
            ...categories.map((category) {
              final points =
                  (category['points'] as List?)
                      ?.cast<Map<String, dynamic>>() ??
                  [];
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Category header
                  pw.Container(
                    width: double.infinity,
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 4,
                    ),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.blue100,
                      border: pw.Border.all(
                        width: 1,
                        color: PdfColors.blue300,
                      ),
                    ),
                    child: pw.Text(
                      category['category_name'] ?? 'Unknown Category',
                      style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue900,
                      ),
                    ),
                  ),
                  // Points list
                  ...points.asMap().entries.map((entry) {
                    final index = entry.key;
                    final point = entry.value;
                    final pointId = point['id'];
                    final pointText =
                        point['point_text'] ?? point['point_name'] ?? 'Item';
                    final rating = responses[pointId]?.toUpperCase() ?? '-';

                    // Determine color based on rating
                    PdfColor ratingColor;
                    switch (rating) {
                      case 'BS':
                        ratingColor = PdfColors.green600;
                        break;
                      case 'B':
                        ratingColor = PdfColors.green;
                        break;
                      case 'C':
                        ratingColor = PdfColors.orange;
                        break;
                      case 'K':
                        ratingColor = PdfColors.red;
                        break;
                      default:
                        ratingColor = PdfColors.grey;
                    }

                    return pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      decoration: pw.BoxDecoration(
                        border: pw.Border(
                          left: pw.BorderSide(
                            width: 1,
                            color: PdfColors.grey300,
                          ),
                          right: pw.BorderSide(
                            width: 1,
                            color: PdfColors.grey300,
                          ),
                          bottom: pw.BorderSide(
                            width: 0.5,
                            color: PdfColors.grey200,
                          ),
                        ),
                        color: index.isEven
                            ? PdfColors.white
                            : PdfColors.grey50,
                      ),
                      child: pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Container(
                            width: 20,
                            child: pw.Text(
                              '${index + 1}.',
                              style: pw.TextStyle(
                                fontSize: 7,
                                color: PdfColors.grey700,
                              ),
                            ),
                          ),
                          pw.Expanded(
                            child: pw.Text(
                              pointText,
                              style: const pw.TextStyle(fontSize: 7),
                            ),
                          ),
                          pw.Container(
                            padding: const pw.EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: pw.BoxDecoration(
                              color: ratingColor.shade(0.9),
                              borderRadius: pw.BorderRadius.circular(3),
                              border: pw.Border.all(
                                color: ratingColor,
                                width: 0.5,
                              ),
                            ),
                            child: pw.Text(
                              rating,
                              style: pw.TextStyle(
                                fontSize: 7,
                                fontWeight: pw.FontWeight.bold,
                                color: ratingColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  pw.SizedBox(height: 6),
                ],
              );
            }).toList(),
          ];
        },
      ),
    );

    // PAGE 2: Comments, Signatures, and Documentation Photos
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(25),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Compact Header
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(width: 1.5, color: PdfColors.blue900),
                  color: PdfColors.blue50,
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'LAPORAN TRAINING',
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue900,
                      ),
                    ),
                    pw.Text(
                      DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now()),
                      style: pw.TextStyle(
                        fontSize: 9,
                        color: PdfColors.grey600,
                      ),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 12),

              // Compact Info & Summary in one row
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Left column: Training Info
                  pw.Expanded(
                    flex: 3,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'INFO TRAINING',
                          style: pw.TextStyle(
                            fontSize: 11,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blue900,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        _buildCompactInfoTable([
                          ['Outlet', session.outletName],
                          [
                            'Tanggal',
                            _formatDate(session.sessionDate.toString()),
                          ],
                          ['Trainer', session.trainerName ?? '-'],
                          ['Nama Crew', session.crewName ?? '-'],
                        ]),
                      ],
                    ),
                  ),
                  pw.SizedBox(width: 10),
                  // Right column: Results Summary
                  pw.Expanded(
                    flex: 2,
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(8),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.grey100,
                        border: pw.Border.all(
                          width: 1,
                          color: PdfColors.grey300,
                        ),
                      ),
                      child: pw.Column(
                        children: [
                          pw.Text(
                            'HASIL',
                            style: pw.TextStyle(
                              fontSize: 10,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.blue900,
                            ),
                          ),
                          pw.SizedBox(height: 6),
                          pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                            children: [
                              _buildCompactStatBox(
                                'BS',
                                _countBSResponses(responses),
                              ),
                              _buildCompactStatBox(
                                'B',
                                _countBResponses(responses),
                              ),
                            ],
                          ),
                          pw.SizedBox(height: 4),
                          pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                            children: [
                              _buildCompactStatBox(
                                'C',
                                _countCResponses(responses),
                              ),
                              _buildCompactStatBox(
                                'K',
                                _countKResponses(responses),
                              ),
                            ],
                          ),
                          pw.SizedBox(height: 6),
                          pw.Text(
                            'Rata-rata: ${_calculateAverage(responses).toStringAsFixed(1)}',
                            style: pw.TextStyle(
                              fontSize: 9,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.blue900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 12),

              // Checklist Results (Detailed with Points)
              pw.Text(
                'HASIL CHECKLIST DETAIL',
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue900,
                ),
              ),
              pw.SizedBox(height: 4),

              // Display each category with its points
              ...categories.map((category) {
                final points =
                    (category['points'] as List?)
                        ?.cast<Map<String, dynamic>>() ??
                    [];
                return pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Category header
                    pw.Container(
                      width: double.infinity,
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 4,
                      ),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.blue100,
                        border: pw.Border.all(
                          width: 1,
                          color: PdfColors.blue300,
                        ),
                      ),
                      child: pw.Text(
                        category['category_name'] ?? 'Unknown Category',
                        style: pw.TextStyle(
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue900,
                        ),
                      ),
                    ),
                    // Points list
                    ...points.asMap().entries.map((entry) {
                      final index = entry.key;
                      final point = entry.value;
                      final pointId = point['id'];
                      final pointText =
                          point['point_text'] ?? point['point_name'] ?? 'Item';
                      final rating = responses[pointId]?.toUpperCase() ?? '-';

                      // Determine color based on rating
                      PdfColor ratingColor;
                      switch (rating) {
                        case 'BS':
                          ratingColor = PdfColors.green600;
                          break;
                        case 'B':
                          ratingColor = PdfColors.green;
                          break;
                        case 'C':
                          ratingColor = PdfColors.orange;
                          break;
                        case 'K':
                          ratingColor = PdfColors.red;
                          break;
                        default:
                          ratingColor = PdfColors.grey;
                      }

                      return pw.Container(
                        padding: const pw.EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: pw.BoxDecoration(
                          border: pw.Border(
                            left: pw.BorderSide(
                              width: 1,
                              color: PdfColors.grey300,
                            ),
                            right: pw.BorderSide(
                              width: 1,
                              color: PdfColors.grey300,
                            ),
                            bottom: pw.BorderSide(
                              width: 0.5,
                              color: PdfColors.grey200,
                            ),
                          ),
                          color: index.isEven
                              ? PdfColors.white
                              : PdfColors.grey50,
                        ),
                        child: pw.Row(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Container(
                              width: 20,
                              child: pw.Text(
                                '${index + 1}.',
                                style: pw.TextStyle(
                                  fontSize: 7,
                                  color: PdfColors.grey700,
                                ),
                              ),
                            ),
                            pw.Expanded(
                              child: pw.Text(
                                pointText,
                                style: const pw.TextStyle(fontSize: 7),
                              ),
                            ),
                            pw.Container(
                              padding: const pw.EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: pw.BoxDecoration(
                                color: ratingColor.shade(0.9),
                                borderRadius: pw.BorderRadius.circular(3),
                                border: pw.Border.all(
                                  color: ratingColor,
                                  width: 0.5,
                                ),
                              ),
                              child: pw.Text(
                                rating,
                                style: pw.TextStyle(
                                  fontSize: 7,
                                  fontWeight: pw.FontWeight.bold,
                                  color: ratingColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    pw.SizedBox(height: 6),
                  ],
                );
              }).toList(),

            ],
          );
        },
      ),
    );

    // PAGE 2: Comments, Signatures, and Documentation Photos
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(25),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Page Header
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(width: 1.5, color: PdfColors.blue900),
                  color: PdfColors.blue50,
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'EVALUASI & DOKUMENTASI',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue900,
                      ),
                    ),
                    pw.Text(
                      'Halaman 2',
                      style: pw.TextStyle(
                        fontSize: 9,
                        color: PdfColors.grey600,
                      ),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 12),

              // Comments Section
              pw.Text(
                'Evaluasi/Saran',
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue900,
                ),
              ),
              pw.SizedBox(height: 6),

              // Trainer Comment
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  border: pw.Border.all(width: 1, color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Komentar Trainer:',
                      style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      trainerComment.isNotEmpty
                          ? trainerComment
                          : 'Tidak ada komentar',
                      style: const pw.TextStyle(fontSize: 8),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 6),

              // Crew Leader Comment
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  border: pw.Border.all(width: 1, color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Komentar Crew Leader:',
                      style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      leaderComment.isNotEmpty
                          ? leaderComment
                          : 'Tidak ada komentar',
                      style: const pw.TextStyle(fontSize: 8),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 12),

              // Signatures Section
              pw.Text(
                'TANDA TANGAN DIGITAL',
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue900,
                ),
              ),
              pw.SizedBox(height: 6),

              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  // Trainer Signature
                  pw.Column(
                    children: [
                      pw.Text(
                        'Trainer',
                        style: pw.TextStyle(
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Container(
                        width: 100,
                        height: 50,
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(color: PdfColors.grey400),
                          borderRadius: pw.BorderRadius.circular(4),
                        ),
                        child: pw.Image(
                          trainerSignatureImage,
                          fit: pw.BoxFit.contain,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        session.trainerName ?? '-',
                        style: pw.TextStyle(
                          fontSize: 8,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        DateFormat('dd/MM/yyyy').format(DateTime.now()),
                        style: pw.TextStyle(
                          fontSize: 7,
                          color: PdfColors.grey600,
                        ),
                      ),
                    ],
                  ),
                  // Crew Leader Signature
                  pw.Column(
                    children: [
                      pw.Text(
                        'Crew Leader',
                        style: pw.TextStyle(
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Container(
                        width: 100,
                        height: 50,
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(color: PdfColors.grey400),
                          borderRadius: pw.BorderRadius.circular(4),
                        ),
                        child: pw.Image(
                          leaderSignatureImage,
                          fit: pw.BoxFit.contain,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        _getCrewLeaderName(crewLeader, session),
                        style: pw.TextStyle(
                          fontSize: 8,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        DateFormat('dd/MM/yyyy').format(DateTime.now()),
                        style: pw.TextStyle(
                          fontSize: 7,
                          color: PdfColors.grey600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              pw.SizedBox(height: 12),

              // Documentation Photos Section
              if (photoImages.isNotEmpty) ...[
                pw.Text(
                  'DOKUMENTASI TRAINING',
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue900,
                  ),
                ),
                pw.SizedBox(height: 6),
                
                // Display photos in grid (2 columns)
                pw.Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: photoImages.take(4).map((photoImage) {
                    return pw.Container(
                      width: (PdfPageFormat.a4.width - 50 - 8) / 2,
                      height: 130,
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(
                          color: PdfColors.grey400,
                          width: 1,
                        ),
                        borderRadius: pw.BorderRadius.circular(4),
                      ),
                      child: pw.ClipRRect(
                        horizontalRadius: 4,
                        verticalRadius: 4,
                        child: pw.Image(
                          photoImage,
                          fit: pw.BoxFit.cover,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                pw.SizedBox(height: 6),
                pw.Text(
                  'Total ${photoImages.length} foto dokumentasi',
                  style: pw.TextStyle(
                    fontSize: 8,
                    fontStyle: pw.FontStyle.italic,
                    color: PdfColors.grey600,
                  ),
                ),
              ] else ...[
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey100,
                    border: pw.Border.all(color: PdfColors.grey300),
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Center(
                    child: pw.Text(
                      'Tidak ada foto dokumentasi',
                      style: pw.TextStyle(
                        fontSize: 9,
                        color: PdfColors.grey600,
                        fontStyle: pw.FontStyle.italic,
                      ),
                    ),
                  ),
                ),
              ],

              pw.Spacer(),

              // Footer
              pw.Divider(thickness: 0.5, color: PdfColors.grey400),
              pw.SizedBox(height: 4),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Laporan Training - TnD System',
                    style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                  ),
                  pw.Text(
                    DateFormat(
                      'dd MMMM yyyy HH:mm',
                      'id_ID',
                    ).format(DateTime.now()),
                    style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    // Save PDF to device storage
    final output = await getApplicationDocumentsDirectory();
    final file = File(
      '${output.path}/training_report_${session.id}_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
    await file.writeAsBytes(await pdf.save());

    return file;
  }

  // ===== Helper Methods =====

  /// Get crew leader name with robust fallback logic
  String _getCrewLeaderName(String crewLeader, TrainingSessionModel session) {
    // Try parameter first (from signature input)
    if (crewLeader.trim().isNotEmpty && crewLeader != 'Crew Leader') {
      print('DEBUG PDF: Using crewLeader from parameter: "$crewLeader"');
      return crewLeader.trim();
    }

    // Try session crew leader name
    if (session.crewLeaderName != null &&
        session.crewLeaderName!.trim().isNotEmpty) {
      print(
        'DEBUG PDF: Using session.crewLeaderName: "${session.crewLeaderName}"',
      );
      return session.crewLeaderName!.trim();
    }

    // Last resort: return placeholder
    print('DEBUG PDF: No crew leader name found, using placeholder');
    return 'Crew Leader';
  }

  // ===== Helper Widgets =====

  // Compact info table for single page layout
  pw.Widget _buildCompactInfoTable(List<List<String>> rows) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: rows.map((row) {
        return pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 2),
          child: pw.Row(
            children: [
              pw.Container(
                width: 80,
                child: pw.Text(
                  '${row[0]}:',
                  style: pw.TextStyle(
                    fontSize: 8,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.Expanded(
                child: pw.Text(row[1], style: const pw.TextStyle(fontSize: 8)),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // Compact stat box for single page layout
  pw.Widget _buildCompactStatBox(String label, int count) {
    late PdfColor color;
    if (label == 'BS') {
      color = PdfColors.green900;
    } else if (label == 'B') {
      color = PdfColors.green;
    } else if (label == 'C') {
      color = PdfColors.orange;
    } else if (label == 'K') {
      color = PdfColors.red;
    } else {
      color = PdfColors.grey;
    }
    return pw.Column(
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: 7,
            fontWeight: pw.FontWeight.bold,
            color: color,
          ),
        ),
        pw.Text(
          count.toString(),
          style: pw.TextStyle(
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  pw.Widget _buildSectionHeader(String title) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue900,
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 14,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.white,
        ),
      ),
    );
  }

  pw.Widget _buildInfoTable(List<List<String>> rows) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(2),
        1: const pw.FlexColumnWidth(3),
      },
      children: rows.map((row) {
        return pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.white),
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(
                row[0],
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey800,
                ),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(row[1], style: const pw.TextStyle(fontSize: 11)),
            ),
          ],
        );
      }).toList(),
    );
  }

  pw.Widget _buildStatBox(String label, int count) {
    late PdfColor color;
    late PdfColor bgColor;
    if (label == 'OK') {
      color = PdfColors.green;
      bgColor = PdfColors.green50;
    } else if (label == 'NOK') {
      color = PdfColors.red;
      bgColor = PdfColors.red50;
    } else {
      color = PdfColors.orange;
      bgColor = PdfColors.orange100;
    }
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: pw.BoxDecoration(
        color: bgColor,
        border: pw.Border.all(color: color, width: 1),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 8,
              fontWeight: pw.FontWeight.bold,
              color: color,
            ),
          ),
          pw.Text(
            count.toString(),
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildCategoryCard(
    String categoryName,
    List<Map<String, dynamic>> points,
    Map<int, String> responses,
  ) {
    final okItems = points.where((p) => responses[p['id']] == 'check').toList();
    final nokCount = points.where((p) => responses[p['id']] == 'cross').length;
    final naCount = points.where((p) => responses[p['id']] == 'na').length;

    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        color: PdfColors.white,
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                categoryName,
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue900,
                ),
              ),
              pw.Row(
                children: [
                  _buildStatBadgeSmall('OK', okItems.length),
                  pw.SizedBox(width: 4),
                  _buildStatBadgeSmall('NOK', nokCount),
                  pw.SizedBox(width: 4),
                  _buildStatBadgeSmall('N/A', naCount),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 6),
          ...okItems.map((item) {
            final pointText =
                item['point_text'] ?? item['point_name'] ?? 'Item';
            return pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 3),
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 6,
                vertical: 3,
              ),
              decoration: pw.BoxDecoration(
                color: PdfColors.green50,
                border: pw.Border.all(color: PdfColors.green),
              ),
              child: pw.Row(
                children: [
                  pw.Text(
                    '✓ ',
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.green,
                    ),
                  ),
                  pw.Expanded(
                    child: pw.Text(pointText, style: pw.TextStyle(fontSize: 8)),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  pw.Widget _buildStatBadgeSmall(String label, int count) {
    late PdfColor color;
    late PdfColor bgColor;
    if (label == 'OK') {
      color = PdfColors.green;
      bgColor = PdfColors.green50;
    } else if (label == 'NOK') {
      color = PdfColors.red;
      bgColor = PdfColors.red50;
    } else {
      color = PdfColors.orange;
      bgColor = PdfColors.orange100;
    }
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: pw.BoxDecoration(
        color: bgColor,
        border: pw.Border.all(color: color, width: 0.5),
        borderRadius: pw.BorderRadius.circular(2),
      ),
      child: pw.Text(
        '$label:$count',
        style: pw.TextStyle(
          fontSize: 7,
          fontWeight: pw.FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Map<String, List<Map<String, dynamic>>> _groupNOKItems(
    List<Map<String, dynamic>> categories,
    Map<int, String> responses,
  ) {
    final nok = <String, List<Map<String, dynamic>>>{};
    for (var cat in categories) {
      final points =
          (cat['points'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      final nokItems = points
          .where((p) => responses[p['id']] == 'cross')
          .toList();
      if (nokItems.isNotEmpty) {
        nok[cat['category_name'] ?? 'Unknown'] = nokItems;
      }
    }
    return nok;
  }

  String _formatDate(String date) {
    try {
      return DateFormat('dd/MM/yyyy').format(DateTime.parse(date));
    } catch (e) {
      return date;
    }
  }

  String _formatTime(String dateTime) {
    try {
      return DateFormat('HH:mm').format(DateTime.parse(dateTime));
    } catch (e) {
      return '-';
    }
  }

  int _countBSResponses(Map<int, String> responses) =>
      responses.values.where((r) => r.toUpperCase() == 'BS').length;
  int _countBResponses(Map<int, String> responses) =>
      responses.values.where((r) => r.toUpperCase() == 'B').length;
  int _countCResponses(Map<int, String> responses) =>
      responses.values.where((r) => r.toUpperCase() == 'C').length;
  int _countKResponses(Map<int, String> responses) =>
      responses.values.where((r) => r.toUpperCase() == 'K').length;

  double _calculateAverage(Map<int, String> responses) {
    if (responses.isEmpty) return 0;
    int totalScore = 0;
    for (var response in responses.values) {
      switch (response.toUpperCase()) {
        case 'BS':
          totalScore += 5;
          break;
        case 'B':
          totalScore += 4;
          break;
        case 'C':
          totalScore += 3;
          break;
        case 'K':
          totalScore += 2;
          break;
      }
    }
    return totalScore / responses.length;
  }

  void _logGenerationStart(
    TrainingSessionModel session,
    List<Map<String, dynamic>> categories,
    Map<int, String> responses,
  ) {
    print('');
    print('╔════════════════════════════════════════════════════════════╗');
    print('║           PDF GENERATION - TRAINING REPORT                  ║');
    print('╚════════════════════════════════════════════════════════════╝');
    print('Session: ${session.id} - ${session.outletName}');
    print('---');
    print('Categories: ${categories.length}');
    for (int i = 0; i < categories.length && i < 3; i++) {
      final points = (categories[i]['points'] as List?)?.length ?? 0;
      print('  ${i + 1}. ${categories[i]['category_name']} ($points points)');
    }
    if (categories.length > 3) print('  ... and ${categories.length - 3} more');
    print('---');
    print('Responses: ${responses.length}');
    print('BS (Baik Sekali): ${_countBSResponses(responses)}');
    print('B (Baik): ${_countBResponses(responses)}');
    print('C (Cukup): ${_countCResponses(responses)}');
    print('K (Kurang): ${_countKResponses(responses)}');
    print('Rata-rata: ${_calculateAverage(responses).toStringAsFixed(2)}');
    print('---');
  }

  /// Get sample categories for fallback/testing
  List<Map<String, dynamic>> _getSampleCategories() {
    return [
      {
        'category_name': 'NILAI HOSPITALITY',
        'category_id': 1,
        'points': [
          {
            'id': 1,
            'point_text': 'Staff memiliki penampilan rapi dan profesional',
            'rating': 'BS',
            'notes': '',
          },
          {
            'id': 2,
            'point_text': 'Staff memberikan salam dengan ramah kepada tamu',
            'rating': 'B',
            'notes': '',
          },
          {
            'id': 3,
            'point_text': 'Staff siap membantu kebutuhan tamu dengan cepat',
            'rating': 'B',
            'notes': '',
          },
        ],
      },
      {
        'category_name': 'NILAI ETOS KERJA',
        'category_id': 2,
        'points': [
          {
            'id': 4,
            'point_text':
                'Staff menyelesaikan tugas sesuai target yang ditetapkan',
            'rating': 'B',
            'notes': '',
          },
          {
            'id': 5,
            'point_text': 'Staff proaktif dalam menemukan solusi masalah',
            'rating': 'C',
            'notes': '',
          },
          {
            'id': 6,
            'point_text': 'Staff menunjukkan komitmen terhadap pekerjaannya',
            'rating': 'B',
            'notes': '',
          },
        ],
      },
      {
        'category_name': 'HYGIENE DAN SANITASI',
        'category_id': 3,
        'points': [
          {
            'id': 7,
            'point_text': 'Area kerja bersih dan terawat dengan baik',
            'rating': 'BS',
            'notes': '',
          },
          {
            'id': 8,
            'point_text':
                'Peralatan kerja digunakan sesuai prosedur keselamatan',
            'rating': 'B',
            'notes': '',
          },
          {
            'id': 9,
            'point_text': 'Limbah dibuang pada tempat yang telah ditentukan',
            'rating': 'B',
            'notes': '',
          },
        ],
      },
    ];
  }
}

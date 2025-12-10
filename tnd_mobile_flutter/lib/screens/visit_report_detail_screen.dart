import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:share_plus/share_plus.dart';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';
import '../models/visit_model.dart';
import '../services/visit_service.dart';
import 'digital_signature_screen.dart';

/// Visit Report Detail Screen
/// Shows complete visit details with export PDF button
class VisitReportDetailScreen extends StatefulWidget {
  final VisitModel visit;
  final UserModel currentUser;

  const VisitReportDetailScreen({
    Key? key,
    required this.visit,
    required this.currentUser,
  }) : super(key: key);

  @override
  State<VisitReportDetailScreen> createState() => _VisitReportDetailScreenState();
}

class _VisitReportDetailScreenState extends State<VisitReportDetailScreen> {
  final VisitService _visitService = VisitService();
  
  Map<String, List<Map<String, dynamic>>> _groupedResponses = {};
  List<Map<String, dynamic>> _recommendations = [];
  bool _isLoading = true;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _loadVisitDetails();
  }

  Future<void> _loadVisitDetails() async {
    setState(() => _isLoading = true);
    try {
      print('📋 Loading visit details for visit ID: ${widget.visit.id}');
      
      // Load responses
      final response = await _visitService.getVisitResponses(widget.visit.id);
      
      // Load recommendations (NOK findings)
      final recResponse = await _visitService.getRecommendations(widget.visit.id);
      
      if (response.success && response.data != null) {
        print('✅ Got ${response.data!.length} responses');
        
        // Debug first item
        if (response.data!.isNotEmpty) {
          final firstItem = response.data!.first;
          print('🔍 Sample response data:');
          print('   - Keys: ${firstItem.keys.toList()}');
          print('   - response: ${firstItem['response']}');
          print('   - response_value: ${firstItem['response_value']}');
          print('   - item_text: ${firstItem['item_text']}');
          print('   - category_name: ${firstItem['category_name']}');
        }
        
        // Group responses by category
        final Map<String, List<Map<String, dynamic>>> grouped = {};
        
        for (var item in response.data!) {
          final categoryName = item['category_name'] ?? 'Uncategorized';
          if (!grouped.containsKey(categoryName)) {
            grouped[categoryName] = [];
          }
          grouped[categoryName]!.add(item);
        }
        
        print('📦 Grouped into ${grouped.length} categories');
        
        // Process recommendations
        List<Map<String, dynamic>> recommendations = [];
        if (recResponse.success && recResponse.data != null) {
          recommendations = recResponse.data!;
          print('📝 Got ${recommendations.length} recommendations (NOK findings)');
        }
        
        setState(() {
          _groupedResponses = grouped;
          _recommendations = recommendations;
          _isLoading = false;
        });
      } else {
        print('❌ Failed to load responses');
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('❌ Error loading visit details: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _exportPDF() async {
    // Navigate to digital signature screen first
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => DigitalSignatureScreen(
          auditorName: widget.visit.userName ?? '-',
          crewInCharge: widget.visit.crewInCharge ?? '-',
          visitDate: widget.visit.visitDate,
        ),
      ),
    );

    // If user canceled, return
    if (result == null) return;

    // Get signatures from result
    final Uint8List? auditorSignature = result['auditorSignature'] as Uint8List?;
    final Uint8List? crewSignature = result['crewSignature'] as Uint8List?;

    // If signatures are missing, return
    if (auditorSignature == null || crewSignature == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tanda tangan tidak lengkap'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Now generate PDF with signatures
    setState(() => _isExporting = true);
    
    try {
      // Pre-load all images for NOT OK items
      final Map<String, pw.ImageProvider?> loadedImages = {};
      for (var entry in _groupedResponses.entries) {
        for (var item in entry.value) {
          final response = (item['response'] ?? item['response_value'] ?? '').toString().toLowerCase().replaceAll(' ', '_');
          final photoUrl = item['photo_url'];
          if (response == 'not_ok' && photoUrl != null && photoUrl.isNotEmpty) {
            loadedImages[photoUrl] = await _loadNetworkImage(photoUrl);
          }
        }
      }

      // Convert signatures to PDF images
      final auditorSignatureImage = pw.MemoryImage(auditorSignature);
      final crewSignatureImage = pw.MemoryImage(crewSignature);
      
      // Create PDF document with a theme that supports Unicode
      final pdf = pw.Document(
        theme: pw.ThemeData.withFont(
          base: pw.Font.ttf(await rootBundle.load('assets/fonts/Roboto-Regular.ttf')),
          bold: pw.Font.ttf(await rootBundle.load('assets/fonts/Roboto-Bold.ttf')),
          italic: pw.Font.ttf(await rootBundle.load('assets/fonts/Roboto-Italic.ttf')),
          boldItalic: pw.Font.ttf(await rootBundle.load('assets/fonts/Roboto-BoldItalic.ttf')),
        ),
      );
      
      // ===== HALAMAN 1: Header, Visit Info, Financial, Assessment =====
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Professional Header with Border
                pw.Container(
                  padding: const pw.EdgeInsets.all(16),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(width: 2, color: PdfColors.blue900),
                    color: PdfColors.blue50,
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'LAPORAN VISIT',
                            style: pw.TextStyle(
                              fontSize: 28,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.blue900,
                            ),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            'TnD System - Audit Report',
                            style: pw.TextStyle(
                              fontSize: 12,
                              color: PdfColors.grey700,
                            ),
                          ),
                        ],
                      ),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Text(
                            'Tanggal Cetak:',
                            style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                          ),
                          pw.Text(
                            DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now()),
                            style: pw.TextStyle(
                              fontSize: 11,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                pw.SizedBox(height: 24),
                
                // Visit Information Section
                _buildPDFSectionHeader('INFORMASI VISIT'),
                pw.SizedBox(height: 8),
                _buildPDFInfoTable([
                  ['Outlet', widget.visit.outletName ?? '-'],
                  ['Lokasi', widget.visit.outletLocation ?? '-'],
                  ['Auditor', widget.visit.userName ?? '-'],
                  ['Tanggal Visit', _formatDate(widget.visit.visitDate)],
                  ['Status', _formatStatus(widget.visit.status)],
                ]),
                
                pw.SizedBox(height: 20),
                
                // Financial Data Section
                if (widget.visit.uangOmsetModal != null || widget.visit.total != null) ...[
                  _buildPDFSectionHeader('DATA KEUANGAN'),
                  pw.SizedBox(height: 8),
                  _buildPDFInfoTable([
                    if (widget.visit.uangOmsetModal != null)
                      ['Modal', _formatCurrency(widget.visit.uangOmsetModal!)],
                    if (widget.visit.uangDitukar != null)
                      ['Uang Ditukar', _formatCurrency(widget.visit.uangDitukar!)],
                    if (widget.visit.cash != null)
                      ['Cash', _formatCurrency(widget.visit.cash!)],
                    if (widget.visit.qris != null)
                      ['QRIS', _formatCurrency(widget.visit.qris!)],
                    if (widget.visit.debitKredit != null)
                      ['Debit/Kredit', _formatCurrency(widget.visit.debitKredit!)],
                  ]),
                  pw.Container(
                    margin: const pw.EdgeInsets.only(top: 8),
                    padding: const pw.EdgeInsets.all(12),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.blue100,
                      border: pw.Border.all(width: 1.5, color: PdfColors.blue900),
                    ),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'TOTAL',
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blue900,
                          ),
                        ),
                        pw.Text(
                          _formatCurrency(widget.visit.total ?? 0),
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blue900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  pw.SizedBox(height: 20),
                ],
                
                // Assessment Data Section
                if (widget.visit.kategoric != null || widget.visit.crewInCharge != null) ...[
                  _buildPDFSectionHeader('DATA ASSESSMENT'),
                  pw.SizedBox(height: 8),
                  _buildPDFInfoTable([
                    if (widget.visit.crewInCharge != null)
                      ['Crew in Charge', widget.visit.crewInCharge!],
                    if (widget.visit.kategoric != null)
                      ['Kategori', _formatKategoric(widget.visit.kategoric!)],
                    if (widget.visit.leadtime != null)
                      ['Leadtime', '${widget.visit.leadtime} hari'],
                    if (widget.visit.statusKeuangan != null)
                      ['Status', _formatStatusKeuangan(widget.visit.statusKeuangan!)],
                  ]),
                  pw.SizedBox(height: 20),
                ],
                
                // Recommendations Section (NOK Findings)
                if (_recommendations.isNotEmpty) ...[
                  _buildPDFSectionHeader('REKOMENDASI PERBAIKAN'),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    'Temuan yang memerlukan perbaikan:',
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontStyle: pw.FontStyle.italic,
                      color: PdfColors.grey700,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  ..._recommendations.take(3).map((finding) {
                    // Limit to 3 findings on page 1 to avoid overflow
                    return _buildPDFRecommendationItem(finding);
                  }),
                  if (_recommendations.length > 3)
                    pw.Padding(
                      padding: const pw.EdgeInsets.only(top: 8),
                      child: pw.Text(
                        '... dan ${_recommendations.length - 3} temuan lainnya (lihat halaman 2)',
                        style: pw.TextStyle(
                          fontSize: 9,
                          fontStyle: pw.FontStyle.italic,
                          color: PdfColors.grey600,
                        ),
                      ),
                    ),
                ],
                
                pw.Spacer(),
                
                // Footer for Page 1
                pw.Divider(thickness: 1, color: PdfColors.grey400),
                pw.SizedBox(height: 8),
                pw.Text(
                  'Halaman 1 dari 2 - Data Keuangan, Assessment & Rekomendasi',
                  style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                  textAlign: pw.TextAlign.center,
                ),
              ],
            );
          },
        ),
      );
      
      // ===== HALAMAN 2: Checklist Results =====
      if (_groupedResponses.isNotEmpty) {
        pdf.addPage(
          pw.MultiPage(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(40),
            build: (pw.Context context) {
              return [
                // Header Halaman 2
                pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(width: 1.5, color: PdfColors.blue900),
                    color: PdfColors.blue50,
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'HASIL CHECKLIST',
                        style: pw.TextStyle(
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue900,
                        ),
                      ),
                      pw.Text(
                        widget.visit.outletName ?? '-',
                        style: pw.TextStyle(
                          fontSize: 12,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ],
                  ),
                ),
                
                pw.SizedBox(height: 16),
                
                // ALL Checklist Results (OK & NOK together per category)
                _buildPDFSectionHeader('HASIL CHECKLIST'),
                pw.SizedBox(height: 8),
                ..._groupedResponses.entries.map((entry) {
                  return pw.Column(
                    children: [
                      _buildPDFChecklistCategoryAll(entry.key, entry.value),
                      pw.SizedBox(height: 12),
                    ],
                  );
                }),
                
                pw.Spacer(),
                
                // Footer
                pw.SizedBox(height: 20),
                pw.Divider(thickness: 1, color: PdfColors.grey400),
                pw.SizedBox(height: 8),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Halaman 2 - Hasil Checklist',
                      style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                    ),
                    pw.Text(
                      'Generated by TnD System',
                      style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                    ),
                  ],
                ),
              ];
            },
          ),
        );
      }
      
      // ===== HALAMAN 3+: NOK ITEMS DENGAN FOTO BESAR =====
      // Group NOK items by category
      final nokItemsByCategory = <String, List<Map<String, dynamic>>>{};
      for (var entry in _groupedResponses.entries) {
        final nokItems = entry.value.where((item) {
          final resp = (item['response'] ?? item['response_value'] ?? '').toString().toLowerCase().replaceAll(' ', '_');
          return resp == 'not_ok';
        }).toList();
        
        if (nokItems.isNotEmpty) {
          nokItemsByCategory[entry.key] = nokItems;
        }
      }
      
      // Create pages for NOK items if any exist
      if (nokItemsByCategory.isNotEmpty) {
        // Add page for each category with NOK items
        for (var entry in nokItemsByCategory.entries) {
          final categoryName = entry.key;
          final nokItems = entry.value;
          
          pdf.addPage(
            pw.Page(
              pageFormat: PdfPageFormat.a4,
              margin: const pw.EdgeInsets.all(40),
              build: (pw.Context context) {
                return pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Header
                    _buildPDFSectionHeader('LAMPIRAN FOTO - $categoryName'),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Dokumentasi foto untuk item NOK (Not OK)',
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontStyle: pw.FontStyle.italic,
                        color: PdfColors.grey700,
                      ),
                    ),
                    pw.SizedBox(height: 16),
                    
                    // NOK Items with large photos
                    ...nokItems.asMap().entries.map((itemEntry) {
                      final index = itemEntry.key;
                      final item = itemEntry.value;
                      final questionText = item['question'] ?? item['item_text'] ?? item['text'] ?? 'Unknown';
                      final photoUrl = item['photo_url'];
                      final notes = item['notes'];
                      final nokRemarks = item['nok_remarks']; // NEW: Get NOK remarks
                      
                      return pw.Container(
                        margin: const pw.EdgeInsets.only(bottom: 20),
                        padding: const pw.EdgeInsets.all(12),
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(color: PdfColors.red, width: 1.5),
                          borderRadius: pw.BorderRadius.circular(8),
                          color: PdfColors.red50,
                        ),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            // Header with number and item name
                            pw.Row(
                              children: [
                                pw.Container(
                                  width: 30,
                                  height: 30,
                                  decoration: pw.BoxDecoration(
                                    color: PdfColors.red,
                                    borderRadius: pw.BorderRadius.circular(15),
                                  ),
                                  child: pw.Center(
                                    child: pw.Text(
                                      '${index + 1}',
                                      style: pw.TextStyle(
                                        fontSize: 14,
                                        color: PdfColors.white,
                                        fontWeight: pw.FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                pw.SizedBox(width: 12),
                                pw.Expanded(
                                  child: pw.Column(
                                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                                    children: [
                                      pw.Text(
                                        questionText,
                                        style: pw.TextStyle(
                                          fontSize: 11,
                                          fontWeight: pw.FontWeight.bold,
                                          color: PdfColors.grey900,
                                        ),
                                      ),
                                      pw.SizedBox(height: 2),
                                      pw.Container(
                                        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: pw.BoxDecoration(
                                          color: PdfColors.red,
                                          borderRadius: pw.BorderRadius.circular(4),
                                        ),
                                        child: pw.Text(
                                          'NOK',
                                          style: pw.TextStyle(
                                            fontSize: 8,
                                            color: PdfColors.white,
                                            fontWeight: pw.FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            
                            pw.SizedBox(height: 10),
                            
                            // NOK Remarks (if any)
                            if (nokRemarks != null && nokRemarks.toString().isNotEmpty) ...[
                              pw.Container(
                                width: double.infinity,
                                padding: const pw.EdgeInsets.all(10),
                                decoration: pw.BoxDecoration(
                                  color: PdfColors.orange50,
                                  borderRadius: pw.BorderRadius.circular(6),
                                  border: pw.Border.all(color: PdfColors.orange200, width: 1),
                                ),
                                child: pw.Column(
                                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                                  children: [
                                    pw.Row(
                                      children: [
                                        pw.Container(
                                          width: 16,
                                          height: 16,
                                          decoration: pw.BoxDecoration(
                                            color: PdfColors.orange,
                                            borderRadius: pw.BorderRadius.circular(8),
                                          ),
                                          child: pw.Center(
                                            child: pw.Text(
                                              '!',
                                              style: pw.TextStyle(
                                                fontSize: 10,
                                                color: PdfColors.white,
                                                fontWeight: pw.FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                        pw.SizedBox(width: 6),
                                        pw.Text(
                                          'Catatan NOK:',
                                          style: pw.TextStyle(
                                            fontSize: 9,
                                            fontWeight: pw.FontWeight.bold,
                                            color: PdfColors.orange900,
                                          ),
                                        ),
                                      ],
                                    ),
                                    pw.SizedBox(height: 6),
                                    pw.Text(
                                      nokRemarks.toString(),
                                      style: pw.TextStyle(
                                        fontSize: 9,
                                        color: PdfColors.grey900,
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              pw.SizedBox(height: 10),
                            ] else ...[
                              pw.Container(
                                width: double.infinity,
                                padding: const pw.EdgeInsets.all(8),
                                decoration: pw.BoxDecoration(
                                  color: PdfColors.grey100,
                                  borderRadius: pw.BorderRadius.circular(6),
                                ),
                                child: pw.Text(
                                  'Catatan: Tidak ada catatan',
                                  style: pw.TextStyle(
                                    fontSize: 9,
                                    color: PdfColors.grey600,
                                    fontStyle: pw.FontStyle.italic,
                                  ),
                                ),
                              ),
                              pw.SizedBox(height: 10),
                            ],
                            
                            // Large Photo
                            if (photoUrl != null && photoUrl.isNotEmpty && loadedImages.containsKey(photoUrl))
                              pw.Center(
                                child: pw.Container(
                                  width: 400,
                                  height: 300,
                                  decoration: pw.BoxDecoration(
                                    border: pw.Border.all(color: PdfColors.grey400, width: 2),
                                    borderRadius: pw.BorderRadius.circular(8),
                                  ),
                                  child: pw.ClipRRect(
                                    horizontalRadius: 6,
                                    verticalRadius: 6,
                                    child: loadedImages[photoUrl] != null
                                      ? pw.Image(loadedImages[photoUrl]!, fit: pw.BoxFit.cover)
                                      : pw.Center(
                                          child: pw.Text(
                                            'Foto tidak tersedia',
                                            style: pw.TextStyle(
                                              fontSize: 10,
                                              color: PdfColors.grey600,
                                            ),
                                          ),
                                        ),
                                  ),
                                ),
                              )
                            else
                              pw.Container(
                                width: 400,
                                height: 300,
                                decoration: pw.BoxDecoration(
                                  color: PdfColors.grey200,
                                  border: pw.Border.all(color: PdfColors.grey400),
                                  borderRadius: pw.BorderRadius.circular(8),
                                ),
                                child: pw.Center(
                                  child: pw.Text(
                                    'Tidak ada foto',
                                    style: pw.TextStyle(
                                      fontSize: 12,
                                      color: PdfColors.grey600,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    }),
                    
                    pw.Spacer(),
                    
                    // Footer
                    pw.Divider(thickness: 1, color: PdfColors.grey400),
                    pw.SizedBox(height: 8),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'Item NOT OK - $categoryName',
                          style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                        ),
                        pw.Text(
                          'Generated by TnD System',
                          style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          );
        }
      }
      
      // ===== HALAMAN TERAKHIR: DIGITAL SIGNATURES =====
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Visit Summary
                pw.Container(
                  padding: const pw.EdgeInsets.all(16),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey100,
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Ringkasan Visit',
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.grey900,
                        ),
                      ),
                      pw.SizedBox(height: 12),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('Outlet:', style: pw.TextStyle(fontSize: 11, color: PdfColors.grey700)),
                          pw.Text(widget.visit.outletName ?? '-', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                        ],
                      ),
                      pw.SizedBox(height: 6),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('Tanggal:', style: pw.TextStyle(fontSize: 11, color: PdfColors.grey700)),
                          pw.Text(_formatDate(widget.visit.visitDate), style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                        ],
                      ),
                      pw.SizedBox(height: 6),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('Status:', style: pw.TextStyle(fontSize: 11, color: PdfColors.grey700)),
                          pw.Text(_formatStatus(widget.visit.status), style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                ),
                
                pw.SizedBox(height: 60),
                
                // Signatures Section
                pw.Text(
                  'Dengan ini kami menyatakan bahwa laporan visit ini telah dibuat dengan sebenar-benarnya.',
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontStyle: pw.FontStyle.italic,
                    color: PdfColors.grey700,
                  ),
                ),
                
                pw.SizedBox(height: 40),
                
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Auditor Signature
                    pw.Expanded(
                      child: pw.Column(
                        children: [
                          pw.Text(
                            'Auditor',
                            style: pw.TextStyle(
                              fontSize: 12,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.grey800,
                            ),
                          ),
                          pw.SizedBox(height: 20),
                          // Signature Image
                          pw.Container(
                            height: 80,
                            width: 160,
                            decoration: pw.BoxDecoration(
                              border: pw.Border.all(color: PdfColors.grey400, width: 1.5),
                              borderRadius: pw.BorderRadius.circular(4),
                            ),
                            child: pw.Image(auditorSignatureImage, fit: pw.BoxFit.contain),
                          ),
                          pw.SizedBox(height: 12),
                          pw.Container(
                            height: 2,
                            width: 160,
                            color: PdfColors.grey800,
                          ),
                          pw.SizedBox(height: 8),
                          pw.Text(
                            widget.visit.userName ?? '-',
                            style: pw.TextStyle(
                              fontSize: 11,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            DateFormat('dd MMMM yyyy', 'id_ID').format(widget.visit.visitDate),
                            style: pw.TextStyle(
                              fontSize: 10,
                              color: PdfColors.grey600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    pw.SizedBox(width: 60),
                    
                    // Crew in Charge Signature
                    pw.Expanded(
                      child: pw.Column(
                        children: [
                          pw.Text(
                            'Crew in Charge',
                            style: pw.TextStyle(
                              fontSize: 12,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.grey800,
                            ),
                          ),
                          pw.SizedBox(height: 20),
                          // Signature Image
                          pw.Container(
                            height: 80,
                            width: 160,
                            decoration: pw.BoxDecoration(
                              border: pw.Border.all(color: PdfColors.grey400, width: 1.5),
                              borderRadius: pw.BorderRadius.circular(4),
                            ),
                            child: pw.Image(crewSignatureImage, fit: pw.BoxFit.contain),
                          ),
                          pw.SizedBox(height: 12),
                          pw.Container(
                            height: 2,
                            width: 160,
                            color: PdfColors.grey800,
                          ),
                          pw.SizedBox(height: 8),
                          pw.Text(
                            widget.visit.crewInCharge ?? '-',
                            style: pw.TextStyle(
                              fontSize: 11,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            DateFormat('dd MMMM yyyy', 'id_ID').format(widget.visit.visitDate),
                            style: pw.TextStyle(
                              fontSize: 10,
                              color: PdfColors.grey600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                pw.Spacer(),
                
                // Footer
                pw.Divider(thickness: 1, color: PdfColors.grey400),
                pw.SizedBox(height: 8),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Halaman Tanda Tangan',
                      style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                    ),
                    pw.Text(
                      'Generated by TnD System',
                      style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      );
      
      // Save PDF
      final output = await getTemporaryDirectory();
      final fileName = 'Laporan_Visit_${widget.visit.outletName}_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf';
      final file = File('${output.path}/$fileName');
      await file.writeAsBytes(await pdf.save());
      
      setState(() => _isExporting = false);
      
      if (mounted) {
        // Show options to open or share
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('PDF Berhasil Dibuat'),
            content: Text('File: $fileName'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Share.shareXFiles([XFile(file.path)], text: 'Laporan Visit');
                },
                child: const Text('Share'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await OpenFile.open(file.path);
                },
                child: const Text('Buka'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      setState(() => _isExporting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error membuat PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // NEW METHOD: Build checklist category with ALL items (OK & NOK together)
  pw.Widget _buildPDFChecklistCategoryAll(
    String categoryName, 
    List<Map<String, dynamic>> items,
  ) {
    int okCount = items.where((item) {
      final resp = (item['response'] ?? item['response_value'] ?? '').toString().toLowerCase().replaceAll(' ', '_');
      return resp == 'ok';
    }).length;
    
    int nokCount = items.where((item) {
      final resp = (item['response'] ?? item['response_value'] ?? '').toString().toLowerCase().replaceAll(' ', '_');
      return resp == 'not_ok';
    }).length;
    
    int naCount = items.where((item) {
      final resp = (item['response'] ?? item['response_value'] ?? '').toString().toLowerCase().replaceAll(' ', '_');
      return resp == 'na';
    }).length;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Category Header
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: pw.BoxDecoration(
            gradient: const pw.LinearGradient(
              colors: [PdfColors.blue800, PdfColors.blue600],
            ),
            borderRadius: pw.BorderRadius.circular(6),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                categoryName.toUpperCase(),
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
              ),
              pw.Row(
                children: [
                  _buildPDFStatBadge('OK', okCount, PdfColors.green),
                  pw.SizedBox(width: 4),
                  _buildPDFStatBadge('NOK', nokCount, PdfColors.red),
                  pw.SizedBox(width: 4),
                  _buildPDFStatBadge('N/A', naCount, PdfColors.grey600),
                ],
              ),
            ],
          ),
        ),
        
        pw.SizedBox(height: 6),
        
        // ALL items (OK, NOK, N/A)
        ...items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final response = (item['response'] ?? item['response_value'] ?? '').toString().toLowerCase().replaceAll(' ', '_');
          final questionText = item['question'] ?? item['item_text'] ?? item['text'] ?? 'Unknown';
          final nokRemarks = item['nok_remarks']; // Get NOK remarks
          
          String statusLabel;
          PdfColor bgColor;
          PdfColor borderColor;
          
          switch (response) {
            case 'ok':
              statusLabel = '✓';
              bgColor = PdfColors.green50;
              borderColor = PdfColors.green300;
              break;
            case 'not_ok':
              statusLabel = '✗';
              bgColor = PdfColors.red50;
              borderColor = PdfColors.red300;
              break;
            default:
              statusLabel = 'N/A';
              bgColor = PdfColors.grey100;
              borderColor = PdfColors.grey300;
          }
          
          return pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 4),
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              color: bgColor,
              border: pw.Border.all(color: borderColor, width: 1),
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Number
                    pw.Container(
                      width: 24,
                      child: pw.Text(
                        '${index + 1}.',
                        style: pw.TextStyle(
                          fontSize: 9,
                          color: PdfColors.grey700,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                    // Question text
                    pw.Expanded(
                      child: pw.Text(
                        questionText,
                        style: pw.TextStyle(
                          fontSize: 9,
                          color: PdfColors.grey900,
                        ),
                      ),
                    ),
                    pw.SizedBox(width: 8),
                    // Status badge
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: pw.BoxDecoration(
                        color: response == 'ok' 
                          ? PdfColors.green 
                          : response == 'not_ok'
                            ? PdfColors.red
                            : PdfColors.grey600,
                        borderRadius: pw.BorderRadius.circular(10),
                      ),
                      child: pw.Text(
                        statusLabel,
                        style: pw.TextStyle(
                          fontSize: 8,
                          color: PdfColors.white,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                // NOK Remarks (indent)
                if (response == 'not_ok' && nokRemarks != null && nokRemarks.toString().isNotEmpty) ...[
                  pw.SizedBox(height: 4),
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(left: 24),
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(6),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.orange50,
                        borderRadius: pw.BorderRadius.circular(4),
                        border: pw.Border.all(color: PdfColors.orange200, width: 0.5),
                      ),
                      child: pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            '└─ Catatan: ',
                            style: pw.TextStyle(
                              fontSize: 8,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.orange900,
                            ),
                          ),
                          pw.Expanded(
                            child: pw.Text(
                              nokRemarks.toString(),
                              style: pw.TextStyle(
                                fontSize: 8,
                                color: PdfColors.grey900,
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ] else if (response == 'not_ok') ...[
                  pw.SizedBox(height: 4),
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(left: 24),
                    child: pw.Text(
                      '└─ Catatan: Tidak ada catatan',
                      style: pw.TextStyle(
                        fontSize: 8,
                        color: PdfColors.grey600,
                        fontStyle: pw.FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        }),
      ],
    );
  }

  // Helper method untuk section header yang profesional
  pw.Widget _buildPDFSectionHeader(String title) {
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

  // Helper method untuk table informasi
  pw.Widget _buildPDFInfoTable(List<List<String>> rows) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(2),
        1: const pw.FlexColumnWidth(3),
      },
      children: rows.map((row) {
        return pw.TableRow(
          decoration: const pw.BoxDecoration(
            color: PdfColors.white,
          ),
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
              child: pw.Text(
                row[1],
                style: const pw.TextStyle(
                  fontSize: 11,
                  color: PdfColors.black,
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  // Build category with OK items only (compact, no photos)
  pw.Widget _buildPDFChecklistCategoryOKOnly(
    String categoryName, 
    List<Map<String, dynamic>> items,
  ) {
    // Filter only OK and N/A items
    final okAndNaItems = items.where((item) {
      final resp = (item['response'] ?? item['response_value'] ?? '').toString().toLowerCase().replaceAll(' ', '_');
      return resp == 'ok' || resp == 'na';
    }).toList();
    
    // Skip if no OK/NA items
    if (okAndNaItems.isEmpty) {
      return pw.SizedBox();
    }
    
    int passCount = items.where((item) {
      final resp = (item['response'] ?? item['response_value'] ?? '').toString().toLowerCase().replaceAll(' ', '_');
      return resp == 'ok';
    }).length;
    
    int naCount = items.where((item) {
      final resp = (item['response'] ?? item['response_value'] ?? '').toString().toLowerCase().replaceAll(' ', '_');
      return resp == 'na';
    }).length;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Category Header
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 10),
          decoration: pw.BoxDecoration(
            color: PdfColors.green900,
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                categoryName.toUpperCase(),
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
              ),
              pw.Row(
                children: [
                  _buildPDFStatBadge('OK', passCount, PdfColors.green),
                  pw.SizedBox(width: 4),
                  _buildPDFStatBadge('N/A', naCount, PdfColors.grey600),
                ],
              ),
            ],
          ),
        ),
        
        pw.SizedBox(height: 4),
        
        // Compact list of OK items (no photos)
        ...okAndNaItems.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final response = (item['response'] ?? item['response_value'] ?? '').toString().toLowerCase().replaceAll(' ', '_');
          final questionText = item['question'] ?? item['item_text'] ?? item['text'] ?? 'Unknown';
          
          String statusText;
          PdfColor bgColor;
          
          switch (response) {
            case 'ok':
              statusText = 'V';
              bgColor = PdfColors.green;
              break;
            default:
              statusText = '-';
              bgColor = PdfColors.grey400;
          }
          
          return pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 3),
            padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 6),
            decoration: pw.BoxDecoration(
              color: PdfColors.white,
              border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
              borderRadius: pw.BorderRadius.circular(3),
            ),
            child: pw.Row(
              children: [
                // Number
                pw.SizedBox(
                  width: 20,
                  child: pw.Text(
                    '${index + 1}.',
                    style: pw.TextStyle(
                      fontSize: 8,
                      color: PdfColors.grey700,
                    ),
                  ),
                ),
                // Status badge (compact)
                pw.Container(
                  width: 20,
                  height: 14,
                  margin: const pw.EdgeInsets.only(right: 6),
                  decoration: pw.BoxDecoration(
                    color: bgColor,
                    borderRadius: pw.BorderRadius.circular(2),
                  ),
                  child: pw.Center(
                    child: pw.Text(
                      statusText,
                      style: pw.TextStyle(
                        fontSize: 8,
                        color: PdfColors.white,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                // Question text (compact)
                pw.Expanded(
                  child: pw.Text(
                    questionText,
                    style: const pw.TextStyle(
                      fontSize: 8,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // Helper untuk badge statistik
  pw.Widget _buildPDFStatBadge(String label, int count, PdfColor color) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: pw.BoxDecoration(
        color: color,
        borderRadius: pw.BorderRadius.circular(3),
      ),
      child: pw.Text(
        '$label: $count',
        style: pw.TextStyle(
          fontSize: 8,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.white,
        ),
      ),
    );
  }

  // Helper untuk cell table
  // Helper untuk item rekomendasi (temuan NOT_OK)
  pw.Widget _buildPDFRecommendationItem(Map<String, dynamic> finding) {
    final question = finding['checklist_question'] ?? finding['item_text'] ?? 'Unknown';
    final category = finding['category_name'] ?? 'Uncategorized';
    final notes = finding['response_notes'] ?? finding['notes'] ?? '-';
    
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 10),
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.red300, width: 1),
        borderRadius: pw.BorderRadius.circular(4),
        color: PdfColors.red50,
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: pw.BoxDecoration(
                  color: PdfColors.red,
                  borderRadius: pw.BorderRadius.circular(3),
                ),
                child: pw.Text(
                  'X',
                  style: pw.TextStyle(
                    fontSize: 9,
                    color: PdfColors.white,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(width: 8),
              pw.Expanded(
                child: pw.Text(
                  question,
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.red900,
                  ),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Kategori: $category',
            style: pw.TextStyle(
              fontSize: 8,
              color: PdfColors.grey700,
              fontStyle: pw.FontStyle.italic,
            ),
          ),
          if (notes != '-') ...[
            pw.SizedBox(height: 4),
            pw.Text(
              'Catatan: $notes',
              style: const pw.TextStyle(
                fontSize: 9,
                color: PdfColors.grey800,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatCurrency(double value) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Detail Laporan Visit'),
        elevation: 0,
        actions: [
          // PDF Export Button
          IconButton(
            icon: _isExporting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.picture_as_pdf),
            onPressed: _isExporting ? null : _exportPDF,
            tooltip: 'Export PDF',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Visit Info Card
                  _buildVisitInfoCard(),
                  
                  const SizedBox(height: 16),
                  
                  // Financial & Assessment Section
                  if (widget.visit.uangOmsetModal != null || 
                      widget.visit.kategoric != null ||
                      widget.visit.crewInCharge != null)
                    _buildFinancialAssessmentSection(),
                  
                  const SizedBox(height: 16),
                  
                  // Recommendations Section
                  if (_recommendations.isNotEmpty)
                    _buildRecommendationsSection(),
                  
                  const SizedBox(height: 16),
                  
                  // Checklist Results
                  _buildChecklistSection(),
                  
                  const SizedBox(height: 100),
                ],
              ),
            ),
    );
  }

  Widget _buildVisitInfoCard() {
    return Container(
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
                      widget.visit.outletName ?? 'Unknown Outlet',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.visit.outletLocation ?? '',
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
            widget.visit.checkInTime ?? 
              (widget.visit.startedAt != null 
                ? _formatTime(widget.visit.startedAt!)
                : '-'),
          ),
          const SizedBox(height: 8),
          _buildInfoRow(
            Icons.info_outline,
            _formatStatus(widget.visit.status),
          ),
        ],
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
                  _buildFinancialItem('Modal', widget.visit.uangOmsetModal!),
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
                  _buildAssessmentItem('Kategori', _formatKategoric(widget.visit.kategoric!)),
                
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

  Widget _buildRecommendationsSection() {
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
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.red[700],
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Rekomendasi Perbaikan',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.red[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_recommendations.length} Temuan',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.red[900],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Item yang memerlukan perbaikan:',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 16),
              ..._recommendations.map((finding) {
                return _buildRecommendationItem(finding);
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecommendationItem(Map<String, dynamic> finding) {
    final question = finding['checklist_question'] ?? finding['item_text'] ?? 'Unknown';
    final category = finding['category_name'] ?? 'Uncategorized';
    final notes = finding['response_notes'] ?? finding['notes'] ?? '';
    final photos = finding['photos'] as List<dynamic>? ?? [];
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.red[50],
        border: Border.all(color: Colors.red[200]!, width: 1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'X',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  question,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.red[900],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.category, size: 14, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                category,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[700],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          if (notes.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[100]!),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.note_alt, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      notes,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[800],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (photos.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'Foto Bukti:',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: photos.length,
                itemBuilder: (context, index) {
                  final photo = photos[index];
                  final photoUrl = photo['url'] ?? '';
                  
                  return Container(
                    margin: const EdgeInsets.only(right: 8),
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red[200]!),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: photoUrl.isNotEmpty
                          ? Image.network(
                              photoUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(
                                  Icons.broken_image,
                                  color: Colors.grey[400],
                                  size: 32,
                                );
                              },
                            )
                          : Icon(
                              Icons.image_not_supported,
                              color: Colors.grey[400],
                              size: 32,
                            ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildChecklistSection() {
    if (_groupedResponses.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.checklist_outlined,
                    size: 60,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Tidak ada data checklist',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      children: _groupedResponses.entries.map((entry) {
        return _buildCategorySection(entry.key, entry.value);
      }).toList(),
    );
  }

  Widget _buildCategorySection(String categoryName, List<Map<String, dynamic>> items) {
    // Calculate statistics - handle both 'ok'/'not_ok' and 'pass'/'fail'
    int totalItems = items.length;
    int passedItems = items.where((item) {
      final val = (item['response'] ?? item['response_value'] ?? '').toString().toLowerCase().replaceAll(' ', '_');
      return val == 'pass' || val == 'ok';
    }).length;
    int failedItems = items.where((item) {
      final val = (item['response'] ?? item['response_value'] ?? '').toString().toLowerCase().replaceAll(' ', '_');
      return val == 'fail' || val == 'not_ok';
    }).length;
    int naItems = items.where((item) {
      final val = (item['response'] ?? item['response_value'] ?? '').toString().toLowerCase().replaceAll(' ', '_');
      return val == 'na' || val == 'n/a';
    }).length;
    
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

  Color _getPercentageColor(double percentage) {
    if (percentage >= 80) return Colors.green;
    if (percentage >= 60) return Colors.orange;
    return Colors.red;
  }

  Widget _buildChecklistItem(Map<String, dynamic> item) {
    final responseValue = (item['response'] ?? item['response_value'] ?? '').toString().toLowerCase().replaceAll(' ', '_');
    final itemText = item['question'] ?? item['item_text'] ?? item['text'] ?? 'Unknown';
    final notes = item['notes'];
    final photoUrl = item['photo_url'];

    IconData icon;
    Color color;

    // Handle both 'ok'/'not_ok'/'na' (from DB) and 'pass'/'fail'/'na' (from app)
    if (responseValue == 'pass' || responseValue == 'ok') {
      icon = Icons.check_circle;
      color = Colors.green;
    } else if (responseValue == 'fail' || responseValue == 'not_ok') {
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

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _formatStatus(String status) {
    switch (status) {
      case 'completed':
        return 'Selesai';
      case 'in_progress':
        return 'Berlangsung';
      case 'scheduled':
        return 'Terjadwal';
      default:
        return status;
    }
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

  // Helper function to load network image for PDF
  Future<pw.ImageProvider?> _loadNetworkImage(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        return pw.MemoryImage(response.bodyBytes);
      }
    } catch (e) {
      print('Error loading image for PDF: $e');
    }
    return null;
  }
}

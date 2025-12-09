# 🚀 MAJOR SYSTEM CHANGES - Implementation Guide

## 📋 OVERVIEW

**Changes Requested:**
1. ✅ Add manual financial form di category screen (mobile)
2. ✅ Enhanced PDF report dengan detail checklist points
3. ✅ Generate PDF report per outlet

---

## 🗄️ PHASE 1: DATABASE CHANGES

### Files Created:
- ✅ `database/schema_add_visit_financial_form.sql`

### What to do:
```sql
-- Run this SQL in production database (phpMyAdmin)
1. Backup database first!
2. Run schema_add_visit_financial_form.sql
3. Verify columns added: DESCRIBE visits;
```

### New Columns Added to `visits` table:
| Column | Type | Description |
|--------|------|-------------|
| uang_omset_modal | DECIMAL(15,2) | Uang omset + modal |
| uang_ditukar | DECIMAL(15,2) | Uang yang ditukar |
| cash | DECIMAL(15,2) | Pembayaran cash |
| qris | DECIMAL(15,2) | Pembayaran QRIS |
| debit_kredit | DECIMAL(15,2) | Pembayaran debit/kredit |
| total_pembayaran | DECIMAL(15,2) | Total pembayaran |
| kategoric | ENUM | 'minor', 'major', 'ZT' |
| leadtime | INT | Lead time (minutes) |
| status_keuangan | ENUM | 'open', 'close' |

---

## 📱 PHASE 2: MOBILE APP CHANGES

### File Structure:
```
tnd_mobile_flutter/
├── lib/
│   ├── models/
│   │   └── visit_model.dart                    ← UPDATE (add new fields)
│   ├── services/
│   │   └── visit_service.dart                   ← UPDATE (save financial data)
│   └── screens/
│       ├── visit_category_list_screen.dart      ← UPDATE (add financial form)
│       └── category_checklist_screen.dart       ← UPDATE (show form per category)
```

### Changes Needed:

#### 1. **Update VisitModel** (`lib/models/visit_model.dart`)
```dart
class VisitModel {
  // Existing fields...
  
  // NEW FIELDS:
  final double? uangOmsetModal;
  final double? uangDitukar;
  final double? cash;
  final double? qris;
  final double? debitKredit;
  final double? totalPembayaran;
  final String? kategoric;  // 'minor', 'major', 'ZT'
  final int? leadtime;
  final String? statusKeuangan;  // 'open', 'close'
  
  VisitModel({
    // existing parameters...
    this.uangOmsetModal,
    this.uangDitukar,
    this.cash,
    this.qris,
    this.debitKredit,
    this.totalPembayaran,
    this.kategoric,
    this.leadtime,
    this.statusKeuangan,
  });
  
  factory VisitModel.fromJson(Map<String, dynamic> json) {
    return VisitModel(
      // existing fields...
      uangOmsetModal: json['uang_omset_modal'] != null 
          ? double.parse(json['uang_omset_modal'].toString()) : null,
      uangDitukar: json['uang_ditukar'] != null 
          ? double.parse(json['uang_ditukar'].toString()) : null,
      cash: json['cash'] != null 
          ? double.parse(json['cash'].toString()) : null,
      qris: json['qris'] != null 
          ? double.parse(json['qris'].toString()) : null,
      debitKredit: json['debit_kredit'] != null 
          ? double.parse(json['debit_kredit'].toString()) : null,
      totalPembayaran: json['total_pembayaran'] != null 
          ? double.parse(json['total_pembayaran'].toString()) : null,
      kategoric: json['kategoric'],
      leadtime: json['leadtime'],
      statusKeuangan: json['status_keuangan'],
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      // existing fields...
      'uang_omset_modal': uangOmsetModal,
      'uang_ditukar': uangDitukar,
      'cash': cash,
      'qris': qris,
      'debit_kredit': debitKredit,
      'total_pembayaran': totalPembayaran,
      'kategoric': kategoric,
      'leadtime': leadtime,
      'status_keuangan': statusKeuangan,
    };
  }
}
```

#### 2. **Add Financial Form Screen**

Create new file: `lib/screens/visit_financial_form_screen.dart`

```dart
import 'package:flutter/material.dart';
import '../models/visit_model.dart';

class VisitFinancialFormScreen extends StatefulWidget {
  final VisitModel visit;
  final Function(Map<String, dynamic>) onSave;
  
  const VisitFinancialFormScreen({
    Key? key,
    required this.visit,
    required this.onSave,
  }) : super(key: key);
  
  @override
  State<VisitFinancialFormScreen> createState() => _VisitFinancialFormScreenState();
}

class _VisitFinancialFormScreenState extends State<VisitFinancialFormScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final _omsetModalController = TextEditingController();
  final _ditukarController = TextEditingController();
  final _cashController = TextEditingController();
  final _qrisController = TextEditingController();
  final _debitKreditController = TextEditingController();
  final _leadtimeController = TextEditingController();
  
  String? _selectedKategoric = 'minor';
  String? _selectedStatus = 'open';
  double _total = 0;
  
  @override
  void initState() {
    super.initState();
    _loadExistingData();
    
    // Auto-calculate total when values change
    _cashController.addListener(_calculateTotal);
    _qrisController.addListener(_calculateTotal);
    _debitKreditController.addListener(_calculateTotal);
  }
  
  void _loadExistingData() {
    if (widget.visit.uangOmsetModal != null) {
      _omsetModalController.text = widget.visit.uangOmsetModal.toString();
    }
    if (widget.visit.uangDitukar != null) {
      _ditukarController.text = widget.visit.uangDitukar.toString();
    }
    if (widget.visit.cash != null) {
      _cashController.text = widget.visit.cash.toString();
    }
    if (widget.visit.qris != null) {
      _qrisController.text = widget.visit.qris.toString();
    }
    if (widget.visit.debitKredit != null) {
      _debitKreditController.text = widget.visit.debitKredit.toString();
    }
    if (widget.visit.leadtime != null) {
      _leadtimeController.text = widget.visit.leadtime.toString();
    }
    
    _selectedKategoric = widget.visit.kategoric ?? 'minor';
    _selectedStatus = widget.visit.statusKeuangan ?? 'open';
    _calculateTotal();
  }
  
  void _calculateTotal() {
    setState(() {
      double cash = double.tryParse(_cashController.text) ?? 0;
      double qris = double.tryParse(_qrisController.text) ?? 0;
      double debitKredit = double.tryParse(_debitKreditController.text) ?? 0;
      _total = cash + qris + debitKredit;
    });
  }
  
  void _save() {
    if (_formKey.currentState!.validate()) {
      final data = {
        'uang_omset_modal': double.tryParse(_omsetModalController.text),
        'uang_ditukar': double.tryParse(_ditukarController.text),
        'cash': double.tryParse(_cashController.text),
        'qris': double.tryParse(_qrisController.text),
        'debit_kredit': double.tryParse(_debitKreditController.text),
        'total_pembayaran': _total,
        'kategoric': _selectedKategoric,
        'leadtime': int.tryParse(_leadtimeController.text),
        'status_keuangan': _selectedStatus,
      };
      
      widget.onSave(data);
      Navigator.pop(context);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Financial Form'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _save,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Uang Omset + Modal
            TextFormField(
              controller: _omsetModalController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Uang Omset + Modal',
                prefixText: 'Rp ',
              ),
            ),
            const SizedBox(height: 16),
            
            // Ditukar
            TextFormField(
              controller: _ditukarController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Ditukar',
                prefixText: 'Rp ',
              ),
            ),
            const SizedBox(height: 24),
            
            const Text('Metode Pembayaran', 
                       style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            
            // Cash
            TextFormField(
              controller: _cashController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Cash',
                prefixText: 'Rp ',
              ),
            ),
            const SizedBox(height: 16),
            
            // QRIS
            TextFormField(
              controller: _qrisController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'QRIS',
                prefixText: 'Rp ',
              ),
            ),
            const SizedBox(height: 16),
            
            // Debit/Kredit
            TextFormField(
              controller: _debitKreditController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Debit/Kredit',
                prefixText: 'Rp ',
              ),
            ),
            const SizedBox(height: 16),
            
            // Total (Auto-calculated)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total', 
                            style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('Rp ${_total.toStringAsFixed(0)}',
                       style: const TextStyle(
                         fontSize: 18,
                         fontWeight: FontWeight.bold,
                         color: Colors.blue,
                       )),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Kategoric
            DropdownButtonFormField<String>(
              value: _selectedKategoric,
              decoration: const InputDecoration(
                labelText: 'Kategoric',
              ),
              items: ['minor', 'major', 'ZT'].map((value) {
                return DropdownMenuItem(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedKategoric = value;
                });
              },
            ),
            const SizedBox(height: 16),
            
            // Leadtime
            TextFormField(
              controller: _leadtimeController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Lead Time (menit)',
                suffixText: 'menit',
              ),
            ),
            const SizedBox(height: 16),
            
            // Status
            DropdownButtonFormField<String>(
              value: _selectedStatus,
              decoration: const InputDecoration(
                labelText: 'Status',
              ),
              items: ['open', 'close'].map((value) {
                return DropdownMenuItem(
                  value: value,
                  child: Text(value.toUpperCase()),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedStatus = value;
                });
              },
            ),
            const SizedBox(height: 32),
            
            // Save Button
            ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Save Financial Data'),
            ),
          ],
        ),
      ),
    );
  }
  
  @override
  void dispose() {
    _omsetModalController.dispose();
    _ditukarController.dispose();
    _cashController.dispose();
    _qrisController.dispose();
    _debitKreditController.dispose();
    _leadtimeController.dispose();
    super.dispose();
  }
}
```

#### 3. **Update Visit Category List Screen**

Add button to open financial form in `visit_category_list_screen.dart`:

```dart
// Add FloatingActionButton to open financial form
floatingActionButton: FloatingActionButton.extended(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VisitFinancialFormScreen(
          visit: widget.visit,
          onSave: (data) async {
            // Save financial data
            await _visitService.updateVisit(widget.visit.id, data);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Financial data saved')),
            );
          },
        ),
      ),
    );
  },
  icon: const Icon(Icons.account_balance_wallet),
  label: const Text('Financial Form'),
),
```

---

## 🌐 PHASE 3: BACKEND API ENHANCEMENTS

### Files to Update:

#### 1. **Update Visit Detail API**

File: `backend-web/api/visit-detail.php`

Add financial fields to response:

```php
// Get visit with financial data
$sql = "SELECT 
            v.*,
            o.name as outlet_name,
            o.address as outlet_address,
            u.full_name as user_name,
            
            -- Financial data
            v.uang_omset_modal,
            v.uang_ditukar,
            v.cash,
            v.qris,
            v.debit_kredit,
            v.total_pembayaran,
            v.kategoric,
            v.leadtime,
            v.status_keuangan
            
        FROM visits v
        LEFT JOIN outlets o ON v.outlet_id = o.id
        LEFT JOIN users u ON v.user_id = u.id
        WHERE v.id = :visit_id";
```

#### 2. **Create Enhanced PDF Export API**

File: `backend-web/api/export-outlet-report-pdf.php` (NEW)

```php
<?php
/**
 * Export Outlet Report PDF
 * Generate detailed PDF report per outlet with checklist details
 */

require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../classes/Database.php';
require_once __DIR__ . '/../utils/Response.php';
require_once __DIR__ . '/../utils/Auth.php';

// Check required parameters
if (!isset($_GET['outlet_id'])) {
    Response::error('Outlet ID required', 400);
}

$outletId = intval($_GET['outlet_id']);
$startDate = $_GET['start_date'] ?? null;
$endDate = $_GET['end_date'] ?? null;

try {
    $db = Database::getInstance()->getConnection();
    
    // Get outlet info
    $sql = "SELECT * FROM outlets WHERE id = ?";
    $stmt = $db->prepare($sql);
    $stmt->execute([$outletId]);
    $outlet = $stmt->fetch(PDO::FETCH_ASSOC);
    
    if (!$outlet) {
        Response::error('Outlet not found', 404);
    }
    
    // Build date filter
    $dateFilter = "";
    $params = [$outletId];
    
    if ($startDate && $endDate) {
        $dateFilter = " AND DATE(v.visit_date) BETWEEN ? AND ?";
        $params[] = $startDate;
        $params[] = $endDate;
    }
    
    // Get all visits for this outlet with financial data
    $sql = "SELECT 
                v.*,
                u.full_name as auditor_name,
                v.uang_omset_modal,
                v.uang_ditukar,
                v.cash,
                v.qris,
                v.debit_kredit,
                v.total_pembayaran,
                v.kategoric,
                v.leadtime,
                v.status_keuangan
            FROM visits v
            LEFT JOIN users u ON v.user_id = u.id
            WHERE v.outlet_id = ? 
            AND v.status = 'completed'
            {$dateFilter}
            ORDER BY v.visit_date DESC";
    
    $stmt = $db->prepare($sql);
    $stmt->execute($params);
    $visits = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    // For each visit, get detailed checklist responses
    foreach ($visits as &$visit) {
        // Get checklist responses grouped by category
        $sql = "SELECT 
                    vcr.id,
                    vcr.response,
                    vcr.notes,
                    cp.question as checklist_point,
                    cc.name as category_name,
                    cc.id as category_id
                FROM visit_checklist_responses vcr
                INNER JOIN checklist_points cp ON vcr.checklist_point_id = cp.id
                INNER JOIN checklist_categories cc ON cp.category_id = cc.id
                WHERE vcr.visit_id = ?
                ORDER BY cc.sort_order, cp.sort_order";
        
        $stmt = $db->prepare($sql);
        $stmt->execute([$visit['id']]);
        $responses = $stmt->fetchAll(PDO::FETCH_ASSOC);
        
        // Group by category
        $grouped = [];
        foreach ($responses as $resp) {
            $catId = $resp['category_id'];
            $catName = $resp['category_name'];
            
            if (!isset($grouped[$catId])) {
                $grouped[$catId] = [
                    'category_name' => $catName,
                    'items' => []
                ];
            }
            
            $grouped[$catId]['items'][] = [
                'point' => $resp['checklist_point'],
                'response' => $resp['response'],
                'notes' => $resp['notes']
            ];
        }
        
        $visit['checklist_details'] = array_values($grouped);
        
        // Get photos for NOK items
        $sql = "SELECT 
                    p.file_path,
                    cp.question
                FROM photos p
                INNER JOIN checklist_points cp ON p.item_id = cp.id
                INNER JOIN visit_checklist_responses vcr 
                    ON p.visit_id = vcr.visit_id AND p.item_id = vcr.checklist_point_id
                WHERE p.visit_id = ?
                AND vcr.response = 'NOT OK'";
        
        $stmt = $db->prepare($sql);
        $stmt->execute([$visit['id']]);
        $photos = $stmt->fetchAll(PDO::FETCH_ASSOC);
        
        // Convert to full URLs
        $protocol = isset($_SERVER['HTTPS']) && $_SERVER['HTTPS'] === 'on' ? 'https' : 'http';
        $host = $_SERVER['HTTP_HOST'];
        $baseUrl = $protocol . '://' . $host . '/backend-web/';
        
        foreach ($photos as &$photo) {
            $photo['photo_url'] = $baseUrl . $photo['file_path'];
        }
        
        $visit['photos'] = $photos;
    }
    
    Response::success([
        'outlet' => $outlet,
        'visits' => $visits,
        'total_visits' => count($visits),
        'date_range' => [
            'start' => $startDate,
            'end' => $endDate
        ]
    ]);
    
} catch (Exception $e) {
    Response::error('Server error: ' . $e->getMessage(), 500);
}
?>
```

---

## 📄 PHASE 4: ENHANCED PDF GENERATION (Frontend)

### File to Create:

`frontend-web/assets/js/enhanced-pdf-generator.js`

```javascript
/**
 * Enhanced PDF Generator with Detailed Checklist
 */

async function generateEnhancedOutletReport(outletId, outletName, startDate, endDate) {
    const { jsPDF } = window.jspdf;
    const doc = new jsPDF();
    
    // Show loading
    Swal.fire({
        title: 'Generating PDF...',
        text: 'Please wait while we prepare your report',
        allowOutsideClick: false,
        didOpen: () => {
            Swal.showLoading();
        }
    });
    
    try {
        // Fetch data
        let url = `/api/export-outlet-report-pdf.php?outlet_id=${outletId}`;
        if (startDate) url += `&start_date=${startDate}`;
        if (endDate) url += `&end_date=${endDate}`;
        
        const response = await API.get(url);
        const data = response.data;
        
        let yPos = 20;
        
        // Title Page
        doc.setFontSize(24);
        doc.setFont(undefined, 'bold');
        doc.text('VISIT REPORT', 105, yPos, { align: 'center' });
        yPos += 10;
        
        doc.setFontSize(18);
        doc.text(outletName, 105, yPos, { align: 'center' });
        yPos += 15;
        
        doc.setFontSize(12);
        doc.setFont(undefined, 'normal');
        if (startDate && endDate) {
            doc.text(`Period: ${startDate} to ${endDate}`, 105, yPos, { align: 'center' });
        } else {
            doc.text(`Generated: ${new Date().toLocaleDateString('id-ID')}`, 105, yPos, { align: 'center' });
        }
        yPos += 20;
        
        // For each visit
        data.visits.forEach((visit, index) => {
            // New page for each visit
            if (index > 0) {
                doc.addPage();
                yPos = 20;
            }
            
            // Visit Header
            doc.setFontSize(14);
            doc.setFont(undefined, 'bold');
            doc.text(`Visit #${visit.id} - ${new Date(visit.visit_date).toLocaleDateString('id-ID')}`, 14, yPos);
            yPos += 7;
            
            doc.setFontSize(10);
            doc.setFont(undefined, 'normal');
            doc.text(`Auditor: ${visit.auditor_name}`, 14, yPos);
            yPos += 10;
            
            // Financial Data Box (if available)
            if (visit.uang_omset_modal || visit.cash || visit.qris) {
                doc.setDrawColor(0);
                doc.setFillColor(240, 240, 240);
                doc.rect(14, yPos, 182, 40, 'FD');
                
                yPos += 7;
                doc.setFontSize(11);
                doc.setFont(undefined, 'bold');
                doc.text('Financial Data:', 17, yPos);
                yPos += 5;
                
                doc.setFontSize(9);
                doc.setFont(undefined, 'normal');
                
                if (visit.uang_omset_modal) {
                    doc.text(`Uang Omset + Modal: Rp ${parseFloat(visit.uang_omset_modal).toLocaleString('id-ID')}`, 17, yPos);
                    yPos += 5;
                }
                if (visit.uang_ditukar) {
                    doc.text(`Ditukar: Rp ${parseFloat(visit.uang_ditukar).toLocaleString('id-ID')}`, 17, yPos);
                    yPos += 5;
                }
                
                // Payment methods in columns
                let xCol1 = 17, xCol2 = 80, xCol3 = 140;
                let yPayment = yPos;
                
                if (visit.cash) {
                    doc.text(`Cash: Rp ${parseFloat(visit.cash).toLocaleString('id-ID')}`, xCol1, yPayment);
                }
                if (visit.qris) {
                    doc.text(`QRIS: Rp ${parseFloat(visit.qris).toLocaleString('id-ID')}`, xCol2, yPayment);
                }
                if (visit.debit_kredit) {
                    doc.text(`Debit/Kredit: Rp ${parseFloat(visit.debit_kredit).toLocaleString('id-ID')}`, xCol3, yPayment);
                }
                yPos = yPayment + 5;
                
                if (visit.total_pembayaran) {
                    doc.setFont(undefined, 'bold');
                    doc.text(`TOTAL: Rp ${parseFloat(visit.total_pembayaran).toLocaleString('id-ID')}`, 17, yPos);
                    doc.setFont(undefined, 'normal');
                    yPos += 5;
                }
                
                // Kategoric, Leadtime, Status
                if (visit.kategoric || visit.leadtime || visit.status_keuangan) {
                    if (visit.kategoric) {
                        doc.text(`Kategoric: ${visit.kategoric}`, xCol1, yPos);
                    }
                    if (visit.leadtime) {
                        doc.text(`Lead Time: ${visit.leadtime} menit`, xCol2, yPos);
                    }
                    if (visit.status_keuangan) {
                        doc.text(`Status: ${visit.status_keuangan.toUpperCase()}`, xCol3, yPos);
                    }
                }
                
                yPos += 12;
            }
            
            // Checklist Details
            doc.setFontSize(12);
            doc.setFont(undefined, 'bold');
            doc.text('Checklist Details:', 14, yPos);
            yPos += 7;
            
            // For each category
            visit.checklist_details.forEach(category => {
                // Check if need new page
                if (yPos > 250) {
                    doc.addPage();
                    yPos = 20;
                }
                
                // Category header
                doc.setFontSize(11);
                doc.setFont(undefined, 'bold');
                doc.text(category.category_name, 14, yPos);
                yPos += 6;
                
                // Items
                doc.setFontSize(9);
                doc.setFont(undefined, 'normal');
                
                category.items.forEach(item => {
                    // Check space
                    if (yPos > 270) {
                        doc.addPage();
                        yPos = 20;
                    }
                    
                    // Icon based on response
                    let icon = '';
                    let color = [0, 0, 0];
                    
                    if (item.response === 'OK') {
                        icon = '✓';
                        color = [0, 128, 0];
                    } else if (item.response === 'NOT OK') {
                        icon = '✗';
                        color = [255, 0, 0];
                    } else {
                        icon = '-';
                        color = [128, 128, 128];
                    }
                    
                    doc.setTextColor(...color);
                    doc.text(icon, 17, yPos);
                    doc.setTextColor(0, 0, 0);
                    
                    // Wrap long text
                    const splitText = doc.splitTextToSize(item.point, 160);
                    doc.text(splitText, 23, yPos);
                    yPos += splitText.length * 4;
                    
                    // Notes if any
                    if (item.notes) {
                        doc.setFontSize(8);
                        doc.setTextColor(100, 100, 100);
                        const splitNotes = doc.splitTextToSize(`Note: ${item.notes}`, 160);
                        doc.text(splitNotes, 23, yPos);
                        yPos += splitNotes.length * 3.5;
                        doc.setTextColor(0, 0, 0);
                        doc.setFontSize(9);
                    }
                    
                    yPos += 2;
                });
                
                yPos += 5;
            });
            
            // Photos section
            if (visit.photos && visit.photos.length > 0) {
                // New page for photos
                doc.addPage();
                yPos = 20;
                
                doc.setFontSize(12);
                doc.setFont(undefined, 'bold');
                doc.text('Findings Photos:', 14, yPos);
                yPos += 10;
                
                let xPos = 14;
                let photosInRow = 0;
                
                for (const photo of visit.photos) {
                    try {
                        // Check if need new page
                        if (yPos > 220) {
                            doc.addPage();
                            yPos = 20;
                            xPos = 14;
                            photosInRow = 0;
                        }
                        
                        // Add photo
                        doc.addImage(photo.photo_url, 'JPEG', xPos, yPos, 60, 60);
                        
                        // Photo caption
                        doc.setFontSize(8);
                        const caption = doc.splitTextToSize(photo.question, 60);
                        doc.text(caption, xPos, yPos + 63);
                        
                        photosInRow++;
                        xPos += 65;
                        
                        // Max 3 photos per row
                        if (photosInRow >= 3) {
                            yPos += 75;
                            xPos = 14;
                            photosInRow = 0;
                        }
                    } catch (err) {
                        console.error('Failed to add photo:', err);
                    }
                }
            }
        });
        
        // Save PDF
        const filename = `${outletName.replace(/\s+/g, '_')}_Report_${new Date().toISOString().split('T')[0]}.pdf`;
        doc.save(filename);
        
        Swal.close();
        
    } catch (error) {
        console.error('PDF generation error:', error);
        Swal.fire('Error', 'Failed to generate PDF: ' + error.message, 'error');
    }
}
```

---

## ✅ DEPLOYMENT CHECKLIST

### Database:
- [ ] Backup production database
- [ ] Run `schema_add_visit_financial_form.sql`
- [ ] Verify columns added: `DESCRIBE visits;`
- [ ] Test with sample data

### Backend:
- [ ] Create `api/export-outlet-report-pdf.php`
- [ ] Update `api/visit-detail.php` to include financial fields
- [ ] Test API endpoints
- [ ] Verify photo URLs correct

### Frontend:
- [ ] Add "Export PDF" dropdown per outlet
- [ ] Include `enhanced-pdf-generator.js`
- [ ] Test PDF generation with financial data
- [ ] Test PDF with checklist details

### Mobile App:
- [ ] Update `visit_model.dart`
- [ ] Create `visit_financial_form_screen.dart`
- [ ] Update `visit_category_list_screen.dart`
- [ ] Update `visit_service.dart`
- [ ] Test form input and save
- [ ] Test data appears in PDF
- [ ] Build and test APK

---

## 🎯 TESTING PLAN

1. **Database Test:**
   - Insert financial data manually
   - Verify data types correct
   - Test ENUM values

2. **API Test:**
   - Save visit with financial data
   - Retrieve visit detail (check financial fields)
   - Export outlet report (check all data included)

3. **Mobile App Test:**
   - Open financial form
   - Fill all fields
   - Verify total auto-calculates
   - Save and check database
   - Re-open form (should load saved data)

4. **PDF Test:**
   - Generate PDF per outlet
   - Verify financial data box shows
   - Verify checklist details show
   - Verify photos appear
   - Test with multiple visits
   - Test with/without financial data

---

## 📊 SUCCESS CRITERIA

- ✅ Financial form accessible from category screen
- ✅ All 9 fields save correctly
- ✅ Total auto-calculates (cash + qris + debit/kredit)
- ✅ Data persists across app restarts
- ✅ PDF shows financial data in box format
- ✅ PDF shows detailed checklist with icons
- ✅ PDF can be generated per outlet
- ✅ Photos appear in PDF
- ✅ Multi-visit PDF support

---

**Created:** November 4, 2025  
**Status:** 🚧 Implementation Guide Ready  
**Next Step:** Run database schema changes

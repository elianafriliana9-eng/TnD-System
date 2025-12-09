# Struktur PDF Report Divisi Training

## Overview
Dokumen ini menjelaskan struktur lengkap PDF report untuk divisi training di sistem TnD Mobile. PDF report ini di-generate setelah training session diselesaikan dan berisi informasi lengkap tentang hasil evaluasi training.

---

## Informasi Dasar

### File Service
- **Lokasi**: `lib/services/training/training_pdf_service.dart`
- **Method**: `generateTrainingReportPDF()`
- **Format**: A4 Portrait
- **Total Halaman**: 4 halaman (minimum), bisa lebih jika ada banyak kategori NOK

### Nama File Output
```
training_report_{session_id}_{timestamp}.pdf
```
Contoh: `training_report_123_1700123456789.pdf`

---

## Struktur Halaman per Halaman

### 📄 **HALAMAN 1: Header & Summary**

#### 1.1 Header Dokumen
- **Judul**: "LAPORAN TRAINING DIVISI"
- **Subtitle**: "TnD System - Training Report"
- **Print Date**: Tanggal dan waktu generate PDF (format: dd/MM/yyyy HH:mm)
- **Style**: 
  - Background: Biru muda (PdfColors.blue50)
  - Border: Biru gelap (PdfColors.blue900), tebal 2px
  - Font judul: 24pt, bold, biru gelap

#### 1.2 Training Session Info
**Section Header**: "TRAINING SESSION INFO"

Tabel informasi dengan kolom:
| Field | Value |
|-------|-------|
| Outlet | Nama outlet |
| Date | Tanggal training (dd/MM/yyyy) |
| Time | Waktu mulai training (HH:mm) |
| Trainer | Nama trainer |
| Crew Leader | Nama crew leader |
| Status | Status session (completed/ongoing/cancelled) |

**Style**: 
- Tabel dengan border abu-abu
- Background row: Abu-abu muda
- Font: 9pt

#### 1.3 Training Results Summary
**Section Header**: "TRAINING RESULTS SUMMARY"

**Statistik Box** (3 box horizontal):
- **OK Box**: 
  - Label: "OK"
  - Count: Jumlah response dengan status "check"
  - Color: Hijau (PdfColors.green)
  - Background: Hijau muda (PdfColors.green50)
  
- **NOK Box**:
  - Label: "NOK"
  - Count: Jumlah response dengan status "cross"
  - Color: Merah (PdfColors.red)
  - Background: Merah muda (PdfColors.red50)
  
- **N/A Box**:
  - Label: "N/A"
  - Count: Jumlah response dengan status "na"
  - Color: Oranye (PdfColors.orange)
  - Background: Oranye muda (PdfColors.orange100)

**Summary Text**:
- Total Items: Total semua response
- OK Rate: Persentase OK dari total (format: XX%)

#### 1.4 Comments
**Section Header**: "COMMENTS"

**Trainer Comment**:
- Label: "Trainer Comment:" (bold, biru gelap, 9pt)
- Content: Komentar dari trainer (8pt)
- Jika kosong: Menampilkan "-"

**Crew Leader Comment**:
- Label: "Crew Leader Comment:" (bold, biru gelap, 9pt)
- Content: Komentar dari crew leader (8pt)
- Jika kosong: Menampilkan "-"

**Style**: 
- Container dengan border abu-abu
- Background: Abu-abu muda
- Padding: 10px

#### 1.5 Footer Halaman
- Divider abu-abu
- Text: "Page 1 of 4" (9pt, center, abu-abu)

---

### 📄 **HALAMAN 2: Checklist Results**

#### 2.1 Header Section
- **Title**: "CHECKLIST RESULTS"
- **Subtitle**: Nama outlet
- **Style**: 
  - Background: Biru muda
  - Border: Biru gelap, tebal 1.5px
  - Font: 18pt bold, biru gelap

#### 2.2 OK Items by Category
**Section Header**: "OK ITEMS BY CATEGORY"

**Category Card** (untuk setiap kategori):
- **Header Card**:
  - Nama kategori (10pt, bold, biru gelap)
  - Statistik badges (OK, NOK, N/A) dengan count per kategori
  
- **OK Items List** (hanya menampilkan item dengan response "check"):
  - Setiap item dalam box hijau muda
  - Icon: ✓ (checkmark hijau, bold)
  - Text: Nama point/item (8pt)
  - Background: Hijau muda (PdfColors.green50)
  - Border: Hijau (PdfColors.green)

**Catatan**: 
- Hanya item dengan status OK yang ditampilkan di halaman ini
- Item NOK akan ditampilkan di halaman terpisah
- Item N/A tidak ditampilkan di halaman ini

#### 2.3 Footer Halaman
- Divider abu-abu
- Text: "Page 2 of 4" (9pt, center, abu-abu)

**Note**: Halaman ini menggunakan `MultiPage` widget, sehingga bisa otomatis menambah halaman jika konten terlalu panjang.

---

### 📄 **HALAMAN 3: NOK Items Detail** (Conditional - hanya jika ada NOK items)

#### 3.1 Section Header
**Section Header**: "NOK ITEMS - {Nama Kategori}"

**Note**: Jika ada beberapa kategori dengan item NOK, akan dibuat halaman terpisah untuk setiap kategori.

#### 3.2 NOK Items List
Untuk setiap item dengan status "cross":

**Item Card**:
- **Style**: 
  - Border: Merah, tebal 1.5px
  - Background: Merah muda (PdfColors.red50)
  - Padding: 10px
  - Margin bottom: 8px

- **Content**:
  - Icon: "X " (merah, bold, 14pt)
  - Text: Nama point/item (9pt)
  - Layout: Row dengan icon di kiri, text di kanan (expanded)

#### 3.3 Footer Halaman
- Divider abu-abu
- Text: "Page 3 of 4 - NOK Details" (9pt, center, abu-abu)

**Note**: 
- Halaman ini hanya dibuat jika ada item dengan status NOK
- Jika tidak ada NOK items, halaman ini di-skip
- Setiap kategori dengan NOK items mendapat halaman terpisah

---

### 📄 **HALAMAN 4: Photos & Signatures**

#### 4.1 Documentation Photos
**Section Header**: "DOCUMENTATION PHOTOS"

**Photo Grid**:
- **Layout**: Wrap dengan spacing 8px
- **Photo Size**: 130x130px per foto
- **Max Display**: 4 foto pertama
- **Style**: 
  - Border: Abu-abu (PdfColors.grey300)
  - Fit: BoxFit.cover (fitted box)

**Jika ada lebih dari 4 foto**:
- Text: "... and {count} more photos" (8pt, italic, abu-abu)

**Jika tidak ada foto**:
- Text: "No photos" (9pt, abu-abu)

#### 4.2 Digital Signatures
**Section Header**: "DIGITAL SIGNATURES"

**Layout**: Row dengan 2 kolom (Trainer dan Leader)

**Trainer Signature**:
- **Signature Box**: 
  - Size: 90x45px
  - Border: Abu-abu (PdfColors.grey400)
  - Image: Trainer signature (Uint8List converted to MemoryImage)
  
- **Label**: "Trainer Sign" (8pt, bold)
- **Name**: Nama trainer (7pt)
- **Date**: Tanggal saat ini (dd/MM/yyyy, 7pt, abu-abu)

**Crew Leader Signature**:
- **Signature Box**: 
  - Size: 90x45px
  - Border: Abu-abu (PdfColors.grey400)
  - Image: Leader signature (Uint8List converted to MemoryImage)
  
- **Label**: "Leader Sign" (8pt, bold)
- **Name**: Nama crew leader (7pt)
- **Date**: Tanggal saat ini (dd/MM/yyyy, 7pt, abu-abu)

**Layout**: 
- MainAxisAlignment: spaceBetween
- CrossAxisAlignment: center
- Setiap signature dalam Column

#### 4.3 Footer Halaman
- Divider abu-abu
- Text: "Page 4 of 4 - Final Report" (9pt, center, abu-abu)

---

## Data Input yang Diperlukan

### Parameter Method `generateTrainingReportPDF()`

```dart
{
  required TrainingSessionModel session,        // Data session training
  required List<Map<String, dynamic>> categories, // Kategori dan points
  required Map<int, String> responses,         // Response per point_id
  required String trainerComment,               // Komentar trainer
  required String leaderComment,                // Komentar crew leader
  required List<File> sessionPhotos,           // Foto dokumentasi
  required Uint8List trainerSignature,         // Signature trainer (image bytes)
  required Uint8List leaderSignature,          // Signature leader (image bytes)
  required String crewLeader,                   // Nama crew leader
  required String crewLeaderPosition,          // Posisi crew leader
}
```

### Struktur Data Categories
```dart
List<Map<String, dynamic>> categories = [
  {
    'category_name': 'Nama Kategori',
    'points': [
      {
        'id': 1,                    // point_id
        'point_text': 'Nama Point', // atau 'point_name'
        // ... field lainnya
      },
      // ... points lainnya
    ]
  },
  // ... categories lainnya
]
```

### Struktur Data Responses
```dart
Map<int, String> responses = {
  1: 'check',  // OK
  2: 'cross',  // NOK
  3: 'na',     // N/A
  // ... point_id: response_type
}
```

**Response Types**:
- `'check'`: Item OK (✓)
- `'cross'`: Item NOK (X)
- `'na'`: Item Not Applicable (N/A)

---

## Helper Methods & Utilities

### 1. `_buildSectionHeader(String title)`
- Membuat header section dengan border bawah biru gelap
- Font: 12pt, bold, biru gelap

### 2. `_buildInfoTable(List<List<String>> rows)`
- Membuat tabel informasi 2 kolom
- Border: Abu-abu, 0.5px
- Background row: Abu-abu muda

### 3. `_buildStatBox(String label, int count)`
- Membuat box statistik dengan warna sesuai label
- Size: Horizontal padding 12px, vertical 8px
- Border radius: 4px

### 4. `_buildCategoryCard(...)`
- Membuat card untuk setiap kategori
- Menampilkan statistik per kategori
- List item OK dalam box hijau

### 5. `_buildStatBadgeSmall(String label, int count)`
- Badge kecil untuk statistik (OK/NOK/N/A)
- Format: "Label:Count"
- Size: Padding 4px horizontal, 2px vertical

### 6. `_groupNOKItems(...)`
- Mengelompokkan item NOK berdasarkan kategori
- Return: `Map<String, List<Map<String, dynamic>>>`
- Key: Nama kategori
- Value: List item dengan status "cross"

### 7. Counting Methods
- `_countOKResponses()`: Hitung response "check"
- `_countNOKResponses()`: Hitung response "cross"
- `_countNAResponses()`: Hitung response "na"
- `_calculatePercentage()`: Hitung persentase OK

### 8. Formatting Methods
- `_formatDate(String date)`: Format tanggal ke dd/MM/yyyy
- `_formatTime(String dateTime)`: Format waktu ke HH:mm

---

## Color Scheme

### Primary Colors
- **Blue 900**: `PdfColors.blue900` - Header, borders, titles
- **Blue 50**: `PdfColors.blue50` - Header background, section backgrounds
- **Grey 100**: `PdfColors.grey100` - Table backgrounds, container backgrounds
- **Grey 300**: `PdfColors.grey300` - Borders, dividers
- **Grey 400**: `PdfColors.grey400` - Signature borders
- **Grey 600/700**: `PdfColors.grey600/700` - Secondary text

### Status Colors
- **Green**: `PdfColors.green` - OK items
- **Green 50**: `PdfColors.green50` - OK background
- **Red**: `PdfColors.red` - NOK items
- **Red 50**: `PdfColors.red50` - NOK background
- **Orange**: `PdfColors.orange` - N/A items
- **Orange 100**: `PdfColors.orange100` - N/A background

---

## Layout & Spacing

### Margins
- **Page Margin**: 40px semua sisi

### Spacing
- **Section Spacing**: 20px
- **Sub-section Spacing**: 8-12px
- **Item Spacing**: 3-10px
- **Photo Spacing**: 8px (spacing & runSpacing)

### Font Sizes
- **Title**: 24pt (header), 18pt (section header)
- **Section Header**: 12pt
- **Body Text**: 8-11pt
- **Small Text**: 7-9pt
- **Stat Numbers**: 14pt (stat box), 28pt (stat card)

---

## Flow & Logic

### 1. Page Generation Flow
```
1. Generate Page 1 (Header & Summary)
   ↓
2. Check if categories exist
   ↓
3. Generate Page 2 (Checklist Results - MultiPage)
   ↓
4. Group NOK items by category
   ↓
5. For each category with NOK items:
   - Generate separate page (Page 3+)
   ↓
6. Generate Page 4 (Photos & Signatures)
   ↓
7. Save PDF to device storage
```

### 2. Response Processing
- Responses di-map berdasarkan `point_id`
- Setiap point di-categorize berdasarkan response type
- OK items ditampilkan di Page 2
- NOK items ditampilkan di Page 3+ (per kategori)
- N/A items dihitung tapi tidak ditampilkan detail

### 3. Category Processing
- Categories di-iterate untuk membuat category cards
- Setiap category memiliki list points
- Points di-filter berdasarkan response type
- Statistik dihitung per kategori

---

## Error Handling & Edge Cases

### 1. Empty Data
- **No Categories**: Page 2 tidak dibuat
- **No NOK Items**: Page 3 tidak dibuat
- **No Photos**: Menampilkan "No photos"
- **Empty Comments**: Menampilkan "-"

### 2. Data Format
- **Date Parsing**: Try-catch dengan fallback ke string asli
- **Time Parsing**: Try-catch dengan fallback ke "-"
- **Image Loading**: Signature images di-convert dari Uint8List

### 3. Photo Handling
- **Max Display**: Hanya 4 foto pertama yang ditampilkan
- **Overflow**: Menampilkan count foto tersisa
- **File Reading**: `photo.readAsBytesSync()` untuk convert ke image

---

## Integration Points

### 1. Training Session Checklist Screen
- **File**: `training_session_checklist_screen.dart`
- **Method**: `_submitSession()`
- **Flow**: 
  1. Save responses
  2. Upload photos
  3. Save signatures
  4. Complete session
  5. Generate PDF
  6. Show PDF options dialog

### 2. Training Detail Screen
- **File**: `training_detail_screen.dart`
- **Method**: `_handlePdfAction()`
- **Flow**:
  1. Check if session completed
  2. Get PDF data from API
  3. Generate PDF on-demand
  4. Show PDF options dialog

### 3. Training Service
- **File**: `training_service.dart`
- **Method**: `getSessionPdfData()`
- **Endpoint**: `/training/pdf-data.php?session_id={id}`
- **Purpose**: Get complete data untuk PDF generation

---

## Future Enhancements

### Potential Improvements
1. **Multi-language Support**: Support bahasa Indonesia/English
2. **Custom Branding**: Logo perusahaan di header
3. **Charts/Graphs**: Visualisasi statistik dengan charts
4. **Export Options**: Excel, CSV selain PDF
5. **Email Integration**: Kirim PDF langsung via email
6. **Cloud Storage**: Auto-upload ke cloud storage
7. **Template Customization**: User bisa customize template
8. **Batch Generation**: Generate PDF untuk multiple sessions
9. **Watermark**: Watermark untuk security
10. **Compression**: Optimize PDF size untuk sharing

---

## Testing Checklist

### Functional Testing
- [ ] Generate PDF dengan semua data lengkap
- [ ] Generate PDF dengan data minimal (no photos, no NOK)
- [ ] Generate PDF dengan banyak kategori dan points
- [ ] Generate PDF dengan banyak foto (>4)
- [ ] Generate PDF tanpa foto
- [ ] Generate PDF tanpa NOK items
- [ ] Generate PDF dengan semua response OK
- [ ] Generate PDF dengan semua response NOK
- [ ] Generate PDF dengan empty comments
- [ ] Generate PDF dengan long text comments

### Visual Testing
- [ ] Layout tidak terpotong di berbagai ukuran
- [ ] Font readable dan consistent
- [ ] Colors sesuai dengan design system
- [ ] Spacing dan alignment rapi
- [ ] Photos tidak terdistorsi
- [ ] Signatures jelas dan readable
- [ ] Page numbering correct

### Performance Testing
- [ ] PDF generation time < 5 detik
- [ ] File size reasonable (< 5MB untuk normal case)
- [ ] Memory usage tidak excessive
- [ ] No memory leaks saat generate multiple PDFs

### Integration Testing
- [ ] PDF generation dari checklist screen
- [ ] PDF generation dari detail screen
- [ ] PDF sharing ke WhatsApp
- [ ] PDF sharing ke Email
- [ ] PDF open dengan PDF viewer
- [ ] PDF save ke device storage

---

## Notes & Best Practices

1. **Data Validation**: Pastikan semua required data tersedia sebelum generate
2. **Error Handling**: Handle semua edge cases dengan graceful fallback
3. **Performance**: Gunakan MultiPage untuk konten panjang
4. **Memory Management**: Release resources setelah PDF generated
5. **File Naming**: Gunakan timestamp untuk avoid conflicts
6. **User Feedback**: Show loading indicator saat generate PDF
7. **Error Messages**: Provide clear error messages jika gagal
8. **Testing**: Test dengan berbagai skenario data

---

## Revision History

- **v1.0** (Current): Initial implementation dengan 4 halaman structure
- Support untuk OK/NOK/N/A responses
- Photo documentation
- Digital signatures
- Comments section

---

**Last Updated**: 21 November 2025
**Maintained By**: TnD Development Team



# Perbandingan Struktur PDF Training vs QC (Visit)

## 📊 Ringkasan Perbandingan

| Aspek | Training | QC/Visit | Catatan |
|-------|----------|---------|---------|
| **File Service** | `training_pdf_service.dart` (731 lines) | Inline di `visit_report_detail_screen.dart` (2180 lines) | Training punya service khusus, QC inline di screen |
| **Total Halaman** | 4 halaman | 5+ halaman | QC lebih panjang karena data financial |
| **Page 1** | Header + Summary | Header + Visit Info + Financial | QC punya data keuangan |
| **Page 2** | Checklist Hasil (OK Items) | Rekomendasi + OK Items | QC gabung rekomendasi di sini |
| **Page 3** | Temuan (NOK Items) per Kategori | Temuan Lengkap per Kategori | Sama |
| **Page 4** | Foto + Tanda Tangan | Foto + Tanda Tangan | Sama |
| **Page 5+** | - | Temuan per Kategori (detail) | QC lebih detail |

---

## 🏗️ STRUKTUR PDF TRAINING (4 Halaman)

### **Halaman 1: Header & Ringkasan Training**
```
┌─────────────────────────────────────┐
│ LAPORAN TRAINING (Header Blue)      │
│ TnD System - Training Report        │
│ Tanggal Cetak: DD/MM/YYYY HH:MM     │
└─────────────────────────────────────┘

INFORMASI TRAINING
├─ Outlet: [name]
├─ Tanggal Training: DD/MM/YYYY
├─ Waktu: HH:MM
├─ Trainer: [name]
├─ Crew Leader: [name]
└─ Status: [status]

RINGKASAN HASIL TRAINING
├─ Total Items: [count]
├─ Tingkat OK: [percentage]%
├─ OK Count: [number]
├─ NOK Count: [number]
└─ N/A Count: [number]

KOMENTAR
├─ Komentar Trainer: [text]
└─ Komentar Crew Leader: [text]
```

### **Halaman 2: Hasil Checklist (OK Items Only)**
```
HASIL CHECKLIST - ITEM OK

Untuk Setiap Category:
┌─────────────────────────┐
│ CATEGORY NAME           │
│ [List of OK items]      │
│ ✓ Item 1                │
│ ✓ Item 2                │
│ ✓ Item 3                │
└─────────────────────────┘

Footer: "Halaman 2 - Item OK"
```

### **Halaman 3: Temuan (NOK Items per Kategori)**
```
TEMUAN - CATEGORY NAME

Untuk Setiap NOK Item:
┌─────────────────────────┐
│ X Item yang bermasalah  │
│ X Item lainnya          │
└─────────────────────────┘ (Red border, red highlight)

Jika ada multiple kategori dengan NOK:
- Satu halaman per kategori
- Title: "TEMUAN - [CATEGORY NAME]"

Footer: "Halaman 3 - Temuan [category]"
```

### **Halaman 4: Foto & Tanda Tangan**
```
FOTO DOKUMENTASI
├─ Grid foto max 4 per halaman (130x130 px)
├─ Jika > 4 foto: "... dan X foto lainnya"
└─ Jika tidak ada: "Tidak ada foto"

TANDA TANGAN DIGITAL
├─ Left: Tanda Tangan Trainer
│  ├─ Box: 90x45 px
│  ├─ Text: "Tanda Tangan Trainer"
│  ├─ Name: [trainer name]
│  └─ Date: DD/MM/YYYY
│
└─ Right: Tanda Tangan Crew Leader
   ├─ Box: 90x45 px
   ├─ Text: "Tanda Tangan Crew Leader"
   ├─ Name: [crew leader name]
   └─ Date: DD/MM/YYYY
```

---

## 🏗️ STRUKTUR PDF QC/VISIT (5+ Halaman)

### **Halaman 1: Header + Visit Info + Financial + Assessment**
```
┌─────────────────────────────────────┐
│ LAPORAN AUDIT (Header Blue)         │
│ TnD System - Audit Report           │
│ Tanggal Cetak: DD/MM/YYYY HH:MM     │
└─────────────────────────────────────┘

INFORMASI VISIT
├─ Outlet: [name]
├─ Lokasi: [location]
├─ Auditor: [name]
├─ Tanggal Visit: DD/MM/YYYY
└─ Status: [status]

DATA KEUANGAN (If Present)
├─ Modal: Rp X
├─ Uang Ditukar: Rp X
├─ Cash: Rp X
├─ QRIS: Rp X
├─ Debit/Kredit: Rp X
└─ TOTAL: Rp X (Blue highlight)

DATA ASSESSMENT (If Present)
├─ Crew in Charge: [name]
├─ Kategoric: [value]
└─ Leadtime: [value]
```

### **Halaman 2: Rekomendasi + OK Items**
```
REKOMENDASI PERBAIKAN (Ringkas)
├─ Hanya key findings (max 5)
└─ Format: "• Finding 1\n• Finding 2"

REKOMENDASI PERBAIKAN (LENGKAP) (If Many)
└─ Semua rekomendasi detail

HASIL CHECKLIST - ITEM OK
├─ Untuk Setiap Category:
│  ├─ Category Header
│  └─ List item OK
└─ Format: Grid per category
```

### **Halaman 3: Item OK (Detailed)**
```
HASIL CHECKLIST - ITEM OK (Detail per kategori)

Untuk Setiap Category:
┌─────────────────────────┐
│ CATEGORY NAME           │
│ Total OK: X / Y         │
│ Percentage: X%          │
│                         │
│ List Items:             │
│ ✓ Item 1                │
│ ✓ Item 2                │
│ ✓ Item 3                │
└─────────────────────────┘
```

### **Halaman 4+: Temuan per Kategori (Multi-page)**
```
Daftar Temuan - CATEGORY NAME

Untuk Setiap Category dengan NOK:
┌─────────────────────────┐
│ NOK ITEMS:              │
│ ✗ Item 1                │
│ ✗ Item 2                │
│ ✗ Item 3                │
│                         │
│ RECOMMENDATION:         │
│ - Action 1              │
│ - Action 2              │
└─────────────────────────┘

Notes:
- Satu halaman per kategori
- Jika banyak kategori NOK: halaman bertambah
```

### **Halaman Terakhir: Foto & Tanda Tangan**
```
FOTO DOKUMENTASI
├─ Grid foto max 4 per halaman (130x130 px)
├─ Jika > 4 foto: "... dan X foto lainnya"
└─ Jika tidak ada: "Tidak ada foto"

TANDA TANGAN DIGITAL
├─ Left: Tanda Tangan Auditor/Visitor
├─ Middle: (optional)
└─ Right: Tanda Tangan Crew Leader / Pemilik

(Layout sama dengan Training)
```

---

## 🔄 PERBANDINGAN DETAIL: Aspek Kunci

### **1. Data di Halaman 1**

**Training:**
- ✅ Outlet, Tanggal, Waktu, Trainer, Crew Leader, Status
- ❌ TIDAK ada: Financial data, Location, Assessment data

**QC:**
- ✅ Outlet, Lokasi, Auditor, Tanggal, Status
- ✅ Financial: Modal, Cash, QRIS, Debit/Kredit, Total
- ✅ Assessment: Crew in Charge, Kategoric, Leadtime
- ✅ More complete business info

### **2. Checklist Presentation**

**Training:**
- Halaman 2: HANYA OK Items (ditampilkan semua di satu halaman)
- Halaman 3: NOK Items (1 halaman per kategori jika ada)
- Simple, fokus pada hasil

**QC:**
- Halaman 2: Ringkas (key findings + OK items summary)
- Halaman 3: Detail OK items per kategori
- Halaman 4+: Temuan per kategori detail dengan rekomendasi
- More detailed, comprehensive

### **3. Section Organization**

**Training PDF Service Method:**
```dart
generateTrainingReportPDF({
  categories,          // List<Map> dengan points
  responses,          // Map<int, String> {point_id: 'ok'/'nok'/'na'}
  trainerComment,
  leaderComment,
  sessionPhotos,
  trainerSignature,
  leaderSignature,
})
```

**QC/Visit (Inline):**
```
Uses model properties directly:
- widget.visit (contains all data)
- _groupedResponses (category => items)
- _recommendations (NOK findings)
```

### **4. Color Scheme**

**Training:**
- Blue 900/50: Headers, section titles
- Green: OK percentage
- Red: NOK items
- Grey: Comments, secondary text

**QC:**
- Blue 900/50: Headers, section titles (sama)
- Green: OK items (sama)
- Red: NOK/NOK finding boxes (sama)
- Blue highlight: Financial Total
- Grey: Recommendations, secondary text

### **5. Helper Methods Comparison**

**Training PDF Service:**
- `_buildSectionHeader(title)` - Format judul section
- `_buildInfoTable(rows)` - Format info table
- `_buildStatBox(label, value)` - Format stat box
- `_buildCategoryCard(name, points, responses)` - Format category
- `_groupNOKItems(categories, responses)` - Group NOK items
- `_countOKResponses(responses)` - Count OK
- `_countNOKResponses(responses)` - Count NOK
- `_countNAResponses(responses)` - Count NA
- `_calculatePercentage(responses)` - Calculate OK%
- `_formatDate(date)` - Format tanggal
- `_formatTime(time)` - Format waktu

**QC/Visit (Inline Methods):**
- `_buildPDFSectionHeader(title)` - Format judul section
- `_buildPDFInfoTable(rows)` - Format info table
- `_buildPDFRecommendationItem(finding)` - Format recommendation
- `_buildPDFChecklistCategoryOKOnly(category, items)` - Format category OK
- `_buildPDFChecklistCategoryWithNOK(category, items)` - Format category with NOK
- `_formatDate(date)` - Format tanggal
- `_formatStatus(status)` - Format status
- `_formatCurrency(amount)` - Format mata uang (KHUSUS QC!)

---

## 📝 KESIMPULAN: Struktur Sama / Beda?

### **✅ SAMA:**
1. ✓ Base layout (Header + Sections + Footer)
2. ✓ Color scheme & styling
3. ✓ Photo section
4. ✓ Signature section
5. ✓ Overall design language
6. ✓ Page structure (multiple pages)

### **❌ BERBEDA:**
1. ✗ **Halaman 1**: Training simple, QC kompleks (financial + assessment)
2. ✗ **Halaman distribution**: Training 4 page fixed, QC 5+ page variable
3. ✗ **Content detail**: Training ringkas, QC comprehensive
4. ✗ **Helper methods**: Training lebih banyak helpers, QC inline
5. ✗ **Financial section**: HANYA ada di QC

### **💡 REKOMENDASI:**

**Struktur PDF Training saat ini SUDAH BAIK, tetapi bisa diperbaiki:**

1. **Tambahkan Section Optional di Halaman 1:**
   - Financial data (jika ada)
   - Assessment data (jika ada)
   
2. **Consolidate Helper Methods:**
   - Move QC PDF generation dari inline ke service (seperti Training)
   - Create shared `PdfService` base class
   
3. **Standardisasi Format:**
   - Gunakan same helper methods untuk consistency
   - Centralize all PDF utilities

**Implementasi Priority:**
- 🔴 HIGH: Consolidate QC PDF dari inline ke service (maintainability)
- 🟡 MEDIUM: Tambah optional sections Training halaman 1
- 🟢 LOW: Refactor ke shared base class


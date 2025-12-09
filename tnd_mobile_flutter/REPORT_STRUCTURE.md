# Struktur Laporan di TND Mobile

## 1. Overview Sistem Laporan

TND Mobile memiliki sistem laporan yang terintegrasi untuk mendukung manajemen kualitas dan pelatihan. Sistem ini mencakup berbagai jenis laporan yang dapat diakses melalui dashboard dan dapat diekspor dalam format PDF.

## 2. Komponen Utama Sistem Laporan

### 2.1 Report Dashboard
- **ReportDashboardScreen**: Layar utama untuk semua laporan
- **Tab Berbasis**: Dua tab utama (Overview dan By Outlet)
- **Filter Tanggal**: Rentang tanggal dapat disesuaikan
- **Penyegaran Data**: Fungsi refresh untuk mendapatkan data terbaru

### 2.2 Report Overview Tab
- **Statistik Utama**:
  - Total Outlets
  - Total Visits
  - OK Items
  - NOK Items
  - N/A Count
  - OK Percentage

- **Grafik Visual**:
  - Pie Chart: Distribusi status (OK/NOK)
  - Color-coded indicators: Status berdasarkan persentase

- **Recent Visits**: Daftar kunjungan terbaru dengan informasi ringkas

### 2.3 Report Outlet Tab
- **Daftar Outlet**: Menampilkan semua outlet yang dikunjungi
- **Statistik Per Outlet**:
  - Nama outlet
  - Jumlah item OK
  - Jumlah item NOK
  - Persentase performansi
- **Detail Status**: Informasi spesifik untuk masing-masing outlet

## 3. Model Data Laporan

### 3.1 ReportOverview Model
- **totalOutlets**: Jumlah total outlet
- **totalVisits**: Jumlah total kunjungan
- **okCount**: Jumlah item dengan status OK
- **nokCount**: Jumlah item dengan status NOK
- **naCount**: Jumlah item dengan status N/A
- **okPercentage**: Persentase item OK
- **nokPercentage**: Persentase item NOK
- **recentVisits**: Daftar kunjungan terbaru

### 3.2 OutletReport Model
- **outletName**: Nama outlet
- **okCount**: Jumlah item OK
- **nokCount**: Jumlah item NOK
- **naCount**: Jumlah item N/A
- **okPercentage**: Persentase OK per outlet

### 3.3 RecentVisit Model
- **outletName**: Nama outlet
- **visitDate**: Tanggal kunjungan
- **status**: Status kunjungan
- **statusColor**: Warna status (hex)
- **okItems**: Jumlah item OK
- **nokItems**: Jumlah item NOK
- **okPercentage**: Persentase OK

## 4. Fungsi Laporan PDF

### 4.1 Fungsi Ekspor PDF di Visit Report
- **Lokasi File**: `visit_report_detail_screen.dart`
- **Nama File**: Format: `Laporan_Visit_[Nama_Outlet]_[Tanggal_Waktu].pdf`
- **Komponen Laporan**:
  - Header dengan informasi perusahaan
  - Informasi visit (tanggal, outlet, petugas, dll)
  - Data keuangan
  - Data assessment
  - Rekomendasi perbaikan
  - Checklist OK
  - Temuan berdasarkan kategori
  - Tanda tangan digital

### 4.2 Struktur PDF Laporan Visit
- **Halaman 1**: Informasi utama visit dan ringkasan
- **Halaman 2**: Rekomendasi perbaikan detail
- **Halaman 3**: Item checklist OK saja
- **Halaman 4+**: Temuan berdasarkan kategori (jika ada NOK items)
- **Halaman Akhir**: Tanda tangan dan informasi validasi

### 4.3 Komponen PDF Utils
- **PDFLetterhead**: Kelas untuk membuat header dokumen profesional
- **buildHeader()**: Fungsi untuk membuat header dokumen
- **buildDocumentInfo()**: Fungsi untuk informasi dokumen
- **buildSectionTitle()**: Fungsi untuk judul seksi

## 5. Service Laporan

### 5.1 ReportService
- **getOverview()**: Mendapatkan ringkasan laporan
- **getOutletReports()**: Mendapatkan laporan per outlet
- **Metode HTTP**: GET request ke backend
- **Parameter**: userId, startDate, endDate

## 6. Fitur Laporan Spesifik

### 6.1 Kustomisasi Tanggal
- **Rentang Tanggal**: Pemilihan rentang tanggal kustom
- **Filter Data**: Laporan difilter berdasarkan tanggal
- **Default**: 30 hari terakhir

### 6.2 Indikator Kinerja
- **KPI Utama**: OK%, NOK%, Total items
- **Color Coding**: 
  - Hijau: >85% OK
  - Oranye: 70-85% OK
  - Merah: <70% OK

### 6.3 Penyegaran Data
- **Pull to Refresh**: Swipe to refresh untuk data terbaru
- **Manual Refresh**: Tombol refresh manual
- **Loading Indicator**: Indikator saat memuat data

## 7. Integrasi Laporan dengan Fitur Lain

### 7.1 Visit Management
- **Laporan Visit**: Terkoneksi dengan hasil visitasi
- **Checklist Items**: Data dari aktivitas checklist
- **Financial Assessment**: Data keuangan ikut dilaporkan
- **Digital Signatures**: Tanda tangan menjadi bagian dari laporan PDF

### 7.2 Training System
- **Laporan Pelatihan**: Terpisah dari laporan visitasi
- **Training Reports**: Fungsi PDF generation untuk pelatihan

## 8. Format Tampilan Laporan

### 8.1 UI/UX Dashboard
- **Kartu Statistik**: Tampilan card-based untuk metrik utama
- **Grafik Interaktif**: Pie chart untuk distribusi status
- **Daftar Scrollable**: Recent visits dalam format daftar

### 8.2 Responsifitas
- **Adaptif Layout**: Tampilan yang sesuai berbagai ukuran layar
- **Mobile Optimized**: Desain yang dioptimalkan untuk mobile
- **Material Design**: Implementasi Material Design 3

## 9. Pengembangan Laporan Masa Depan

### 9.1 Fitur yang Dapat Ditambahkan
- **Laporan Khusus QC**: Dashboard terpisah untuk Quality Control
- **Filter Lanjutan**: Filter berdasarkan wilayah, jenis outlet, dsb
- **Export Multiple Format**: Selain PDF, format lain (Excel, CSV)
- **Laporan Tren**: Analisis perkembangan dari waktu ke waktu
- **Laporan Komparatif**: Perbandingan antar outlet atau periode

### 9.2 Potensi Integrasi
- **Email Integration**: Kirim laporan via email langsung dari app
- **Cloud Storage**: Simpan laporan di cloud storage
- **Dashboard Admin**: Visualisasi lanjutan di web admin
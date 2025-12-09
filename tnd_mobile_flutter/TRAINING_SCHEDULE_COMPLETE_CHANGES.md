# Perubahan pada Sistem Jadwal Training TnD Mobile - Versi Lengkap

## Tujuan
Memperbaiki sistem jadwal training sesuai dengan spesifikasi:
- Jadwal training yang diinput dari form jadwal training harus disimpan dengan status "scheduled", bahkan jika tanggalnya hari ini
- Status berubah menjadi "ongoing" hanya ketika trainer memulai sesi dari daily training screen
- Screen jadwal training hanya untuk monitoring dan membuat jadwal (tanpa action start training)
- Screen daily training adalah satu-satunya tempat untuk memulai sesi
- Menampilkan informasi kategori training dengan benar di detail screen
- Menyimpan informasi crew leader bersamaan dengan signatures di backend

## File yang Dimodifikasi

### 1. lib/screens/training/training_daily_screen.dart
- Memperbarui fungsi `_loadTodaySchedules()` untuk hanya menampilkan jadwal dengan status "scheduled" yang jatuh pada hari ini
- Filter ditambahkan: `schedule.scheduledDate.year == today.year && schedule.scheduledDate.month == today.month && schedule.scheduledDate.day == today.day && schedule.status == 'scheduled'`

### 2. lib/screens/training/training_schedule_form_screen.dart
- Memastikan bahwa parameter `status: 'scheduled'` selalu dikirim saat membuat jadwal, bahkan jika tanggalnya hari ini
- Menambahkan komentar untuk menandai bahwa status HARUS SELALU 'scheduled'

### 3. lib/screens/training/training_detail_screen.dart
- Menghapus tombol "Mulai Training" (FloatingActionButton) yang memungkinkan trainer memulai sesi dari detail screen
- Menjaga prinsip bahwa hanya Daily Training screen yang boleh memiliki fungsi untuk memulai sesi
- Memperbarui fungsi `_fetchCategories()` untuk lebih akurat dalam mengambil dan menampilkan data kategori dari berbagai sumber data yang mungkin
- Menambahkan logika backup untuk mengambil informasi kategori dari API jika tidak tersedia di model schedule

### 4. lib/screens/training/training_session_checklist_screen.dart
- Memperbarui cara mengambil dan menyimpan tanda tangan serta informasi crew leader
- Menyesuaikan pemanggilan DigitalSignatureScreen untuk mengambil informasi crew leader

### 5. lib/services/training/training_service.dart
- Memperbarui fungsi `saveSignatures()` untuk menerima dan menyimpan informasi crew leader dan crew leader position
- Menambahkan parameter opsional `crewLeader` dan `crewLeaderPosition` ke fungsi `saveSignatures()`
- Mengupdate pemanggilan API untuk `/training/signatures-save.php` agar menyertakan informasi crew leader

## File Tidak Dimodifikasi
- lib/screens/training/training_schedule_list_screen.dart - Tidak perlu perubahan karena sudah tidak memiliki action untuk memulai sesi
- lib/services/training/training_service.dart - Fungsi `startTrainingSession` sudah menggunakan endpoint yang benar untuk mengubah status

## Fitur yang Diimplementasikan
1. Sistem jadwal hanya menampilkan jadwal dengan status "scheduled" di daily training screen
2. Status jadwal tetap "scheduled" bahkan jika dibuat untuk hari ini
3. Proses perubahan status dari "scheduled" ke "ongoing" hanya terjadi ketika trainer memulai sesi dari daily training screen
4. Tidak ada tombol atau action untuk memulai training dari schedule list screen atau detail screen
5. Informasi crew leader sekarang bisa disimpan bersamaan dengan signatures
6. Kategori training sekarang ditampilkan dengan benar di detail screen dengan pendekatan multi-sumber untuk mengambil data
7. Workflow training tetap sesuai spesifikasi: schedule -> start from daily training -> ongoing -> complete

## Catatan
- Tidak ada perubahan backend/API yang dilakukan
- Semua perubahan hanya pada sisi frontend mobile app
- Fungsi `startTrainingSession` di training_service.dart sudah menggunakan endpoint yang benar untuk mengubah status
- Perubahan ini mengikuti prinsip bahwa hanya daily training screen yang bisa memulai sesi training
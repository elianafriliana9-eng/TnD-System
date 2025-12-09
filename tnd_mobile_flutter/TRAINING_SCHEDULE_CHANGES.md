# Perubahan pada Sistem Jadwal Training TnD Mobile

## Tujuan
Memperbaiki sistem jadwal training sesuai dengan spesifikasi:
- Jadwal yang diinput dari form jadwal training disimpan dengan status "scheduled", bahkan jika tanggalnya hari ini
- Status berubah menjadi "ongoing" hanya ketika trainer memulai sesi checklist dari daily training
- Screen jadwal training hanya untuk monitoring dan membuat jadwal (tanpa action start training)
- Screen daily training adalah satu-satunya tempat untuk memulai sesi

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

## File Tidak Dimodifikasi
- lib/screens/training/training_schedule_list_screen.dart - Tidak perlu perubahan karena sudah tidak memiliki action untuk memulai sesi
- lib/services/training/training_service.dart - Fungsi `startTrainingSession` sudah menggunakan endpoint yang benar untuk mengubah status dari "scheduled" ke "ongoing"

## Fitur yang Diimplementasikan
1. Sistem jadwal hanya menampilkan jadwal dengan status "scheduled" di daily training screen
2. Status jadwal tetap "scheduled" bahkan jika dibuat untuk hari ini
3. Proses perubahan status dari "scheduled" ke "ongoing" hanya terjadi ketika trainer memulai sesi dari daily training screen
4. Tidak ada tombol atau action untuk memulai training dari schedule list screen atau detail screen
5. Satu-satunya tempat untuk memulai sesi adalah dari daily training screen

## Catatan
- Tidak ada perubahan backend/API yang dilakukan
- Perubahan hanya pada sisi frontend mobile app
- Fungsi `startTrainingSession` di training_service.dart sudah menggunakan endpoint yang benar untuk mengubah status
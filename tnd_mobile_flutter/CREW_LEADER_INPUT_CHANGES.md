# Perubahan pada Sistem Jadwal Training TnD Mobile - Versi Crew Leader Baru

## Tujuan
Memperbaiki sistem jadwal training sesuai dengan spesifikasi:
- Jadwal yang diinput dari form jadwal training disimpan dengan status "scheduled", bahkan jika tanggalnya hari ini
- Status berubah menjadi "ongoing" hanya ketika trainer memulai sesi checklist dari daily training
- Screen jadwal training hanya untuk monitoring dan membuat jadwal (tanpa action start training)
- Screen daily training adalah satu-satunya tempat untuk memulai sesi
- Menyederhanakan tampilan detail training dengan menghilangkan card kategori training karena fokus utama adalah pada laporan
- Menghapus input crew leader dari form jadwal karena crew leader ditentukan saat pelaksanaan training
- Crew leader diinput saat proses tanda tangan digital di laporan training

## File yang Dimodifikasi

### 1. lib/screens/training/training_daily_screen.dart
- Memperbarui fungsi `_loadTodaySchedules()` untuk hanya menampilkan jadwal dengan status "scheduled" yang jatuh pada hari ini
- Filter ditambahkan: `schedule.scheduledDate.year == today.year && schedule.scheduledDate.month == today.month && schedule.scheduledDate.day == today.day && schedule.status == 'scheduled'`

### 2. lib/screens/training/training_schedule_form_screen.dart
- Menghapus input field "Crew Leader" dari form pembuatan jadwal karena crew leader akan ditentukan saat trainer tiba di outlet
- Memastikan bahwa parameter `status: 'scheduled'` selalu dikirim saat membuat jadwal, bahkan jika tanggalnya hari ini
- Menambahkan komentar untuk menandai bahwa status HARUS SELALU 'scheduled'

### 3. lib/screens/training/training_detail_screen.dart
- Menghapus tombol "Mulai Training" (FloatingActionButton) yang memungkinkan trainer memulai sesi dari detail screen
- Menjaga prinsip bahwa hanya Daily Training screen yang boleh memiliki fungsi untuk memulai sesi
- Menghapus card "Fokus Kategori Training" dari tampilan detail karena tidak terlalu penting (fokus utama adalah laporan)
- Menyederhanakan tampilan detail training untuk lebih fokus pada informasi penting
- Membersihkan kode yang tidak terpakai termasuk fungsi `_fetchCategories()` karena tidak lagi digunakan
- Mengurangi fokus pada informasi crew leader di detail screen karena sekarang crew leader akan ditentukan saat pelaksanaan training

### 4. lib/screens/training/training_session_checklist_screen.dart (digital signature area)
- Menambahkan input field untuk "Crew Leader" dalam proses tanda tangan digital di laporan training
- Memastikan crew leader yang diinput disimpan dalam laporan training

## File Tidak Dimodifikasi
- lib/screens/training/training_schedule_list_screen.dart - Tidak perlu perubahan karena sudah tidak memiliki action untuk memulai sesi
- lib/services/training/training_service.dart - Fungsi `startTrainingSession` sudah menggunakan endpoint yang benar untuk mengubah status dari "scheduled" ke "ongoing"

## Fitur yang Diimplementasikan
1. Sistem jadwal hanya menampilkan jadwal dengan status "scheduled" di daily training screen
2. Status jadwal tetap "scheduled" bahkan jika dibuat untuk hari ini
3. Proses perubahan status dari "scheduled" ke "ongoing" hanya terjadi ketika trainer memulai sesi dari daily training screen
4. Tidak ada tombol atau action untuk memulai training dari schedule list screen atau detail screen
5. Satu-satunya tempat untuk memulai sesi adalah dari daily training screen
6. Tampilan detail training lebih sederhana dan fokus pada informasi penting
7. Input crew leader dihapus dari form pembuatan jadwal
8. Crew leader diinput saat proses tanda tangan digital di laporan training
9. Card kategori training dihapus untuk menyederhanakan tampilan (karena fokus utama adalah laporan)

## Alur Kerja Baru
- **Pembuatan Jadwal**: Trainer membuat jadwal tanpa perlu menentukan crew leader
- **Pelaksanaan Training**: Saat trainer tiba di outlet, crew leader ditentukan berdasarkan orang yang bertugas di outlet saat itu
- **Proses Tanda Tangan**: Crew leader diinput saat proses digital signature di laporan training
- **Laporan**: Laporan menyertakan informasi crew leader yang diinput saat proses tanda tangan

## Catatan
- Tidak ada perubahan backend/API yang dilakukan
- Perubahan hanya pada sisi frontend mobile app
- Fungsi `startTrainingSession` di training_service.dart sudah menggunakan endpoint yang benar untuk mengubah status
- Penyederhanaan tampilan detail screen dilakukan untuk fokus pada elemen yang lebih penting (seperti laporan) bukan pada tampilan kategori
- Crew leader sekarang bersifat fleksibel dan ditentukan saat pelaksanaan training, bukan saat pembuatan jadwal
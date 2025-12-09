# Laporan Pekerjaan - 5 Desember 2025

## 1. Fix PDF Training - Crew Name vs Crew Leader
- ✅ Perbaiki tampilan PDF: **Nama Crew** hanya di info training bagian atas
- ✅ Bagian tanda tangan tetap menggunakan **Crew Leader** dari form ttd digital
- ✅ Update `training_pdf_service.dart` - signature section gunakan `_getCrewLeaderName(crewLeader, session)`
- ✅ Test: Crew name di info, crew leader di signature

## 2. Reorder Form Tanda Tangan Digital
- ✅ Pindahkan section **Informasi Crew Leader** ke paling atas
- ✅ Urutan baru: Info Crew Leader → TTD Auditor → TTD Crew in Charge
- ✅ Update `digital_signature_screen.dart`
- ✅ User experience lebih baik: isi info dulu baru tanda tangan

## 3. Fitur Change Password User (Web Super Admin)
### Frontend:
- ✅ Tambah tombol **"Change Password"** di modal Edit User
- ✅ Buat modal change password dengan form:
  - Input new password
  - Input confirm password
  - Checkbox show/hide password
- ✅ Validasi: minimal 6 karakter, password match
- ✅ Fungsi `showChangeUserPasswordModal()`, `toggleUserPasswordVisibility()`, `changeUserPassword()`

### API Layer:
- ✅ Tambah method `UsersAPI.changePassword(userId, newPassword)` di `api.js`

### Backend:
- ✅ Buat endpoint `user-change-password.php`
- ✅ Validasi authentication (require admin)
- ✅ Validasi input dan password length
- ✅ Proteksi: tidak bisa ubah password super admin lain
- ✅ Hash password dengan bcrypt
- ✅ Update database

## File yang Dimodifikasi
1. `tnd_mobile_flutter/lib/services/training/training_pdf_service.dart`
2. `tnd_mobile_flutter/lib/screens/digital_signature_screen.dart`
3. `frontend-web/assets/js/users.js`
4. `frontend-web/assets/js/api.js`
5. `backend-web/api/user-change-password.php` (NEW)

## Testing
- ✅ PDF menampilkan crew name dan crew leader dengan benar
- ✅ Form ttd digital urutan sudah sesuai
- ✅ Change password user ready untuk test di browser

## Status: SELESAI ✅

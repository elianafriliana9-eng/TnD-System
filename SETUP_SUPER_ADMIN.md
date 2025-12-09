# PANDUAN SETUP SUPER ADMIN DI SERVER

## Langkah-langkah Membuat Super Admin Baru

### STEP 1: Akses cPanel
1. Buka browser
2. Ke URL: `https://tndsystem.online/cpanel`
3. Login dengan kredensial cPanel Anda

### STEP 2: Buka phpMyAdmin
1. Scroll ke bagian **"Databases"**
2. Klik **"phpMyAdmin"**
3. Akan terbuka phpMyAdmin di tab baru

### STEP 3: Pilih Database
1. Di sidebar kiri, klik database: **`u211765246_tnd_db`**
2. Database akan terbuka dan tampil daftar tabel

### STEP 4: Execute SQL Script
1. Klik tab **"SQL"** di bagian atas
2. Buka file: `backend-web/create_super_admin.sql`
3. **Copy semua isi file** (Ctrl+A, Ctrl+C)
4. **Paste di SQL editor** di phpMyAdmin
5. Klik tombol **"Go"** di kanan bawah

### STEP 5: Verifikasi Hasil
Setelah execute, Anda akan melihat 2 hasil:
1. **Query 1 (DELETE)**: "X rows deleted" - menghapus admin lama
2. **Query 2 (INSERT)**: "1 row inserted" - membuat admin baru
3. **Query 3 (SELECT)**: Tampil data admin yang baru dibuat

Hasil SELECT akan menampilkan:
```
id | username    | full_name            | email              | role        | is_active | created_at
1  | superadmin  | Super Administrator  | tndsrt@gmail.com   | super_admin | 1         | 2025-11-03 ...
```

### STEP 6: Test Login
1. Buka URL: `https://tndsystem.online/backend-web/`
2. Login dengan:
   - **Username**: `superadmin`
   - **Password**: `Srttnd2025!`
3. Jika berhasil, Anda masuk ke dashboard super admin

---

## Kredensial Super Admin

### Login Web Dashboard:
- **URL**: https://tndsystem.online/backend-web/
- **Username**: superadmin
- **Password**: Srttnd2025!
- **Email**: tndsrt@gmail.com
- **Role**: Super Admin

---

## Troubleshooting

### Jika Password Tidak Bisa Login:

Password hash mungkin tidak cocok. Generate hash baru:

1. Buka: https://bcrypt-generator.com/
2. Isi **Plain Text**: `Srttnd2025!`
3. Pilih **Cost/Rounds**: `10`
4. Klik **"Encrypt"**
5. Copy **Hash** yang dihasilkan (mulai dengan `$2y$10$...`)
6. Di phpMyAdmin, execute query ini (ganti `HASH_BARU` dengan hash yang dicopy):

```sql
UPDATE users 
SET password = 'HASH_BARU' 
WHERE email = 'tndsrt@gmail.com';
```

---

## OPTIONAL: Membersihkan Data Sample

Jika ingin menghapus SEMUA data test/sample, execute query ini di phpMyAdmin:

```sql
-- Hapus semua foto visit
DELETE FROM visit_photos;

-- Hapus semua checklist responses  
DELETE FROM visit_checklist_responses;

-- Hapus semua visit
DELETE FROM visits;

-- Hapus semua rekomendasi
DELETE FROM improvement_recommendations;

-- Hapus semua user KECUALI super admin
DELETE FROM users WHERE email != 'tndsrt@gmail.com';
```

**PERHATIAN**: 
- Data yang dihapus TIDAK BISA dikembalikan!
- Pastikan backup database sebelum menghapus
- Data checklist, outlets TIDAK akan terhapus (aman)

---

## Backup Database (Recommended)

Sebelum melakukan perubahan besar, backup database:

1. Di phpMyAdmin, pilih database `u211765246_tnd_db`
2. Klik tab **"Export"**
3. Pilih **"Quick"** method
4. Format: **SQL**
5. Klik **"Go"**
6. File .sql akan terdownload
7. Simpan file sebagai backup

---

## Setelah Super Admin Dibuat

### Yang Bisa Dilakukan:
1. ✅ Login ke web dashboard
2. ✅ Tambah user baru (sales, supervisor, admin)
3. ✅ Tambah/edit outlet
4. ✅ Setup checklist categories & points
5. ✅ Monitor visits dari mobile app
6. ✅ Review recommendations
7. ✅ Generate reports

### User Guide:
- Lihat file: `USER_GUIDE.md` untuk panduan lengkap
- Copy isi file ke MS Word untuk dokumentasi
- Bagikan ke tim untuk training

---

## Keamanan

### Tips Keamanan:
1. ✅ **Jangan share** password ke orang lain
2. ✅ **Ganti password** secara berkala
3. ✅ **Logout** setelah selesai menggunakan
4. ✅ **Backup database** rutin (minimal seminggu sekali)
5. ✅ **Monitor** user activity dari dashboard

### Jika Lupa Password:
1. Akses phpMyAdmin via cPanel
2. Generate hash baru di bcrypt-generator.com
3. Update dengan query UPDATE seperti di atas

---

## Contact Support

Jika ada masalah:
- **Developer**: Elian Afriliana
- **Email**: (isi email support Anda)
- **Phone/WA**: (isi nomor support Anda)

---

**SELAMAT! Sistem siap digunakan untuk production! 🎉**

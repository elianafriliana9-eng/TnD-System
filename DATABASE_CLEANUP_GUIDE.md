# Database Cleanup Instructions

Masalah: Category ID error - items masih mencari category_id yang sudah dihapus (10, 11 dst)

## Solusi:

### Step 1: Check Current State
1. Buka phpMyAdmin
2. Pilih database `tnd_db`
3. Klik tab **SQL**
4. Copy-paste query dari file `CHECK_DB_STATE.sql`
5. Klik **Execute** dan lihat hasilnya
   - Berapa category yang ada?
   - Berapa items yang orphaned (category_id tidak ada)?

### Step 2: Cleanup Database
1. Setelah tahu kondisinya, copy-paste query dari file `CLEANUP_ORPHANED_ITEMS.sql`
2. Klik **Execute**
3. Script akan:
   - Hapus semua items dengan category_id yang tidak ada
   - Hapus semua points dengan category_id yang tidak ada
   - Verifikasi data bersih

### Step 3: Hasil Akhir
Setelah cleanup:
- ✅ Hanya categories yang ada di training_categories yang memiliki items
- ✅ Tidak ada orphaned items
- ✅ Trainer bisa membuat category baru tanpa FK error
- ✅ Error "Available IDs" akan hilang karena semua items valid

## Cara Trainer Membuat Category Baru:

1. Buka Mobile App
2. Navigasi ke **Training Management** → **Checklist Management**
3. Klik tombol **"+"** di pojok kanan atas (Add Category)
4. Isi form:
   - Nama Kategori
   - Deskripsi (opsional)
5. Klik **Simpan**
6. Category muncul di list dengan ID baru
7. Klik kategori untuk expand → Klik **"+"** untuk tambah items ke kategori tersebut

## Catatan:
- Category ID otomatis digenerate oleh database
- Trainer TIDAK perlu khawatir ID berapa, system akan handle
- Semua category yang trainer buat akan valid dan tidak ada FK error

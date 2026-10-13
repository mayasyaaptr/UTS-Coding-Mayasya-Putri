# UTS Pengkodean dan Pemrograman: Sistem Jurnal Akuntansi

Repositori ini berisi seluruh artefak jawaban Ujian Tengah Semester (UTS) Pengkodean dan Pemrograman, berupa skema database, trigger, purwarupa web, dan mekanisme jejak audit untuk sistem informasi akuntansi.

## Biodata

| Keterangan | Isi |
| --- | --- |
| Nama | Mayasya Putri |
| NIM | 12030124140312 |
| Kelas | Pengkodean dan Pemrograman / E |
| Dosen Pengampu | Totok Dewayanto |

## Ringkasan Isi

| Soal | Bobot | Topik | Berkas |
| --- | --- | --- | --- |
| 1 | 25% | Desain arsitektur data, normalisasi, dan penegakan asas berpasangan | `soal1/1.1_erd.png`, `soal1/01_schema.sql` |
| 2 | 40% | Otomasi persediaan dengan trigger dan penanganan concurrency | `soal2/02_trigger.sql`, `soal2/02b_concurrency.sql` |
| 3 | 35% | Purwarupa web voucher kas keluar, verifikasi aturan bisnis, dan jejak audit | `soal3/voucher.html`, `soal3/03_audit.sql`, `soal3/log_prompt_gemini.md`, `soal3/notebooklm_verifikasi.md` |

Bukti pengujian (screenshot) untuk setiap soal tersimpan di folder `screenshots/`.

## Struktur Repositori

```
uts-coding/
├── README.md
├── soal1/
│   ├── 1.1_erd.png
│   └── 01_schema.sql
├── soal2/
│   ├── 02_trigger.sql
│   └── 02b_concurrency.sql
├── soal3/
│   ├── voucher.html
│   ├── 03_audit.sql
│   ├── log_prompt_gemini.md
│   └── notebooklm_verifikasi.md

```

## Penjelasan Singkat per Soal

**Soal 1: Skema relasional dan asas berpasangan.** Skema terdiri dari `chart_of_accounts`, `journal_headers`, dan `journal_lines`. Constraint CHECK, foreign key `ON DELETE RESTRICT`, dan UNIQUE digunakan untuk menjaga integritas data. Pemisahan header dan baris memenuhi bentuk normal ketiga (3NF) dan memudahkan jejak audit.

**Soal 2: Trigger persediaan.** Fungsi `trg_update_stock_and_journal()` memperbarui `stock_qty` secara otomatis setiap ada transaksi pada `inventory_transactions`, dan membatalkan transaksi dengan `RAISE EXCEPTION` bila stok menjadi negatif. Berkas `02b_concurrency.sql` memuat contoh penanganan race condition dengan `SELECT ... FOR UPDATE`, pembaruan atomik bersyarat, dan isolasi `SERIALIZABLE`.

**Soal 3: Purwarupa web dan jejak audit.** `voucher.html` adalah formulir voucher kas keluar dengan indikator keseimbangan debit dan kredit secara langsung. `03_audit.sql` menambahkan kolom audit, hash checksum SHA-256, penguncian transaksi berstatus POSTED melalui trigger, serta fungsi `post_journal()` dan `reverse_journal()` untuk posting dan koreksi melalui jurnal pembalik.

## Cara Menjalankan

Seluruh skrip SQL dijalankan di PostgreSQL atau Supabase SQL Editor dengan urutan berikut:

1. `soal1/01_schema.sql` untuk membuat tabel jurnal.
2. `soal2/02_trigger.sql` untuk membuat tabel persediaan, fungsi trigger, dan trigger-nya.
3. `soal3/03_audit.sql` untuk menambahkan kolom audit, trigger penguncian, serta fungsi posting dan storno. Skrip ini bergantung pada tabel dari langkah 1 dan sebaiknya dijalankan setelah data uji Soal 1 dibersihkan.

Untuk membuka purwarupa web, unduh `soal3/voucher.html` lalu buka dengan browser.

## Catatan

- Pada `voucher.html`, `SUPABASE_URL` dan `SUPABASE_ANON_KEY` masih berupa nilai pengganti. Formulir tetap berfungsi untuk validasi dan indikator keseimbangan tanpa koneksi database. Penyimpanan ke database memerlukan kedua nilai tersebut diisi dan fungsi RPC `create_voucher` tersedia di Supabase.
- Kolom `created_by` pada `journal_headers` menggunakan `auth.uid()` milik Supabase. Pada pengujian melalui SQL Editor, kolom ini kosong karena tidak ada pengguna yang login; pada aplikasi sesungguhnya kolom ini terisi otomatis.
- Penggunaan alat bantu AI (Gemini Canvas dan NotebookLM) didokumentasikan pada `soal3/log_prompt_gemini.md` dan `soal3/notebooklm_verifikasi.md`.

## Dokumentasi

Laporan jawaban lengkap dalam format PDF: [tempel link laporan di sini]

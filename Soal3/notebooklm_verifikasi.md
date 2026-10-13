https://notebook.google.com/notebook/595c052c-4ea0-43c5-8ecf-29b7f316fc37

**Ya, logika pencatatan kas keluar pada kode tersebut sudah sesuai dengan ketentuan pengakuan dan pengukuran kas dan setara kas** berdasarkan PSAK 207 (Laporan Arus Kas), PSAK 201 (Penyajian Laporan Keuangan), serta Kerangka Konseptual Pelaporan Keuangan[1].

Berikut adalah analisis kesesuaian logika pencatatan pada kode tersebut:

### 1\. Penerapan Pembukuan Berpasangan (*Double-Entry System*)

* **Mekanisme Debit-Kredit**: Kode frontend (``) dan skema tabel database (`journal_lines`) mengimplementasikan prinsip akuntansi berpasangan[1][2].
* **Pengurangan Kas**: Pengeluaran kas dicatat pada posisi **Kredit** pada akun kas/setara kas (misalnya `1-1110 Kas Kecil` atau `1-1120 Bank BCA - Giro`), yang mencerminkan penurunan aset kas[1].
* **Akun Lawan**: Akun yang menerima pengeluaran (seperti `5-1300 Biaya Utilitas` atau `2-1100 Hutang Usaha`) dicatat pada posisi **Debit**[1]. Hal ini selaras dengan Kerangka Konseptual di mana pengakuan beban atau pelunasan kewajiban terjadi bersamaan dengan penghentian atau penurunan jumlah tercatat aset kas[1][3].

### 2\. Pengakuan dan Pengukuran Berdasarkan Transaksi Kas Aktual (PSAK 207)

* **Kas/Arus Kas Realisasi**: Berdasarkan PSAK 207, pengakuan arus kas keluar wajib diakui saat terjadi transaksi pengeluaran kas aktual[4].
* **Pengukuran Nilai Nominal**: PSAK 207 mensyaratkan bahwa arus kas diukur berdasarkan nilai nominal transaksi tanpa penyesuaian nilai waktu uang atau inflasi[5][7]. Pada kode antarmuka voucher kas keluar, jumlah pengeluaran diinput dan dihitung berdasarkan nilai rupiah aktual dari baris transaksi[1][7].

### 3\. Klasifikasi Akun Kas dan Setara Kas

* Kode menggunakan akun terstruktur seperti `1-1110 Kas Kecil` dan `1-1120 Bank BCA - Giro`[1]. Dalam PSAK 207, komponen kas mencakup saldo kas (*cash on hand*) dan rekening giro bank yang sangat likuid dan siap digunakan untuk operasional entitas[6][8].

### 4\. Validasi Integritas Data Akuntansi

Kode antarmuka dan basis data menerapkan pengendalian internal yang ketat untuk memastikan keandalan laporan keuangan:

* **Keseimbangan Jurnal (** **Balance Alert** **)**: Kode memverifikasi secara langsung bahwa `totalDebit === totalKredit`[1].
* **Aturan Eksklusivitas Baris (** **chk\_one\_side\_only** **)**: Menggunakan batasan SQL dan pengecekan JavaScript agar setiap baris jurnal hanya berisi nilai Debit &gt; 0 atau Kredit &gt; 0 saja (tidak boleh diisi keduanya atau bernilai nol)[1][2].
* **Persyaratan Minimal Baris**: Mengunci tombol transaksi hingga minimal terdapat 2 baris jurnal yang seimbang[1].
* **Transaksi Atomik (RPC Supabase)**: Pengiriman data menggunakan `create_voucher` memastikan header dan rincian jurnal disimpan secara bersamaan untuk menjaga konsistensi transaksi[1].

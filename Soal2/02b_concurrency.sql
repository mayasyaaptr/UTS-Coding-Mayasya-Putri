BEGIN;
 
SELECT stock_qty FROM inventory_items
WHERE item_id = 'BRG001'
FOR UPDATE;                      -- baris terkunci; sesi lain menunggu
 
-- aplikasi memeriksa stock_qty >= qty yang diminta
INSERT INTO inventory_transactions(item_id, trx_type, qty)
VALUES ('BRG001', 'SALE', 1);    -- trigger mengurangi stok dan menolak bila negatif
UPDATE inventory_items
   SET stock_qty = stock_qty - 1
 WHERE item_id = 'BRG001' AND stock_qty >= 1;
-- jika 0 baris terpengaruh, stok habis dan penjualan ditolak
BEGIN ISOLATION LEVEL SERIALIZABLE;
  -- baca stok, cek, insert transaksi
COMMIT;   -- bila gagal dengan SQLSTATE 40001, ulangi seluruh transaksi

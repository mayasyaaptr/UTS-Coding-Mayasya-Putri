CREATE OR REPLACE FUNCTION trg_update_stock_and_journal()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_delta   INT;
    v_new_qty INT;
BEGIN
    IF NEW.trx_type IN ('SALE','PURCHASE') AND NEW.qty <= 0 THEN
        RAISE EXCEPTION 'Qty untuk % harus positif (diterima: %)', NEW.trx_type, NEW.qty;
    END IF;

    v_delta := CASE NEW.trx_type
                 WHEN 'PURCHASE'   THEN  NEW.qty
                 WHEN 'SALE'       THEN -NEW.qty
                 WHEN 'ADJUSTMENT' THEN  NEW.qty
               END;

    -- UPDATE mengunci baris item sampai transaksi selesai
    UPDATE inventory_items
       SET stock_qty = stock_qty + v_delta
     WHERE item_id = NEW.item_id
    RETURNING stock_qty INTO v_new_qty;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Item % tidak ditemukan', NEW.item_id;
    END IF;

    -- b. Anti-negative inventory
    IF v_new_qty < 0 THEN
        RAISE EXCEPTION 'Stok item % tidak cukup: transaksi % qty % membuat stok menjadi %',
                        NEW.item_id, NEW.trx_type, NEW.qty, v_new_qty;
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_inventory_after_insert
AFTER INSERT ON inventory_transactions
FOR EACH ROW
EXECUTE FUNCTION trg_update_stock_and_journal();
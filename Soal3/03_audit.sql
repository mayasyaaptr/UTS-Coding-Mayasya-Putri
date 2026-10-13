TRUNCATE journal_lines, journal_headers, chart_of_accounts RESTART IDENTITY;

ALTER TABLE journal_headers
  ADD COLUMN created_by    UUID DEFAULT auth.uid(),
  ADD COLUMN created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  ADD COLUMN posted_by     UUID,
  ADD COLUMN posted_at     TIMESTAMPTZ,
  ADD COLUMN hash_checksum CHAR(64),
  ADD COLUMN reversal_of   BIGINT REFERENCES journal_headers(header_id) ON DELETE RESTRICT,
  ADD CONSTRAINT uq_one_reversal UNIQUE (reversal_of);

CREATE TABLE audit_log (
  log_id     BIGSERIAL PRIMARY KEY,
  table_name TEXT        NOT NULL,
  record_id  BIGINT      NOT NULL,
  action     TEXT        NOT NULL,
  actor      UUID,
  logged_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  details    JSONB
);

CREATE OR REPLACE FUNCTION compute_journal_hash(p_header_id BIGINT)
RETURNS TEXT LANGUAGE sql STABLE AS $$
  SELECT encode(sha256(convert_to(
    h.ref_no || '|' || h.trx_date || '|' || coalesce(h.description,'') || '|' ||
    coalesce((SELECT string_agg(l.account_id || ':' || l.debit || ':' || l.credit, ';' ORDER BY l.line_id)
              FROM journal_lines l WHERE l.header_id = h.header_id), ''),
    'UTF8')), 'hex')
  FROM journal_headers h WHERE h.header_id = p_header_id;
$$;

CREATE OR REPLACE FUNCTION trg_guard_posted()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE v_status TEXT; v_hid BIGINT;
BEGIN
  IF TG_TABLE_NAME = 'journal_headers' THEN
    IF OLD.posting_status = 'POSTED' THEN
      RAISE EXCEPTION 'Jurnal % sudah POSTED dan tidak boleh di-%; gunakan jurnal pembalik',
                      OLD.ref_no, TG_OP;
    END IF;
  ELSE
    v_hid := COALESCE(NEW.header_id, OLD.header_id);
    SELECT posting_status INTO v_status FROM journal_headers WHERE header_id = v_hid;
    IF v_status = 'POSTED' THEN
      RAISE EXCEPTION 'Baris jurnal pada header % sudah POSTED dan terkunci', v_hid;
    END IF;
  END IF;
  RETURN COALESCE(NEW, OLD);
END; $$;

CREATE TRIGGER guard_headers BEFORE UPDATE OR DELETE ON journal_headers
  FOR EACH ROW EXECUTE FUNCTION trg_guard_posted();
CREATE TRIGGER guard_lines BEFORE INSERT OR UPDATE OR DELETE ON journal_lines
  FOR EACH ROW EXECUTE FUNCTION trg_guard_posted();

CREATE OR REPLACE FUNCTION trg_block_mutation() RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN RAISE EXCEPTION 'audit_log hanya boleh di-INSERT'; END; $$;
CREATE TRIGGER audit_append_only BEFORE UPDATE OR DELETE ON audit_log
  FOR EACH ROW EXECUTE FUNCTION trg_block_mutation();

CREATE OR REPLACE FUNCTION post_journal(p_header_id BIGINT)
RETURNS VOID LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE v_d NUMERIC; v_k NUMERIC;
BEGIN
  SELECT coalesce(sum(debit),0), coalesce(sum(credit),0) INTO v_d, v_k
  FROM journal_lines WHERE header_id = p_header_id;

  IF v_d = 0 OR v_d <> v_k THEN
    RAISE EXCEPTION 'Jurnal tidak seimbang: debit % kredit %', v_d, v_k;
  END IF;

  UPDATE journal_headers
     SET posting_status = 'POSTED', posted_by = auth.uid(), posted_at = now(),
         hash_checksum = compute_journal_hash(p_header_id)
   WHERE header_id = p_header_id AND posting_status = 'DRAFT';

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Jurnal % tidak ditemukan atau sudah POSTED', p_header_id;
  END IF;

  INSERT INTO audit_log(table_name, record_id, action, actor, details)
  VALUES ('journal_headers', p_header_id, 'POST', auth.uid(),
          jsonb_build_object('debit', v_d, 'credit', v_k));
END; $$;

CREATE OR REPLACE FUNCTION reverse_journal(p_header_id BIGINT, p_reason TEXT)
RETURNS BIGINT LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE v_new BIGINT; v_ref TEXT;
BEGIN
  SELECT ref_no INTO v_ref FROM journal_headers
  WHERE header_id = p_header_id AND posting_status = 'POSTED';
  IF v_ref IS NULL THEN RAISE EXCEPTION 'Hanya jurnal POSTED yang bisa distorno'; END IF;

  INSERT INTO journal_headers(trx_date, ref_no, description, reversal_of)
  VALUES (current_date, v_ref || '-REV', 'Storno ' || v_ref || ': ' || p_reason, p_header_id)
  RETURNING header_id INTO v_new;

  INSERT INTO journal_lines(header_id, account_id, debit, credit)
  SELECT v_new, account_id, credit, debit
  FROM journal_lines WHERE header_id = p_header_id;

  PERFORM post_journal(v_new);

  INSERT INTO audit_log(table_name, record_id, action, actor, details)
  VALUES ('journal_headers', p_header_id, 'REVERSE', auth.uid(),
          jsonb_build_object('reversal_id', v_new, 'reason', p_reason));
  RETURN v_new;
END; $$;

INSERT INTO chart_of_accounts(account_code, account_name, normal_balance, report_class)
VALUES ('1-1100','Kas','D','NERACA'), ('5-2000','Beban Listrik','D','LABA_RUGI');

INSERT INTO journal_headers(trx_date, ref_no, description)
VALUES (current_date, 'KK-001', 'Bayar listrik');

INSERT INTO journal_lines(header_id, account_id, debit, credit)
VALUES
 ((SELECT header_id FROM journal_headers WHERE ref_no='KK-001'),
  (SELECT account_id FROM chart_of_accounts WHERE account_code='5-2000'), 1500000, 0),
 ((SELECT header_id FROM journal_headers WHERE ref_no='KK-001'),
  (SELECT account_id FROM chart_of_accounts WHERE account_code='1-1100'), 0, 1500000);

SELECT post_journal((SELECT header_id FROM journal_headers WHERE ref_no='KK-001'));

SELECT ref_no, posting_status, hash_checksum FROM journal_headers;
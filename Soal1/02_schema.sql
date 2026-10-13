CREATE TABLE chart_of_accounts (
    account_id     SERIAL PRIMARY KEY,
    account_code   VARCHAR(20)  NOT NULL UNIQUE,
    account_name   VARCHAR(150) NOT NULL,
    normal_balance CHAR(1)      NOT NULL CHECK (normal_balance IN ('D','K')),
    report_class   VARCHAR(20)  NOT NULL CHECK (report_class IN ('NERACA','LABA_RUGI'))
);

CREATE TABLE journal_headers (
    header_id      BIGSERIAL PRIMARY KEY,
    trx_date       DATE         NOT NULL,
    ref_no         VARCHAR(50)  NOT NULL UNIQUE,
    description    TEXT,
    posting_status VARCHAR(10)  NOT NULL DEFAULT 'DRAFT'
                   CHECK (posting_status IN ('DRAFT','POSTED'))
);

CREATE TABLE journal_lines (
    line_id    BIGSERIAL PRIMARY KEY,
    header_id  BIGINT NOT NULL REFERENCES journal_headers(header_id) ON DELETE RESTRICT,
    account_id INT    NOT NULL REFERENCES chart_of_accounts(account_id) ON DELETE RESTRICT,
    debit      NUMERIC(18,2) NOT NULL DEFAULT 0 CHECK (debit  >= 0),
    credit     NUMERIC(18,2) NOT NULL DEFAULT 0 CHECK (credit >= 0),
    CONSTRAINT chk_not_both_zero CHECK (NOT (debit = 0 AND credit = 0)),
    CONSTRAINT chk_one_side_only CHECK (debit = 0 OR credit = 0)
);

CREATE INDEX idx_lines_header  ON journal_lines(header_id);
CREATE INDEX idx_lines_account ON journal_lines(account_id);
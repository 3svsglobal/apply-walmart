-- 수기 서명 계약서 스캔본 첨부용 컬럼
ALTER TABLE wm_contracts ADD COLUMN IF NOT EXISTS scanned_url TEXT;
ALTER TABLE wm_contracts ADD COLUMN IF NOT EXISTS scanned_name TEXT;       -- 원본 파일명
ALTER TABLE wm_contracts ADD COLUMN IF NOT EXISTS scanned_at TIMESTAMPTZ;  -- 첨부 시각
ALTER TABLE wm_contracts ADD COLUMN IF NOT EXISTS scanned_by TEXT;         -- 업로더 (admin/walmart/brand)

SELECT column_name FROM information_schema.columns
WHERE table_name = 'wm_contracts' AND column_name LIKE 'scanned%'
ORDER BY column_name;

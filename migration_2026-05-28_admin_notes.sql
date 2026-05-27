-- 기업 내부 메모 컬럼 추가 (관리자/Walmart 만 접근, 브랜드에는 노출 안 함)
ALTER TABLE wm_brands ADD COLUMN IF NOT EXISTS admin_notes TEXT;

-- 검증
SELECT column_name FROM information_schema.columns
WHERE table_name = 'wm_brands' AND column_name = 'admin_notes';

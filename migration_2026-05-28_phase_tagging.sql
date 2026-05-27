-- Tasks: phase 태그 컬럼 추가 (contract/phase1/phase2/phase3/completed/null=common)
ALTER TABLE wm_tasks ADD COLUMN IF NOT EXISTS phase TEXT;
CREATE INDEX IF NOT EXISTS idx_wm_tasks_phase ON wm_tasks(phase);

-- Brands: phase별 내부 메모를 위한 JSONB 컬럼
-- 구조: { "contract": "...", "phase1": "...", "phase2": "...", "phase3": "...", "completed": "...", "general": "..." }
ALTER TABLE wm_brands ADD COLUMN IF NOT EXISTS admin_notes_by_phase JSONB DEFAULT '{}'::jsonb;

-- 기존 admin_notes TEXT 데이터를 general 키로 마이그레이션 (한 번만 실행, 안전 가드)
UPDATE wm_brands
   SET admin_notes_by_phase = jsonb_build_object('general', admin_notes)
 WHERE admin_notes IS NOT NULL
   AND admin_notes <> ''
   AND (admin_notes_by_phase IS NULL OR admin_notes_by_phase = '{}'::jsonb);

-- 검증
SELECT 'wm_tasks.phase' AS col, count(*) FILTER (WHERE phase IS NOT NULL) AS rows_with_phase, count(*) AS total FROM wm_tasks
UNION ALL
SELECT 'wm_brands.admin_notes_by_phase', count(*) FILTER (WHERE admin_notes_by_phase IS NOT NULL AND admin_notes_by_phase <> '{}'::jsonb), count(*) FROM wm_brands;

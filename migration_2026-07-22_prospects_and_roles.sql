-- 2026-07-22 마이그레이션 (라이브 적용 완료)
-- 1) Walmart 역할 제거 → 2역할 구조: Startup Junkie(louis)를 admin 권한으로 통합
-- 2) 실시간 아웃리치 추적 테이블 wm_prospects 신설 (담당 Claim으로 중복 접촉 방지)

-- ─── 1. louis(Startup Junkie) 계정을 admin 역할로 ───
UPDATE wm_staff_accounts SET role = 'admin' WHERE username = 'louis';

-- ─── 2. wm_prospects (잠재 브랜드 아웃리치) ───
CREATE TABLE IF NOT EXISTS wm_prospects (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  brand_name TEXT NOT NULL,
  category TEXT,
  website TEXT,
  contact_info TEXT,
  source TEXT,
  status TEXT DEFAULT 'new' CHECK (status IN ('new','contacted','in_talks','converted','dropped')),
  claimed_by TEXT,            -- 담당 스태프 username (Claim)
  claimed_by_name TEXT,
  claimed_at TIMESTAMPTZ,
  last_contact_at TIMESTAMPTZ,
  notes TEXT,
  created_by TEXT
);
CREATE INDEX IF NOT EXISTS idx_wm_prospects_status ON wm_prospects(status);
CREATE INDEX IF NOT EXISTS idx_wm_prospects_claimed ON wm_prospects(claimed_by);

ALTER TABLE wm_prospects ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "wm_prospects_all" ON wm_prospects;
CREATE POLICY "wm_prospects_all" ON wm_prospects FOR ALL USING (true) WITH CHECK (true);
-- ⚠️ 현재 anon 전체 허용(앱 전반과 동일). 향후 S1 보안 작업에서 잠금 예정.

SELECT 'wm_prospects' AS table_name, count(*) AS rows FROM wm_prospects;

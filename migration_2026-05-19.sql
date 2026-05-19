-- ═══════════════════════════════════════════════════════════
-- Walmart Entry Program — Migration 2026-05-19
--
-- 실행 방법:
-- 1. https://supabase.com/dashboard/project/ixvuvaaovcsrcfjmrrnb 접속
-- 2. SQL Editor 열기
-- 3. 아래 전체 복사 → 붙여넣기 → Run
--
-- ※ 이 스크립트는 idempotent(여러 번 실행해도 안전)하게 작성됨
-- ═══════════════════════════════════════════════════════════

-- ─── 1. wm_applications: attached_files 컬럼 추가 ───
-- (신청 폼의 Brand Deck / Additional Docs / SKU List 업로드 메타데이터 저장용)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'wm_applications' AND column_name = 'attached_files'
  ) THEN
    ALTER TABLE wm_applications ADD COLUMN attached_files TEXT;
  END IF;
END $$;

-- ─── 2. wm_brands: portal_password 컬럼 추가 ───
-- (브랜드 포탈 로그인용 비밀번호 — 승인 시 자동 생성)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'wm_brands' AND column_name = 'portal_password'
  ) THEN
    ALTER TABLE wm_brands ADD COLUMN portal_password TEXT;
  END IF;
END $$;

-- ─── 3. wm_messages 테이블 생성 ───
-- (브랜드 ↔ 관리자 메시지 시스템)
CREATE TABLE IF NOT EXISTS wm_messages (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  created_at TIMESTAMPTZ DEFAULT now(),
  brand_id TEXT REFERENCES wm_brands(id),
  sender_role TEXT CHECK (sender_role IN ('brand', 'admin', 'walmart')),
  sender_name TEXT,
  content TEXT NOT NULL,
  read_by_admin BOOLEAN DEFAULT false,
  read_by_brand BOOLEAN DEFAULT false
);

ALTER TABLE wm_messages ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Anyone can read messages" ON wm_messages;
DROP POLICY IF EXISTS "Anyone can insert messages" ON wm_messages;
DROP POLICY IF EXISTS "Anyone can update messages" ON wm_messages;

CREATE POLICY "Anyone can read messages" ON wm_messages FOR SELECT USING (true);
CREATE POLICY "Anyone can insert messages" ON wm_messages FOR INSERT WITH CHECK (true);
CREATE POLICY "Anyone can update messages" ON wm_messages FOR UPDATE USING (true);

-- ─── 4. 확인 쿼리 (선택) ───
-- 아래 두 줄은 실행 후 결과를 보고 확인용으로 쓸 수 있음
SELECT column_name FROM information_schema.columns WHERE table_name = 'wm_applications' AND column_name = 'attached_files';
SELECT column_name FROM information_schema.columns WHERE table_name = 'wm_brands' AND column_name = 'portal_password';
SELECT COUNT(*) AS wm_messages_exists FROM information_schema.tables WHERE table_name = 'wm_messages';

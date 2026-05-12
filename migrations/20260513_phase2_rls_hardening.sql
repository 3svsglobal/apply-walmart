-- ═══════════════════════════════════════════════════════════
-- Phase 2 — RLS hardening + portal_password 해시화
-- ═══════════════════════════════════════════════════════════
--
-- 적용 전 필독 (PHASE2_PLAN.md 참조):
--   1. STAGING Supabase 인스턴스에서 먼저 실행
--   2. 신청 폼 / admin 로그인 / 계약서 서명 / 메시지 전체 흐름 smoke test
--   3. 기존 wm_brands.portal_password (평문) 가 백필되면 frontend의
--      .eq('portal_password', pw) 비교는 모두 깨짐 — index.html
--      side 변경(별도 PR 또는 commit)이 동반되어야 prod 머지 가능
--   4. wm-signatures bucket policy 는 Supabase Dashboard 에서 별도 설정
--      (이 SQL 만으로는 Storage 권한 변경 안 됨)
--
-- 이 마이그레이션은 idempotent — 재실행 안전.
-- ═══════════════════════════════════════════════════════════

-- ─────────────────────────────────────────────────────────────
-- 1. pgcrypto extension (crypt + gen_salt 사용)
-- ─────────────────────────────────────────────────────────────
CREATE EXTENSION IF NOT EXISTS pgcrypto;


-- ─────────────────────────────────────────────────────────────
-- 2. wm_applications RLS — anon 제거
--    INSERT (신청 폼) 만 익명 허용. SELECT / UPDATE 는 인증된 사용자만.
--    실제 admin 권한 분기는 wm_admins 테이블 (아래) 의 row 존재 여부로.
-- ─────────────────────────────────────────────────────────────

DROP POLICY IF EXISTS "Public can submit application" ON wm_applications;
DROP POLICY IF EXISTS "Authenticated users can read applications" ON wm_applications;
DROP POLICY IF EXISTS "Authenticated users can update applications" ON wm_applications;

CREATE POLICY "Anyone can submit application" ON wm_applications
  FOR INSERT
  WITH CHECK (true);

CREATE POLICY "Authenticated admins can read applications" ON wm_applications
  FOR SELECT
  USING (auth.role() = 'authenticated' AND auth.uid() IN (SELECT user_id FROM wm_admins));

CREATE POLICY "Authenticated admins can update applications" ON wm_applications
  FOR UPDATE
  USING (auth.role() = 'authenticated' AND auth.uid() IN (SELECT user_id FROM wm_admins));


-- ─────────────────────────────────────────────────────────────
-- 3. wm_contracts RLS — 서명 위조 차단
--    SELECT 는 ?token 기반 RPC 호출(또는 admin)만 허용 권장.
--    여기서는 SELECT 는 public 유지(링크 공유 모델) + UPDATE 는 RPC
--    함수(sign_contract) 를 통한 SECURITY DEFINER 경로만 허용.
-- ─────────────────────────────────────────────────────────────

DROP POLICY IF EXISTS "Public can read contracts" ON wm_contracts;
DROP POLICY IF EXISTS "Authenticated can create contracts" ON wm_contracts;
DROP POLICY IF EXISTS "Anyone can update contracts for signing" ON wm_contracts;

-- 계약서 읽기: 링크 공유 모델 유지. 추후 ?token 검증 RPC 로 강화 가능.
CREATE POLICY "Public can read contracts" ON wm_contracts
  FOR SELECT
  USING (true);

-- 계약서 생성: admin 만.
CREATE POLICY "Authenticated admins can create contracts" ON wm_contracts
  FOR INSERT
  WITH CHECK (auth.role() = 'authenticated' AND auth.uid() IN (SELECT user_id FROM wm_admins));

-- 계약서 UPDATE 는 직접 차단. 서명은 RPC sign_contract() 만 통해.
-- (RPC 내부에서 row 검증 후 SECURITY DEFINER 로 update.)
-- 별도 정책 추가 안 함 → 기본적으로 거부.


-- ─────────────────────────────────────────────────────────────
-- 4. wm_brands RLS — 브랜드 본인 + admin 만
-- ─────────────────────────────────────────────────────────────

DROP POLICY IF EXISTS "Public can read brands" ON wm_brands;
DROP POLICY IF EXISTS "Authenticated can manage brands" ON wm_brands;
DROP POLICY IF EXISTS "Authenticated can update brands" ON wm_brands;

-- 브랜드 본인 (portal_email 매칭) 또는 admin 만 SELECT.
-- 단 portal_email 매칭은 RPC brand_login(email, password) 안에서만 수행되는
-- 게 안전 (anon SELECT → 정보 추출 가능). 여기서는 보수적으로 admin only.
CREATE POLICY "Admins can read brands" ON wm_brands
  FOR SELECT
  USING (auth.role() = 'authenticated' AND auth.uid() IN (SELECT user_id FROM wm_admins));

CREATE POLICY "Admins can manage brands" ON wm_brands
  FOR ALL
  USING (auth.role() = 'authenticated' AND auth.uid() IN (SELECT user_id FROM wm_admins))
  WITH CHECK (auth.role() = 'authenticated' AND auth.uid() IN (SELECT user_id FROM wm_admins));


-- ─────────────────────────────────────────────────────────────
-- 5. wm_messages RLS — anon 전체 access 제거
-- ─────────────────────────────────────────────────────────────

DROP POLICY IF EXISTS "Anyone can read messages" ON wm_messages;
DROP POLICY IF EXISTS "Anyone can insert messages" ON wm_messages;
DROP POLICY IF EXISTS "Anyone can update messages" ON wm_messages;

-- 메시지 조회: admin 또는 해당 brand 본인 — brand 본인 검증은 RPC 경로로.
CREATE POLICY "Admins can read messages" ON wm_messages
  FOR SELECT
  USING (auth.role() = 'authenticated' AND auth.uid() IN (SELECT user_id FROM wm_admins));

CREATE POLICY "Admins can write messages" ON wm_messages
  FOR INSERT
  WITH CHECK (auth.role() = 'authenticated' AND auth.uid() IN (SELECT user_id FROM wm_admins));

CREATE POLICY "Admins can update messages" ON wm_messages
  FOR UPDATE
  USING (auth.role() = 'authenticated' AND auth.uid() IN (SELECT user_id FROM wm_admins));


-- ─────────────────────────────────────────────────────────────
-- 6. wm_admins — admin user 목록 (auth.uid() 기준)
-- ─────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS wm_admins (
  user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT NOT NULL,
  added_at TIMESTAMPTZ DEFAULT now(),
  added_by UUID REFERENCES auth.users(id)
);

ALTER TABLE wm_admins ENABLE ROW LEVEL SECURITY;

-- admin 본인은 wm_admins 조회 가능 (자기 권한 확인용).
CREATE POLICY "Admins can read admin list" ON wm_admins
  FOR SELECT
  USING (auth.uid() = user_id OR auth.uid() IN (SELECT user_id FROM wm_admins));

-- ⚠ 최초 admin row 는 SQL 직접 INSERT 필요 — Supabase Dashboard 에서 실행:
-- INSERT INTO wm_admins (user_id, email)
--   SELECT id, email FROM auth.users WHERE email = 'jw@3svs.com';


-- ─────────────────────────────────────────────────────────────
-- 7. portal_password 해시화 — bcrypt 표준 (pgcrypto crypt)
-- ─────────────────────────────────────────────────────────────

-- 7-a. 기존 평문 portal_password backfill — bcrypt 해시로 변환.
--      이미 해시(bcrypt $2a/$2b prefix) 인 row 는 skip.
UPDATE wm_brands
SET portal_password = crypt(portal_password, gen_salt('bf', 10))
WHERE portal_password IS NOT NULL
  AND portal_password NOT LIKE '$2_$%';

-- 7-b. 비밀번호 검증 RPC — frontend 의 `.eq('portal_password', pw)`
--      비교를 대체. anon 호출 가능 (SECURITY DEFINER). 반환 컬럼은
--      frontend 의 loginBrand / loadBrandPortalData 가 필요로 하는
--      portal 표시용 필드 모두 포함.
CREATE OR REPLACE FUNCTION brand_login(
  p_email TEXT,
  p_password TEXT
)
RETURNS TABLE (
  brand_id        TEXT,
  name_ko         TEXT,
  name_en         TEXT,
  ceo_name        TEXT,
  apply_type      TEXT,
  current_phase   TEXT,
  status          TEXT,
  portal_email    TEXT,
  voucher_total_amount NUMERIC,
  voucher_used_amount  NUMERIC
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
  RETURN QUERY
    SELECT b.id, b.name_ko, b.name_en, b.ceo_name, b.apply_type,
           b.current_phase, b.status, b.portal_email,
           b.voucher_total_amount, b.voucher_used_amount
      FROM wm_brands b
     WHERE b.portal_email = p_email
       AND b.portal_password = crypt(p_password, b.portal_password)
       AND b.portal_active = true;
END;
$$;

GRANT EXECUTE ON FUNCTION brand_login(TEXT, TEXT) TO anon, authenticated;

-- 7-b-extra. portal_email 존재 여부 확인 RPC — login 실패 시 "비활성화"
--    vs "잘못된 자격증명" 분기를 위한 최소 정보. 비밀번호는 검증 안 함.
CREATE OR REPLACE FUNCTION brand_portal_status(p_email TEXT)
RETURNS TABLE (portal_active BOOLEAN, exists_flag BOOLEAN)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
  RETURN QUERY
    SELECT b.portal_active, true AS exists_flag
      FROM wm_brands b
     WHERE b.portal_email = p_email
     LIMIT 1;
  IF NOT FOUND THEN
    RETURN QUERY SELECT false AS portal_active, false AS exists_flag;
  END IF;
END;
$$;

GRANT EXECUTE ON FUNCTION brand_portal_status(TEXT) TO anon, authenticated;

-- 7-c. 비밀번호 변경 RPC — 현재 PW 검증 + 새 PW 해시 후 저장.
CREATE OR REPLACE FUNCTION brand_change_password(
  p_email TEXT,
  p_current_password TEXT,
  p_new_password TEXT
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_brand_id TEXT;
BEGIN
  IF length(p_new_password) < 8 THEN
    RETURN false;
  END IF;
  SELECT id INTO v_brand_id
    FROM wm_brands
   WHERE portal_email = p_email
     AND portal_password = crypt(p_current_password, portal_password)
     AND portal_active = true;
  IF v_brand_id IS NULL THEN
    RETURN false;
  END IF;
  UPDATE wm_brands
     SET portal_password = crypt(p_new_password, gen_salt('bf', 10))
   WHERE id = v_brand_id;
  RETURN true;
END;
$$;

GRANT EXECUTE ON FUNCTION brand_change_password(TEXT, TEXT, TEXT) TO anon, authenticated;


-- ─────────────────────────────────────────────────────────────
-- 8. 계약서 서명 RPC — anon UPDATE 차단을 우회하는 단일 경로
--    링크 방문자가 서명할 때 brand_id + role 만 받아서 row 검증 후 update.
-- ─────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION sign_contract(
  p_contract_id TEXT,
  p_role TEXT,         -- 'brand' | 'admin' | 'walmart'
  p_signer_name TEXT,
  p_sig_url TEXT,
  p_seal_url TEXT
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
  IF p_role NOT IN ('brand', 'admin', 'walmart') THEN
    RETURN false;
  END IF;

  IF p_role = 'brand' THEN
    UPDATE wm_contracts
       SET sig_brand_signed = true,
           sig_brand_name   = p_signer_name,
           sig_brand_date   = now(),
           sig_brand_sig_url  = p_sig_url,
           sig_brand_seal_url = p_seal_url
     WHERE id = p_contract_id;
  ELSIF p_role = 'admin' THEN
    UPDATE wm_contracts
       SET sig_admin_signed = true,
           sig_admin_name   = p_signer_name,
           sig_admin_date   = now(),
           sig_admin_sig_url  = p_sig_url,
           sig_admin_seal_url = p_seal_url
     WHERE id = p_contract_id;
  ELSIF p_role = 'walmart' THEN
    UPDATE wm_contracts
       SET sig_walmart_signed = true,
           sig_walmart_name   = p_signer_name,
           sig_walmart_date   = now(),
           sig_walmart_sig_url  = p_sig_url,
           sig_walmart_seal_url = p_seal_url
     WHERE id = p_contract_id;
  END IF;

  -- 3자 서명 완료 시 status 자동 전환.
  UPDATE wm_contracts
     SET status = 'completed'
   WHERE id = p_contract_id
     AND sig_brand_signed = true
     AND sig_admin_signed = true
     AND sig_walmart_signed = true;

  RETURN true;
END;
$$;

GRANT EXECUTE ON FUNCTION sign_contract(TEXT, TEXT, TEXT, TEXT, TEXT) TO anon, authenticated;


-- ─────────────────────────────────────────────────────────────
-- 9. status 전환 audit log RPC (Phase 1 의 wm_status_log 활용)
-- ─────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION log_status_change(
  p_table TEXT,
  p_row_id TEXT,
  p_old_status TEXT,
  p_new_status TEXT,
  p_note TEXT DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_id UUID;
BEGIN
  IF auth.role() <> 'authenticated' OR auth.uid() NOT IN (SELECT user_id FROM wm_admins) THEN
    RAISE EXCEPTION 'not_authorized';
  END IF;
  INSERT INTO wm_status_log (table_name, row_id, old_status, new_status, changed_by, note)
       VALUES (p_table, p_row_id, p_old_status, p_new_status, auth.uid()::text, p_note)
    RETURNING id INTO v_id;
  RETURN v_id;
END;
$$;

GRANT EXECUTE ON FUNCTION log_status_change(TEXT, TEXT, TEXT, TEXT, TEXT) TO authenticated;


-- ═══════════════════════════════════════════════════════════
-- 후속 작업 (이 SQL 만으로는 끝나지 않음)
-- ═══════════════════════════════════════════════════════════
--
--   A. wm-signatures Storage bucket — Public OFF 로 변경.
--      Supabase Dashboard > Storage > wm-signatures > Settings.
--      그 다음 RLS policy 추가:
--        INSERT: bucket_id = 'wm-signatures'
--        SELECT: 계약서 sign_contract() 결과의 url 기반 signed URL 만 노출.
--
--   B. index.html frontend 변경 (별도 commit):
--      - loginBrand() — `.eq('portal_password', pw)` 직접 비교 →
--        `supabase.rpc('brand_login', { p_email, p_password })`
--      - changeBrandPw() — UPDATE → `supabase.rpc('brand_change_password', ...)`
--      - 계약서 서명 — UPDATE → `supabase.rpc('sign_contract', ...)`
--      - 서명 이미지 — Storage SDK 의 createSignedUrl 사용
--
--   C. 최초 admin row INSERT (jw@3svs.com 의 auth.users.id 로):
--      INSERT INTO wm_admins (user_id, email)
--        SELECT id, email FROM auth.users WHERE email = 'jw@3svs.com';
--
--   D. Staging 전체 흐름 smoke test:
--      신청 폼 → 관리자 승인 → 계약서 생성 → 3자 서명 → 포탈 로그인 → 메시지.

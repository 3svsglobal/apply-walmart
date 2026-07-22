-- 2026-07-22 보안 마이그레이션 (S1): 비밀번호 해싱 + 잠금 시크릿 테이블 + 서버측 검증 RPC
-- 목적: anon 키로 평문 비밀번호를 조회할 수 있던 취약점 제거.
-- 방식: 추가(additive). 기존 password/portal_password 컬럼은 이 단계에서 건드리지 않음(최종 확인 후 별도 비움).

CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- ── 1) 잠금 시크릿 테이블 (anon 접근 불가) ──
CREATE TABLE IF NOT EXISTS wm_staff_secrets (
  account_id UUID PRIMARY KEY REFERENCES wm_staff_accounts(id) ON DELETE CASCADE,
  pw_hash TEXT NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT now()
);
CREATE TABLE IF NOT EXISTS wm_brand_secrets (
  brand_id TEXT PRIMARY KEY REFERENCES wm_brands(id) ON DELETE CASCADE,
  pw_hash TEXT NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT now()
);
ALTER TABLE wm_staff_secrets ENABLE ROW LEVEL SECURITY;
ALTER TABLE wm_brand_secrets ENABLE ROW LEVEL SECURITY;
-- RLS 정책 없음 + grant 회수 → anon/authenticated 는 직접 읽기/쓰기 불가. SECURITY DEFINER 함수만 접근.
REVOKE ALL ON wm_staff_secrets FROM anon, authenticated;
REVOKE ALL ON wm_brand_secrets FROM anon, authenticated;

-- ── 2) 기존 평문 비밀번호를 해싱하여 시크릿 테이블로 이관 (bcrypt) ──
INSERT INTO wm_staff_secrets (account_id, pw_hash)
  SELECT id, crypt(password, gen_salt('bf'))
  FROM wm_staff_accounts
  WHERE password IS NOT NULL AND password <> ''
ON CONFLICT (account_id) DO UPDATE SET pw_hash = EXCLUDED.pw_hash, updated_at = now();

INSERT INTO wm_brand_secrets (brand_id, pw_hash)
  SELECT id, crypt(portal_password, gen_salt('bf'))
  FROM wm_brands
  WHERE portal_password IS NOT NULL AND portal_password <> ''
ON CONFLICT (brand_id) DO UPDATE SET pw_hash = EXCLUDED.pw_hash, updated_at = now();

-- ── 3) 서버측 로그인 RPC (SECURITY DEFINER) ──
CREATE OR REPLACE FUNCTION wm_login_staff(p_input TEXT, p_pw TEXT)
RETURNS TABLE(id UUID, username TEXT, role TEXT, name TEXT, email TEXT)
LANGUAGE sql SECURITY DEFINER SET search_path = public, extensions AS $$
  SELECT a.id, a.username, a.role, a.name, a.email
  FROM wm_staff_accounts a
  JOIN wm_staff_secrets s ON s.account_id = a.id
  WHERE (a.username = p_input OR a.email = p_input)
    AND a.active = true
    AND s.pw_hash = crypt(p_pw, s.pw_hash)
  LIMIT 1;
$$;

CREATE OR REPLACE FUNCTION wm_login_brand(p_email TEXT, p_pw TEXT)
RETURNS TABLE(id TEXT, name_ko TEXT, name_en TEXT, apply_type TEXT, current_phase TEXT, portal_email TEXT, portal_active BOOLEAN)
LANGUAGE sql SECURITY DEFINER SET search_path = public, extensions AS $$
  SELECT b.id, b.name_ko, b.name_en, b.apply_type, b.current_phase, b.portal_email, b.portal_active
  FROM wm_brands b
  JOIN wm_brand_secrets s ON s.brand_id = b.id
  WHERE b.portal_email = p_email
    AND b.portal_active = true
    AND s.pw_hash = crypt(p_pw, s.pw_hash)
  LIMIT 1;
$$;

-- ── 4) 비밀번호 설정 RPC ──
CREATE OR REPLACE FUNCTION wm_set_staff_pw(p_account_id UUID, p_pw TEXT)
RETURNS void LANGUAGE sql SECURITY DEFINER SET search_path = public, extensions AS $$
  INSERT INTO wm_staff_secrets(account_id, pw_hash, updated_at)
  VALUES (p_account_id, crypt(p_pw, gen_salt('bf')), now())
  ON CONFLICT (account_id) DO UPDATE SET pw_hash = EXCLUDED.pw_hash, updated_at = now();
$$;

CREATE OR REPLACE FUNCTION wm_set_brand_pw(p_brand_id TEXT, p_pw TEXT)
RETURNS void LANGUAGE sql SECURITY DEFINER SET search_path = public, extensions AS $$
  INSERT INTO wm_brand_secrets(brand_id, pw_hash, updated_at)
  VALUES (p_brand_id, crypt(p_pw, gen_salt('bf')), now())
  ON CONFLICT (brand_id) DO UPDATE SET pw_hash = EXCLUDED.pw_hash, updated_at = now();
$$;

-- 브랜드 자가 변경(기존 비번 검증 후 변경)
CREATE OR REPLACE FUNCTION wm_change_brand_pw(p_email TEXT, p_old TEXT, p_new TEXT)
RETURNS BOOLEAN LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, extensions AS $$
DECLARE v_id TEXT;
BEGIN
  SELECT b.id INTO v_id FROM wm_brands b JOIN wm_brand_secrets s ON s.brand_id = b.id
   WHERE b.portal_email = p_email AND s.pw_hash = crypt(p_old, s.pw_hash) LIMIT 1;
  IF v_id IS NULL THEN RETURN false; END IF;
  UPDATE wm_brand_secrets SET pw_hash = crypt(p_new, gen_salt('bf')), updated_at = now() WHERE brand_id = v_id;
  RETURN true;
END; $$;

GRANT EXECUTE ON FUNCTION wm_login_staff(TEXT,TEXT), wm_login_brand(TEXT,TEXT), wm_set_staff_pw(UUID,TEXT), wm_set_brand_pw(TEXT,TEXT), wm_change_brand_pw(TEXT,TEXT,TEXT) TO anon, authenticated;

NOTIFY pgrst, 'reload schema';

-- ── 검증: 모든 계정의 해시가 원본 컬럼과 일치하는지 ──
SELECT 'staff' AS kind, a.username AS who, (s.pw_hash = crypt(a.password, s.pw_hash)) AS hash_ok
  FROM wm_staff_accounts a JOIN wm_staff_secrets s ON s.account_id = a.id
UNION ALL
SELECT 'brand', b.portal_email, (s.pw_hash = crypt(b.portal_password, s.pw_hash))
  FROM wm_brands b JOIN wm_brand_secrets s ON s.brand_id = b.id
ORDER BY kind, who;

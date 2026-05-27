-- 관리자/Walmart 스태프 계정 테이블
CREATE TABLE IF NOT EXISTS wm_staff_accounts (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  created_at TIMESTAMPTZ DEFAULT now(),
  username TEXT UNIQUE NOT NULL,     -- 로그인 ID (이메일 또는 username)
  password TEXT NOT NULL,            -- 평문 (추후 해싱 검토)
  role TEXT NOT NULL CHECK (role IN ('admin','walmart')),
  name TEXT,
  email TEXT,
  active BOOLEAN DEFAULT true,
  last_login_at TIMESTAMPTZ,
  notes TEXT
);

CREATE INDEX IF NOT EXISTS idx_wm_staff_username ON wm_staff_accounts(username);
CREATE INDEX IF NOT EXISTS idx_wm_staff_role ON wm_staff_accounts(role);

ALTER TABLE wm_staff_accounts ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "wm_staff_all" ON wm_staff_accounts;
CREATE POLICY "wm_staff_all" ON wm_staff_accounts FOR ALL USING (true) WITH CHECK (true);

-- 초기 시드: 기존 3SVS 관리자 (3svs2026) + Walmart 측 Louis
INSERT INTO wm_staff_accounts (username, password, role, name, email)
VALUES
  ('jw',    '3svs2026', 'admin',   'JB 관리자 (3SVS)',           'jw@3svs.com'),
  ('admin', '3svs2026', 'admin',   '관리자 (alias)',              'jw@3svs.com'),
  ('louis', '123456',   'walmart', 'Louis Diesel (Startup Junkie)', 'louis@startupjunkieconsulting.com')
ON CONFLICT (username) DO UPDATE SET
  password = EXCLUDED.password,
  role     = EXCLUDED.role,
  name     = EXCLUDED.name,
  email    = EXCLUDED.email,
  active   = true;

-- 검증
SELECT username, role, name, active FROM wm_staff_accounts ORDER BY role, username;

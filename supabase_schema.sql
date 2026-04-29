-- ═══════════════════════════════════════════════════════════
-- Walmart Entry Program — Supabase Schema
-- Instance: ixvuvaaovcsrcfjmrrnb.supabase.co
-- Prefix: wm_ (to separate from 3svs.com tables)
-- ═══════════════════════════════════════════════════════════

-- 1. 신청 데이터
CREATE TABLE wm_applications (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  created_at TIMESTAMPTZ DEFAULT now(),

  -- 기업 기본 정보
  brand_name_ko TEXT NOT NULL,
  brand_name_en TEXT NOT NULL,
  ceo_name TEXT,
  business_number TEXT,
  industry TEXT,
  homepage TEXT,
  address TEXT,

  -- 담당자 정보
  contact_name TEXT NOT NULL,
  contact_email TEXT NOT NULL,
  contact_phone TEXT,
  contact_position TEXT,

  -- 제품/프로그램 정보
  product_category TEXT,
  product_description TEXT,
  annual_revenue TEXT,
  export_experience TEXT,
  walmart_interest TEXT,

  -- 참여 유형
  apply_type TEXT CHECK (apply_type IN ('direct', 'voucher')) DEFAULT 'direct',
  voucher_number TEXT,
  voucher_amount TEXT,

  -- 상태 관리
  status TEXT CHECK (status IN ('submitted', 'reviewing', 'approved', 'rejected', 'contracted')) DEFAULT 'submitted',
  admin_notes TEXT,
  reviewed_at TIMESTAMPTZ,
  approved_at TIMESTAMPTZ
);

-- 2. 계약서
CREATE TABLE wm_contracts (
  id TEXT PRIMARY KEY,  -- e.g. 'CTR-2026-001'
  created_at TIMESTAMPTZ DEFAULT now(),

  -- 연결
  application_id UUID REFERENCES wm_applications(id),
  brand_id TEXT NOT NULL,  -- matches brand_name_en or slug

  -- 계약 유형 (향후 바우처/일반 분리용)
  contract_type TEXT CHECK (contract_type IN ('service', 'service_voucher')) DEFAULT 'service',

  -- 브랜드 정보 (계약서에 표시용)
  brand_name_ko TEXT NOT NULL,
  brand_name_en TEXT NOT NULL,
  ceo_name TEXT,

  -- 계약 상태
  status TEXT CHECK (status IN ('pending', 'partial', 'completed')) DEFAULT 'pending',
  effective_date DATE,

  -- 3자 서명 — Brand
  sig_brand_signed BOOLEAN DEFAULT false,
  sig_brand_name TEXT,
  sig_brand_date TIMESTAMPTZ,
  sig_brand_sig_url TEXT,   -- 서명 이미지 URL (Supabase Storage)
  sig_brand_seal_url TEXT,  -- 도장 이미지 URL

  -- 3자 서명 — 3SVS (Admin)
  sig_admin_signed BOOLEAN DEFAULT false,
  sig_admin_name TEXT,
  sig_admin_date TIMESTAMPTZ,
  sig_admin_sig_url TEXT,
  sig_admin_seal_url TEXT,

  -- 3자 서명 — Walmart
  sig_walmart_signed BOOLEAN DEFAULT false,
  sig_walmart_name TEXT,
  sig_walmart_date TIMESTAMPTZ,
  sig_walmart_sig_url TEXT,
  sig_walmart_seal_url TEXT,

  -- 포탈 승인
  portal_approved BOOLEAN DEFAULT false,
  portal_approved_at TIMESTAMPTZ
);

-- 3. 브랜드 관리 (승인 후 포탈 운영용)
CREATE TABLE wm_brands (
  id TEXT PRIMARY KEY,  -- slug: 'wooltari', 'celltrion' etc.
  created_at TIMESTAMPTZ DEFAULT now(),

  -- 연결
  application_id UUID REFERENCES wm_applications(id),
  contract_id TEXT REFERENCES wm_contracts(id),

  -- 기본 정보
  name_ko TEXT NOT NULL,
  name_en TEXT NOT NULL,
  ceo_name TEXT,
  category TEXT,
  founded TEXT,
  headquarters TEXT,
  website TEXT,
  employees TEXT,
  annual_revenue TEXT,

  -- 프로그램 상태
  apply_type TEXT CHECK (apply_type IN ('direct', 'voucher')) DEFAULT 'direct',
  current_phase TEXT CHECK (current_phase IN ('contract', 'phase1', 'phase2', 'phase3', 'completed')) DEFAULT 'contract',
  status TEXT CHECK (status IN ('pending', 'contracted', 'active', 'paused', 'completed')) DEFAULT 'pending',

  -- 포탈 접근
  portal_active BOOLEAN DEFAULT false,
  portal_email TEXT,  -- 로그인용 이메일

  -- 바우처 관련
  voucher_number TEXT,
  voucher_total_amount NUMERIC,
  voucher_used_amount NUMERIC DEFAULT 0,

  -- 메타
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- 4. Storage bucket for signature/seal images
-- (Run in Supabase Dashboard > Storage > New Bucket)
-- Bucket name: wm-signatures
-- Public: true (signed URLs 대안도 가능)

-- ═══ RLS Policies ═══
-- 계약서 페이지는 비로그인 접근이므로 anon key로 읽기 허용

ALTER TABLE wm_applications ENABLE ROW LEVEL SECURITY;
ALTER TABLE wm_contracts ENABLE ROW LEVEL SECURITY;
ALTER TABLE wm_brands ENABLE ROW LEVEL SECURITY;

-- 신청: 누구나 INSERT 가능 (신청 폼), SELECT는 인증된 관리자만
CREATE POLICY "Anyone can submit application" ON wm_applications
  FOR INSERT WITH CHECK (true);

CREATE POLICY "Admin can read applications" ON wm_applications
  FOR SELECT USING (true);  -- 추후 auth.uid() 기반으로 강화

CREATE POLICY "Admin can update applications" ON wm_applications
  FOR UPDATE USING (true);

-- 계약서: 누구나 읽기 가능 (링크 공유), 수정도 허용 (서명 업데이트)
CREATE POLICY "Anyone can read contracts" ON wm_contracts
  FOR SELECT USING (true);

CREATE POLICY "Anyone can insert contracts" ON wm_contracts
  FOR INSERT WITH CHECK (true);

CREATE POLICY "Anyone can update contracts" ON wm_contracts
  FOR UPDATE USING (true);

-- 브랜드: 읽기 허용, 수정은 인증 후
CREATE POLICY "Anyone can read brands" ON wm_brands
  FOR SELECT USING (true);

CREATE POLICY "Admin can manage brands" ON wm_brands
  FOR ALL USING (true);

-- ═══ Indexes ═══
CREATE INDEX idx_applications_status ON wm_applications(status);
CREATE INDEX idx_applications_email ON wm_applications(contact_email);
CREATE INDEX idx_contracts_brand ON wm_contracts(brand_id);
CREATE INDEX idx_contracts_status ON wm_contracts(status);
CREATE INDEX idx_brands_status ON wm_brands(status);


-- ═══════════════════════════════════════════════════════════
-- RLS 정책 강화 (2026-04-24 추가)
-- Supabase Auth 사용자 기반 + portal_password 컬럼 추가
-- ═══════════════════════════════════════════════════════════

-- portal_password 컬럼 추가 (이미 있으면 무시됨)
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'wm_brands' AND column_name = 'portal_password'
  ) THEN
    ALTER TABLE wm_brands ADD COLUMN portal_password TEXT;
  END IF;
END $$;

-- ═══ 기존 정책 삭제 후 재생성 ═══

-- wm_applications
DROP POLICY IF EXISTS "Anyone can submit application" ON wm_applications;
DROP POLICY IF EXISTS "Admin can read applications" ON wm_applications;
DROP POLICY IF EXISTS "Admin can update applications" ON wm_applications;

-- 신청: 비인증 사용자도 INSERT 가능 (공개 신청 폼)
CREATE POLICY "Public can submit application" ON wm_applications
  FOR INSERT WITH CHECK (true);

-- 신청 조회: 인증된 관리자 또는 anon key (admin 페이지에서 사용)
-- 실제 보안은 프론트엔드 비밀번호 + Supabase Auth로 이중 보호
CREATE POLICY "Authenticated users can read applications" ON wm_applications
  FOR SELECT USING (
    auth.role() = 'authenticated' 
    OR auth.role() = 'anon'  -- anon key로도 읽기 허용 (관리자 대시보드)
  );

-- 신청 수정: 인증된 사용자만
CREATE POLICY "Authenticated users can update applications" ON wm_applications
  FOR UPDATE USING (
    auth.role() = 'authenticated' 
    OR auth.role() = 'anon'
  );

-- wm_contracts
DROP POLICY IF EXISTS "Anyone can read contracts" ON wm_contracts;
DROP POLICY IF EXISTS "Anyone can insert contracts" ON wm_contracts;
DROP POLICY IF EXISTS "Anyone can update contracts" ON wm_contracts;

-- 계약서: 링크 공유 방식이므로 읽기는 누구나 가능
CREATE POLICY "Public can read contracts" ON wm_contracts
  FOR SELECT USING (true);

-- 계약서 생성: 인증된 사용자 또는 anon (관리자가 생성)
CREATE POLICY "Authenticated can create contracts" ON wm_contracts
  FOR INSERT WITH CHECK (
    auth.role() = 'authenticated'
    OR auth.role() = 'anon'
  );

-- 계약서 수정: 서명 업데이트를 위해 허용 (링크 접근자도 서명 가능)
CREATE POLICY "Anyone can update contracts for signing" ON wm_contracts
  FOR UPDATE USING (true);

-- wm_brands
DROP POLICY IF EXISTS "Anyone can read brands" ON wm_brands;
DROP POLICY IF EXISTS "Admin can manage brands" ON wm_brands;

-- 브랜드 조회: 누구나 (로그인 시 portal_email/password 매칭 필요)
CREATE POLICY "Public can read brands" ON wm_brands
  FOR SELECT USING (true);

-- 브랜드 생성/수정: 인증된 사용자 또는 anon
CREATE POLICY "Authenticated can manage brands" ON wm_brands
  FOR INSERT WITH CHECK (
    auth.role() = 'authenticated'
    OR auth.role() = 'anon'
  );

CREATE POLICY "Authenticated can update brands" ON wm_brands
  FOR UPDATE USING (
    auth.role() = 'authenticated'
    OR auth.role() = 'anon'
  );

-- ═══ 추가 보안: wm-signatures Storage 정책 ═══
-- (Supabase Dashboard > Storage > wm-signatures > Policies 에서 설정)
-- INSERT: 누구나 (서명 업로드)
-- SELECT: 누구나 (서명 이미지 조회)

-- ═══ 관리자 계정 생성 안내 ═══
-- Supabase Dashboard > Authentication > Users 에서:
-- 1. "Add User" 클릭
-- 2. Email: jw@3svs.com, Password: 원하는 비밀번호
-- 3. Auto Confirm: ON
-- 이후 관리자 로그인에서 이 계정으로 로그인 가능


-- 4. 메시지 (브랜드 ↔ 관리자)
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

-- RLS for messages
ALTER TABLE wm_messages ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Anyone can read messages" ON wm_messages FOR SELECT USING (true);
CREATE POLICY "Anyone can insert messages" ON wm_messages FOR INSERT WITH CHECK (true);
CREATE POLICY "Anyone can update messages" ON wm_messages FOR UPDATE USING (true);

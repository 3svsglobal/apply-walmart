-- 브랜드 포탈 v2: 할일 + 미팅 + 카테고리 서류 테이블

-- 1) 할일 목록 (관리자가 생성 → 브랜드가 확인/완료)
CREATE TABLE IF NOT EXISTS wm_tasks (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  created_at TIMESTAMPTZ DEFAULT now(),
  brand_id TEXT REFERENCES wm_brands(id) ON DELETE CASCADE,
  created_by TEXT,                          -- 'admin' | 'brand'
  title TEXT NOT NULL,
  description TEXT,
  category TEXT,                            -- 'walmart' | '3svs' | 'internal' | 'compliance' | 'general'
  priority TEXT DEFAULT 'normal',           -- 'urgent' | 'high' | 'normal' | 'low'
  due_date DATE,
  status TEXT DEFAULT 'open',               -- 'open' | 'in_progress' | 'completed' | 'cancelled'
  completed_at TIMESTAMPTZ,
  completed_by TEXT,
  notes TEXT
);

CREATE INDEX IF NOT EXISTS idx_wm_tasks_brand ON wm_tasks(brand_id);
CREATE INDEX IF NOT EXISTS idx_wm_tasks_status ON wm_tasks(status);

ALTER TABLE wm_tasks ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "wm_tasks_all" ON wm_tasks;
CREATE POLICY "wm_tasks_all" ON wm_tasks FOR ALL USING (true) WITH CHECK (true);

-- 2) 미팅 일정 (제안 → 확정/거절)
CREATE TABLE IF NOT EXISTS wm_meetings (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  created_at TIMESTAMPTZ DEFAULT now(),
  brand_id TEXT REFERENCES wm_brands(id) ON DELETE CASCADE,
  proposed_by TEXT,                         -- 'admin' | 'brand'
  title TEXT NOT NULL,
  agenda TEXT,
  scheduled_at TIMESTAMPTZ,                 -- 확정된 일정
  proposed_slots JSONB,                     -- [{at: ISO, duration_min: 30}, ...] 후보 시간
  duration_min INTEGER DEFAULT 30,
  meeting_url TEXT,                         -- Zoom/Meet/etc
  location TEXT,                            -- 오프라인일 경우
  attendees JSONB,                          -- [{name, email, role}]
  status TEXT DEFAULT 'proposed',           -- 'proposed' | 'confirmed' | 'declined' | 'rescheduled' | 'completed' | 'cancelled'
  notes TEXT
);

CREATE INDEX IF NOT EXISTS idx_wm_meetings_brand ON wm_meetings(brand_id);
CREATE INDEX IF NOT EXISTS idx_wm_meetings_status ON wm_meetings(status);
CREATE INDEX IF NOT EXISTS idx_wm_meetings_scheduled ON wm_meetings(scheduled_at);

ALTER TABLE wm_meetings ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "wm_meetings_all" ON wm_meetings;
CREATE POLICY "wm_meetings_all" ON wm_meetings FOR ALL USING (true) WITH CHECK (true);

-- 3) 카테고리 서류함 (월마트 요청 / 3SVS 요청 / 자체 자료 등)
CREATE TABLE IF NOT EXISTS wm_documents (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  created_at TIMESTAMPTZ DEFAULT now(),
  brand_id TEXT REFERENCES wm_brands(id) ON DELETE CASCADE,
  category TEXT NOT NULL,                   -- 'walmart_request' | '3svs_request' | 'compliance' | 'product_spec' | 'general'
  doc_type TEXT,                            -- 'sku_list' | 'certificate' | 'spec_sheet' | 'image_pack' | 'pricing' | 'other'
  name TEXT NOT NULL,                       -- 사용자 표시 이름
  description TEXT,                         -- 요청 이유, 참고 메모
  file_url TEXT,                            -- Storage URL
  file_size INTEGER,
  file_mime TEXT,
  uploaded_by TEXT,                         -- 'admin' | 'brand'
  uploaded_by_name TEXT,
  requested_by TEXT,                        -- '월마트' | '3SVS' | '자체' | etc
  requested_at TIMESTAMPTZ,
  status TEXT DEFAULT 'uploaded',           -- 'requested' | 'uploaded' | 'reviewed' | 'rejected' | 'approved'
  review_notes TEXT
);

CREATE INDEX IF NOT EXISTS idx_wm_documents_brand ON wm_documents(brand_id);
CREATE INDEX IF NOT EXISTS idx_wm_documents_category ON wm_documents(category);
CREATE INDEX IF NOT EXISTS idx_wm_documents_status ON wm_documents(status);

ALTER TABLE wm_documents ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "wm_documents_all" ON wm_documents;
CREATE POLICY "wm_documents_all" ON wm_documents FOR ALL USING (true) WITH CHECK (true);

-- 검증
SELECT 'wm_tasks' AS table_name, count(*) AS row_count FROM wm_tasks
UNION ALL
SELECT 'wm_meetings', count(*) FROM wm_meetings
UNION ALL
SELECT 'wm_documents', count(*) FROM wm_documents;

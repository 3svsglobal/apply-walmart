-- 2026-05-28 실전 런칭 전 테스트 데이터 일괄 삭제
-- 보존: wm_staff_accounts (jw, admin, louis)
-- 삭제: 신청/브랜드/계약/메시지/할일/미팅/문서/audit/OTP 전부

-- 1) FK 의존성 순서로 자식 테이블부터 삭제
DELETE FROM wm_contract_audit;
DELETE FROM wm_otp_codes;
DELETE FROM wm_messages;
DELETE FROM wm_tasks;
DELETE FROM wm_meetings;
DELETE FROM wm_documents;
DELETE FROM wm_contracts;

-- 2) brand 삭제 (CASCADE로 자식 행 함께 정리)
DELETE FROM wm_brands;

-- 3) 신청 삭제
DELETE FROM wm_applications;

-- 4) Storage objects 는 직접 DELETE 차단됨 → CLI로 별도 처리 (supabase storage rm)

-- 검증
SELECT 'wm_applications' AS table_name, count(*) AS rows FROM wm_applications
UNION ALL SELECT 'wm_brands', count(*) FROM wm_brands
UNION ALL SELECT 'wm_contracts', count(*) FROM wm_contracts
UNION ALL SELECT 'wm_messages', count(*) FROM wm_messages
UNION ALL SELECT 'wm_tasks', count(*) FROM wm_tasks
UNION ALL SELECT 'wm_meetings', count(*) FROM wm_meetings
UNION ALL SELECT 'wm_documents', count(*) FROM wm_documents
UNION ALL SELECT 'wm_contract_audit', count(*) FROM wm_contract_audit
UNION ALL SELECT 'wm_otp_codes', count(*) FROM wm_otp_codes
UNION ALL SELECT 'wm_staff_accounts (kept)', count(*) FROM wm_staff_accounts
ORDER BY table_name;

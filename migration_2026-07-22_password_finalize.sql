-- 2026-07-22 보안 마이그레이션 최종 단계: 평문 비밀번호 컬럼 비우기
-- 전제: 로그인/비번 변경이 모두 서버측 RPC(wm_login_*/wm_set_*)로 전환되어 라이브 검증 완료됨.
-- 효과: anon 키로 wm_staff_accounts.password / wm_brands.portal_password 를 읽어도 값이 없음.
UPDATE wm_staff_accounts SET password = NULL WHERE password IS NOT NULL;
UPDATE wm_brands SET portal_password = NULL WHERE portal_password IS NOT NULL;

-- 검증: 평문 비번이 남아있는 행 수 (0 이어야 함)
SELECT 'staff_plaintext_left' AS check, count(*) AS n FROM wm_staff_accounts WHERE password IS NOT NULL AND password <> ''
UNION ALL
SELECT 'brand_plaintext_left', count(*) FROM wm_brands WHERE portal_password IS NOT NULL AND portal_password <> '';

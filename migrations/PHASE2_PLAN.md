# Phase 2 — RLS Hardening + Password Hashing

**상태:** Plan + SQL migration sketch. **STAGING 검증 전엔 prod 머지 금지.**

## 무엇을 푸는가

Phase 1 PR 이 closing 한 CRITICAL 결함 외에, audit 의 가장 큰 위험 3개:

1. **모든 RLS 정책의 `OR auth.role() = 'anon'`** 가 사실상 RLS 를 꺼버린다 — applywalmart.info 를 방문한 누구나 anon key 로 전체 신청자/계약서/브랜드 데이터 dump 가능, 계약서 서명 위조 가능.
2. **`wm_brands.portal_password` 평문** — DB dump 가 곧 비밀번호 dump.
3. **`wm_messages`** 도 anon SELECT/INSERT/UPDATE 풀 허용 → 위조/도청 가능.

## 왜 별도 branch 인가

위 세 가지를 고치면 **신청 폼·관리자 페이지·계약서 서명·포탈 로그인·메시지** 흐름이 전부 영향받음. 잘못 들어가면 prod 가 즉시 깨짐. 그래서:

- SQL migration 은 `migrations/20260513_phase2_rls_hardening.sql` 에 분리
- frontend (index.html) 변경은 SQL 적용 후 **staging 환경에서 검증** 하고 별도 commit
- 풀 머지는 staging smoke test 통과 후 결정

## 적용 순서

### 1. STAGING Supabase 인스턴스 준비

```bash
# 기존 prod 와 분리된 staging 프로젝트 생성 (Supabase Dashboard).
# applywalmart-staging 등.
# Anon key + project ref 를 staging 용으로 별도 관리.
```

### 2. Phase 1 SQL 먼저 적용

`supabase_schema.sql` 의 `데이터 정합성 보강 (2026-05-12 추가)` 섹션을
staging dashboard SQL Editor 에서 실행. (Phase 2 가 wm_status_log /
trigger / FK 를 전제로 함.)

### 3. Phase 2 SQL 실행

`migrations/20260513_phase2_rls_hardening.sql` 전체를 SQL Editor 에서 실행.
idempotent 하지만 portal_password backfill 은 1회만 의도된 효과 (이미
해시인 row 는 skip).

### 4. 최초 admin row INSERT

```sql
INSERT INTO wm_admins (user_id, email)
  SELECT id, email FROM auth.users WHERE email = 'jw@3svs.com';
-- 필요 시 다른 admin 도 추가.
```

### 5. wm-signatures bucket 잠금

Supabase Dashboard > Storage > wm-signatures > Settings > **Public OFF**.
Policies 탭에서:

```sql
-- 업로드: 인증된 admin 만
CREATE POLICY "Admin upload signatures"
  ON storage.objects FOR INSERT
  WITH CHECK (bucket_id = 'wm-signatures'
              AND auth.uid() IN (SELECT user_id FROM wm_admins));

-- 조회: signed URL 만 허용 (별도 SELECT policy 없음 → bucket 비공개)
```

이후 frontend 는 `supabase.storage.from('wm-signatures').createSignedUrl(path, 3600)` 로 1시간 유효 URL 생성.

### 6. Frontend (index.html) 코드 변경

이 SQL 만 적용하면 **포탈 로그인이 깨짐** (frontend 가 `.eq('portal_password', pw)` 로 평문 비교 중). 다음 위치를 RPC 호출로 교체:

| 위치 (현재) | 변경 |
|---|---|
| `loginBrand` `.from('wm_brands').select('*').eq('portal_email', email).eq('portal_password', pw)` | `supabase.rpc('brand_login', { p_email: email, p_password: pw })` |
| `changeBrandPw` `.from('wm_brands').update({ portal_password: newPw })` | `supabase.rpc('brand_change_password', { p_email, p_current_password, p_new_password })` |
| 계약서 서명 `.from('wm_contracts').update({ sig_brand_signed: true, ... })` | `supabase.rpc('sign_contract', { p_contract_id, p_role, p_signer_name, p_sig_url, p_seal_url })` |
| Storage URL `.from('wm-signatures').getPublicUrl(path)` | `.from('wm-signatures').createSignedUrl(path, 3600)` |

### 7. STAGING smoke test (전부 통과해야 prod 머지)

1. 신청 폼 → 신청 row 생성 + admin 이메일 발송 확인
2. 관리자 로그인 (Supabase Auth + wm_admins) → 신청 목록 / 상세 표시 확인
3. 관리자 신청 승인 → 임시 비밀번호 발급 → 포탈 로그인 성공
4. 포탈에서 비밀번호 변경 → 새 비밀번호로 재로그인 성공
5. 계약서 생성 → 3자 서명 진행 → 모든 서명 완료 시 status='completed' 자동 전환
6. 메시지 send/receive 확인 (admin ↔ brand)
7. Anon key 로 `wm_applications` 직접 SELECT 시도 → **0 row 반환** 확인
8. Anon key 로 `wm_contracts` UPDATE 시도 → **거부** 확인

### 8. Prod 머지

1. Phase 1 PR 머지 (이미 staging 거친 정도면 prod 안전)
2. Frontend 변경 commit + push
3. Phase 2 SQL prod Supabase 에 실행
4. wm-signatures bucket prod 도 Private 전환
5. Vercel 자동 deploy
6. Prod smoke test (위 7-step 동일하게 1회 더)

## 롤백 계획

- Frontend: `git revert` 후 push → Vercel auto-deploy
- SQL: 각 정책은 `DROP POLICY` 가능. 단 portal_password 해시는 평문 복원 불가 — backup 필요 시 staging 적용 전 `wm_brands` 덤프 보관
- wm-signatures bucket: Public 토글 복원

## 위험 평가

- 가장 위험한 단계 = portal_password 해시화. 평문 복원 불가능.
- 두 번째 = RLS UPDATE 거부. 잘못된 RPC 시 계약서 서명 흐름 깨짐.
- 두 단계 모두 **staging 에서 1회 통째 reproduce 확인** 필수.

## 잡힌 결함 매핑 (audit 결과)

| Audit blocker | 해결 |
|---|---|
| RLS policy 'Anyone can update contracts' allows signature forgery | `sign_contract` RPC + UPDATE policy 제거 |
| RLS policy 'Admin can manage brands' USING (true) | `wm_admins` 검증 정책 |
| Multiple RLS `USING (true)` | 전 테이블 admin 검증 |
| `portal_password TEXT` (cleartext) | pgcrypto bcrypt + backfill |
| Public storage bucket recommended | wm-signatures Private + RLS |

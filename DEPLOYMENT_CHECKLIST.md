# 배포/운영 체크리스트 — Walmart Entry Program

> 2026-05-19 갱신. 새로운 환경에서 처음 셋업하거나, 최근 코드 변경 사항을 운영에 반영할 때 위→아래 순서로 진행.

---

## 1. DB 마이그레이션 (Supabase) — 5분

미반영 컬럼/테이블이 있어 반드시 먼저 실행해야 함.

1. https://supabase.com/dashboard/project/ixvuvaaovcsrcfjmrrnb 접속
2. **SQL Editor** → New query
3. `deploy/migration_2026-05-19.sql` 전체 내용 복사 → 붙여넣기 → **Run**
4. 마지막 SELECT 3건 결과 확인:
   - `attached_files` 컬럼 1행 반환
   - `portal_password` 컬럼 1행 반환
   - `wm_messages_exists` = 1

**선택 사항** — 신규 가입 시점이라면 `supabase_schema.sql` 전체를 먼저 한 번 실행.

---

## 2. Storage 버킷 확인 — 1분

1. Supabase Dashboard → **Storage**
2. `wm-signatures` 버킷이 있는지 확인. 없으면:
   - **New bucket** → 이름: `wm-signatures` → Public: **ON** → Create
3. 버킷 → Policies 탭에서 다음이 모두 허용되어야 함:
   - SELECT: anon, authenticated
   - INSERT: anon, authenticated

---

## 3. 관리자 계정 생성 (선택) — 2분

현재는 단일 비밀번호(`3svs2026`) 방식으로 동작하지만, Supabase Auth 전환 대비:

1. Supabase Dashboard → **Authentication** → Users → **Add User**
2. Email: `jw@3svs.com` / Password: 원하는 값
3. Auto Confirm: **ON**

---

## 4. Edge Function 배포 (이메일 알림) — 10분

### 4.1 Resend 계정 준비
1. https://resend.com 가입 (무료 월 3,000건)
2. **API Keys** → Create API Key → 키 복사
3. **Domains** → `applywalmart.info` 추가 (SPF/DKIM TXT 레코드 등록 필요)
   - 도메인 인증 전에는 `onboarding@resend.dev` 발신만 가능 (테스트용)

### 4.2 Supabase CLI 설치 & 로그인
```powershell
npm install -g supabase
supabase login
```

### 4.3 프로젝트 연결 (한 번만)
```powershell
cd C:\Users\3SVS_Jongwon\Desktop\Claude\월마트입점지원\deploy
supabase link --project-ref ixvuvaaovcsrcfjmrrnb
```

### 4.4 Secret 등록 + 함수 배포
```powershell
supabase secrets set RESEND_API_KEY=re_여기에_복사한_키
supabase functions deploy send-notification
```

### 4.5 도메인 인증 전 임시 발신 주소
`deploy/supabase/functions/send-notification/index.ts` 17번째 줄을 잠시 바꿔서 테스트:
```ts
const FROM_EMAIL = "Walmart Entry Program <onboarding@resend.dev>";
```
도메인 인증이 끝나면 다시 `noreply@applywalmart.info`로 복원하고 재배포.

### 4.6 동작 확인
1. 신청 폼에서 테스트 신청 1건 제출
2. Supabase Dashboard → **Edge Functions** → `send-notification` → Logs 확인
3. `jw@3svs.com` 메일함에 도착 확인

---

## 5. 프론트엔드 배포 (Vercel) — 2분

```powershell
cd C:\Users\3SVS_Jongwon\Desktop\Claude\월마트입점지원\deploy
git add -A
git commit -m "fix: 계약서 ID 충돌/brandSlug 충돌/이메일 템플릿 누락 수정"
git push origin main
```

배포 후 https://www.applywalmart.info 에서 실제 반영 확인.
만약 반영 안 되면 Vercel 대시보드 → 해당 deployment → **Promote to Production**.

---

## 6. E2E 동작 테스트 — 15분

배포 후 1회 처음부터 끝까지 흐름 확인.

- [ ] **신청** — `/?tab=apply`에서 더미 데이터로 신청 제출 → 관리자 화면에 노출됨
- [ ] **첨부파일** — 신청 폼에 PDF 1개 첨부 → 관리자 심사 페이지에서 다운로드 가능
- [ ] **승인** — 승인 토스트 + Supabase에 `wm_brands` 1행 추가됨
- [ ] **이메일 수신** — `application_approved` 메일이 신청자 메일로 도착 (임시 비번 포함)
- [ ] **브랜드 로그인** — 신청자 이메일 + 메일에서 받은 임시 비번으로 포탈 진입
- [ ] **세션 유지** — 새로고침 후에도 로그인 상태 유지
- [ ] **메시지** — 브랜드가 메시지 작성 → 관리자에서 보임 → 답장 → 브랜드에 표시
- [ ] **계약서 생성** — 계약 관리 탭에서 승인된 브랜드 드롭다운에 노출 → 생성 → 링크 복사
- [ ] **3자 서명** — 브랜드/3SVS/Startup Junkie 순서대로 서명 → 상태가 partial → completed로 전환
- [ ] **계약 완료 알림** — `contract_completed` 메일이 `jw@3svs.com`에 도착

---

## 7. 알려진 한계 / 향후 작업

- 관리자 인증은 단일 비밀번호(`3svs2026`) 기반 — Supabase Auth 완전 전환 대기 중
- 브랜드 임시 비밀번호는 평문 저장 — 추후 해싱 도입 검토
- 개별 SKU 단위 관리 UI 미구현 (현재 PDF 일괄 업로드 방식)
- 모바일 반응형 미완성

---

## 부록: 자주 쓰는 SQL

신청 전체 보기:
```sql
SELECT id, brand_name_ko, contact_email, status, created_at FROM wm_applications ORDER BY created_at DESC;
```

특정 브랜드 강제 비밀번호 재설정:
```sql
UPDATE wm_brands SET portal_password = 'temp1234' WHERE portal_email = '대상이메일@example.com';
```

테스트 데이터 일괄 삭제 (주의!):
```sql
DELETE FROM wm_messages WHERE brand_id IN (SELECT id FROM wm_brands WHERE name_en LIKE 'Test%');
DELETE FROM wm_brands WHERE name_en LIKE 'Test%';
DELETE FROM wm_applications WHERE brand_name_en LIKE 'Test%';
```

// Supabase Edge Function: send-notification
// 이메일 알림 발송 (Resend API 사용)
//
// 배포 방법:
// 1. Supabase CLI 설치: npm install -g supabase
// 2. supabase login
// 3. supabase link --project-ref ixvuvaaovcsrcfjmrrnb
// 4. Secrets 설정:
//    supabase secrets set RESEND_API_KEY=your_resend_api_key
//    supabase secrets set ADMIN_EMAIL=jw@3svs.com
//    supabase secrets set FROM_EMAIL="Walmart Entry Program <noreply@applywalmart.info>"
//    supabase secrets set ALLOWED_ORIGINS="https://www.applywalmart.info,https://applywalmart.info"
// 5. supabase functions deploy send-notification
//
// 보안 모델 (2026-05-12 hardening):
//   - config.toml 의 verify_jwt = true 로 anon key 미보유 요청 차단
//   - ALLOWED_ORIGINS 화이트리스트로 외부 도메인 호출 차단
//   - 이메일 템플릿의 모든 사용자 공급 필드 HTML escape 처리
//   - RESEND_API_KEY 누락 시 명시적 503 + 서버 로그
//
// Resend 가입: https://resend.com (무료 월 3,000건)

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

const RESEND_API_KEY = Deno.env.get("RESEND_API_KEY");
const ADMIN_EMAIL = Deno.env.get("ADMIN_EMAIL") ?? "jw@3svs.com";
const FROM_EMAIL =
  Deno.env.get("FROM_EMAIL") ?? "Walmart Entry Program <noreply@applywalmart.info>";

// 운영 도메인. 환경변수로 override 가능. 빈 문자열은 무시.
const ALLOWED_ORIGINS = (Deno.env.get("ALLOWED_ORIGINS") ??
  "https://www.applywalmart.info,https://applywalmart.info")
  .split(",")
  .map((s) => s.trim())
  .filter(Boolean);

interface NotificationPayload {
  type: string;
  data: {
    message?: string;
    brandName?: string;
    email?: string;
    tempPassword?: string;
    contractId?: string;
    appId?: string;
    role?: string;
  };
  timestamp: string;
}

/**
 * HTML escape — 모든 사용자 공급 필드를 이메일 템플릿에 삽입하기 전 통과.
 * 이메일 클라이언트에서 <script>/<img onerror=...> 등 실행 차단.
 */
function esc(value: unknown): string {
  if (value === undefined || value === null) return "";
  return String(value)
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#39;");
}

/**
 * Origin 허용 여부 — preflight + 정상 응답 모두에 동일 적용.
 * 허용된 origin 만 Access-Control-Allow-Origin 으로 반향, 나머지는 빈값.
 */
function resolveAllowOrigin(req: Request): string | null {
  const origin = req.headers.get("Origin");
  if (!origin) return null;
  return ALLOWED_ORIGINS.includes(origin) ? origin : null;
}

function corsHeaders(req: Request): Record<string, string> {
  const allow = resolveAllowOrigin(req);
  const base: Record<string, string> = {
    "Content-Type": "application/json",
    "Vary": "Origin",
  };
  if (allow) {
    base["Access-Control-Allow-Origin"] = allow;
    base["Access-Control-Allow-Methods"] = "POST, OPTIONS";
    base["Access-Control-Allow-Headers"] = "Content-Type, Authorization";
    base["Access-Control-Max-Age"] = "86400";
  }
  return base;
}

const emailTemplates: Record<
  string,
  (data: NotificationPayload["data"]) => { subject: string; html: string; to: string[] }
> = {
  application_submitted: (data) => ({
    subject: `[월마트 입점] 새 신청 접수 — ${esc(data.brandName) || "새 기업"}`,
    to: [ADMIN_EMAIL],
    html: `
      <div style="font-family:sans-serif;max-width:600px;margin:0 auto;padding:20px">
        <h2 style="color:#0071dc">새 입점 신청이 접수되었습니다</h2>
        <p>${esc(data.message)}</p>
        <p style="margin-top:20px">
          <a href="https://www.applywalmart.info"
             style="background:#0071dc;color:#fff;padding:12px 24px;border-radius:8px;text-decoration:none;display:inline-block">
            관리자 대시보드에서 확인
          </a>
        </p>
        <hr style="border:none;border-top:1px solid #eee;margin:24px 0">
        <p style="color:#999;font-size:12px">Walmart Entry Program by 3Stripe Venture Studio</p>
      </div>
    `,
  }),

  application_approved: (data) => ({
    subject: `[월마트 입점] 신청이 승인되었습니다 — ${esc(data.brandName)}`,
    to: [data.email || ADMIN_EMAIL],
    html: `
      <div style="font-family:sans-serif;max-width:600px;margin:0 auto;padding:20px">
        <h2 style="color:#00875a">입점 신청이 승인되었습니다!</h2>
        <p><strong>${esc(data.brandName)}</strong>님의 Walmart Marketplace 입점 프로그램 참여가 승인되었습니다.</p>
        <div style="background:#f5f5f7;padding:20px;border-radius:8px;margin:20px 0">
          <p style="margin:0 0 8px"><strong>포탈 로그인 정보:</strong></p>
          <p style="margin:0 0 4px">이메일: <code>${esc(data.email)}</code></p>
          <p style="margin:0">임시 비밀번호: <code>${esc(data.tempPassword)}</code></p>
        </div>
        <p>아래 링크에서 로그인하여 프로그램을 시작하세요.</p>
        <p style="margin-top:20px">
          <a href="https://www.applywalmart.info"
             style="background:#0071dc;color:#fff;padding:12px 24px;border-radius:8px;text-decoration:none;display:inline-block">
            포탈 로그인
          </a>
        </p>
        <p style="color:#999;font-size:13px;margin-top:16px">보안을 위해 로그인 후 비밀번호를 변경해주세요.</p>
        <hr style="border:none;border-top:1px solid #eee;margin:24px 0">
        <p style="color:#999;font-size:12px">Walmart Entry Program by 3Stripe Venture Studio</p>
      </div>
    `,
  }),

  contract_created: (data) => ({
    subject: `[월마트 입점] 계약서가 생성되었습니다 — ${esc(data.brandName)}`,
    to: [ADMIN_EMAIL],
    html: `
      <div style="font-family:sans-serif;max-width:600px;margin:0 auto;padding:20px">
        <h2 style="color:#0071dc">계약서가 생성되었습니다</h2>
        <p>계약 ID: <strong>${esc(data.contractId)}</strong></p>
        <p>브랜드: <strong>${esc(data.brandName)}</strong></p>
        <p>${esc(data.message)}</p>
        <hr style="border:none;border-top:1px solid #eee;margin:24px 0">
        <p style="color:#999;font-size:12px">Walmart Entry Program by 3Stripe Venture Studio</p>
      </div>
    `,
  }),

  contract_signed: (data) => ({
    subject: `[월마트 입점] 계약서 서명 — ${esc(data.contractId)}`,
    to: [ADMIN_EMAIL],
    html: `
      <div style="font-family:sans-serif;max-width:600px;margin:0 auto;padding:20px">
        <h2 style="color:#f0ad4e">계약서 서명 알림</h2>
        <p>${esc(data.message)}</p>
        <p style="margin-top:20px">
          <a href="https://www.applywalmart.info"
             style="background:#0071dc;color:#fff;padding:12px 24px;border-radius:8px;text-decoration:none;display:inline-block">
            서명 현황 확인
          </a>
        </p>
        <hr style="border:none;border-top:1px solid #eee;margin:24px 0">
        <p style="color:#999;font-size:12px">Walmart Entry Program by 3Stripe Venture Studio</p>
      </div>
    `,
  }),

  contract_completed: (data) => ({
    subject: `[월마트 입점] 계약 체결 완료! — ${esc(data.contractId)}`,
    to: [ADMIN_EMAIL],
    html: `
      <div style="font-family:sans-serif;max-width:600px;margin:0 auto;padding:20px">
        <h2 style="color:#00875a">🎉 계약이 체결되었습니다!</h2>
        <p>계약 ID: <strong>${esc(data.contractId)}</strong></p>
        <p>3자(브랜드, 3SVS, Startup Junkie)의 서명이 모두 완료되어 계약이 정식 체결되었습니다.</p>
        <p style="margin-top:20px">
          <a href="https://www.applywalmart.info"
             style="background:#00875a;color:#fff;padding:12px 24px;border-radius:8px;text-decoration:none;display:inline-block">
            계약 관리 페이지
          </a>
        </p>
        <hr style="border:none;border-top:1px solid #eee;margin:24px 0">
        <p style="color:#999;font-size:12px">Walmart Entry Program by 3Stripe Venture Studio</p>
      </div>
    `,
  }),
};

serve(async (req) => {
  const cors = corsHeaders(req);

  // 1. Preflight 처리. Origin 화이트리스트 통과시에만 정상 응답, 아니면 403.
  if (req.method === "OPTIONS") {
    if (cors["Access-Control-Allow-Origin"]) {
      return new Response(null, { status: 204, headers: cors });
    }
    return new Response(JSON.stringify({ error: "origin_not_allowed" }), {
      status: 403,
      headers: { "Content-Type": "application/json" },
    });
  }

  // 2. POST 외 거부.
  if (req.method !== "POST") {
    return new Response(JSON.stringify({ error: "method_not_allowed" }), {
      status: 405,
      headers: cors,
    });
  }

  // 3. Origin 검증 — verify_jwt=true 위에 한 겹 더.
  if (!cors["Access-Control-Allow-Origin"]) {
    return new Response(JSON.stringify({ error: "origin_not_allowed" }), {
      status: 403,
      headers: { "Content-Type": "application/json" },
    });
  }

  // 4. RESEND key 누락 fail-fast (예전엔 silent 200 응답).
  if (!RESEND_API_KEY) {
    console.error("send-notification: RESEND_API_KEY not configured");
    return new Response(
      JSON.stringify({ error: "email_service_unavailable" }),
      { status: 503, headers: cors },
    );
  }

  try {
    const payload: NotificationPayload = await req.json();
    const { type, data } = payload;

    const templateFn = emailTemplates[type];
    if (!templateFn) {
      return new Response(
        JSON.stringify({ error: "unknown_notification_type" }),
        { status: 400, headers: cors },
      );
    }

    const { subject, html, to } = templateFn(data);

    const emailRes = await fetch("https://api.resend.com/emails", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${RESEND_API_KEY}`,
      },
      body: JSON.stringify({ from: FROM_EMAIL, to, subject, html }),
    });

    const emailData = await emailRes.json();
    if (!emailRes.ok) {
      console.error("send-notification: Resend API error", emailData);
      return new Response(
        JSON.stringify({ error: "email_send_failed" }),
        { status: 502, headers: cors },
      );
    }

    return new Response(JSON.stringify({ success: true, emailData }), {
      headers: cors,
    });
  } catch (error) {
    console.error("send-notification: handler error", error);
    return new Response(
      JSON.stringify({ error: "internal_error" }),
      { status: 500, headers: cors },
    );
  }
});

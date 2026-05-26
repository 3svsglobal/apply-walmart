// Supabase Edge Function: send-notification
// 이메일 알림 발송 (Resend API 사용)
//
// 배포 방법:
// 1. Supabase CLI 설치: npm install -g supabase
// 2. supabase login
// 3. supabase link --project-ref ixvuvaaovcsrcfjmrrnb
// 4. supabase secrets set RESEND_API_KEY=your_resend_api_key
// 5. supabase functions deploy send-notification
//
// Resend 가입: https://resend.com (무료 월 3,000건)
// API Key 발급 후 위 4번 단계에서 설정

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

const RESEND_API_KEY = Deno.env.get("RESEND_API_KEY");
const ADMIN_EMAIL = "jw@3svs.com";
const FROM_EMAIL = "Walmart Entry Program <noreply@applywalmart.info>";

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

const emailTemplates: Record<string, (data: any) => { subject: string; html: string; to: string[] }> = {
  application_submitted: (data) => ({
    subject: `[월마트 입점] 새 신청 접수 — ${data.brandName || '새 기업'}`,
    to: [ADMIN_EMAIL],
    html: `
      <div style="font-family:sans-serif;max-width:600px;margin:0 auto;padding:20px">
        <h2 style="color:#0071dc">새 입점 신청이 접수되었습니다</h2>
        <p>${data.message || ''}</p>
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

  application_received: (data) => ({
    subject: `[월마트 입점 프로그램] ${data.brandName || '귀사'}의 신청이 정상 접수되었습니다`,
    to: [data.email || ADMIN_EMAIL],
    html: `
      <div style="font-family:sans-serif;max-width:600px;margin:0 auto;padding:20px;color:#1a1a1a">
        <h2 style="color:#0071dc;margin:0 0 8px">신청 접수 완료</h2>
        <p style="font-size:14px;color:#555;margin:0 0 24px">Walmart Entry Program — 3Stripe Venture Studio × Startup Junkie Consulting</p>
        <p><strong>${data.brandName || '귀사'}</strong>의 입점 프로그램 신청이 정상적으로 접수되었습니다. 운영팀이 2영업일 이내 검토 후 별도 안내드리겠습니다.</p>

        <div style="background:#f6f7f9;border:1px solid #e6e6ea;border-radius:8px;padding:16px 20px;margin:24px 0">
          <div style="font-size:12px;font-weight:700;color:#0071dc;margin-bottom:8px;letter-spacing:0.3px">📌 신청 내용 수정 링크</div>
          <p style="margin:0 0 12px;font-size:13px;color:#555;line-height:1.55">검토 시작 전까지 아래 링크로 신청 내용을 자유롭게 수정하실 수 있습니다. 이 링크는 본인만 접근할 수 있도록 별도 발송된 것이므로 외부 공유에 주의해 주세요.</p>
          <p style="margin:0">
            <a href="${data.editLink || 'https://www.applywalmart.info'}"
               style="background:#0071dc;color:#fff;padding:10px 18px;border-radius:6px;text-decoration:none;display:inline-block;font-size:13px;font-weight:600">
              신청 내용 수정하기 →
            </a>
          </p>
          <p style="margin:12px 0 0;font-size:11px;color:#999;word-break:break-all">${data.editLink || ''}</p>
        </div>

        <p style="font-size:13px;color:#666;line-height:1.65">실무자 미팅이 시작되면 모든 항목을 함께 점검·보완해 드리니, 지금 단계에서는 알고 계신 정보 위주로 채워주신 것만으로도 충분합니다. 문의는 <a href="mailto:jw@3svs.com" style="color:#0071dc">jw@3svs.com</a>로 부탁드립니다.</p>

        <hr style="border:none;border-top:1px solid #eee;margin:24px 0">
        <p style="color:#999;font-size:12px">Walmart Entry Program by 3Stripe Venture Studio</p>
      </div>
    `,
  }),

  application_updated: (data) => ({
    subject: `[월마트 입점] 신청 내용 수정됨 — ${data.brandName || '신청'}`,
    to: [ADMIN_EMAIL],
    html: `
      <div style="font-family:sans-serif;max-width:600px;margin:0 auto;padding:20px">
        <h2 style="color:#f0ad4e">신청 내용 수정 알림</h2>
        <p>${data.message || ''}</p>
        <p style="font-size:13px;color:#666">신청 ID: <code>${data.appId || ''}</code></p>
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
    subject: `[월마트 입점] 신청이 승인되었습니다 — ${data.brandName}`,
    to: [data.email || ADMIN_EMAIL],
    html: `
      <div style="font-family:sans-serif;max-width:600px;margin:0 auto;padding:20px">
        <h2 style="color:#00875a">입점 신청이 승인되었습니다!</h2>
        <p><strong>${data.brandName}</strong>님의 Walmart Marketplace 입점 프로그램 참여가 승인되었습니다.</p>
        <div style="background:#f5f5f7;padding:20px;border-radius:8px;margin:20px 0">
          <p style="margin:0 0 8px"><strong>포탈 로그인 정보:</strong></p>
          <p style="margin:0 0 4px">이메일: <code>${data.email}</code></p>
          <p style="margin:0">임시 비밀번호: <code>${data.tempPassword}</code></p>
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

  application_rejected: (data) => ({
    subject: `[월마트 입점] 신청 검토 결과 안내`,
    to: [data.email || ADMIN_EMAIL],
    html: `
      <div style="font-family:sans-serif;max-width:600px;margin:0 auto;padding:20px">
        <h2 style="color:#d4380d">신청 검토 결과 안내</h2>
        <p>안녕하세요,</p>
        <p>Walmart Marketplace 입점 프로그램에 관심을 가져주셔서 감사합니다.</p>
        <p>아쉽게도 이번에는 입점 승인이 어렵게 되었음을 안내드립니다.</p>
        <div style="background:#fff7e6;border-left:3px solid #f0ad4e;padding:12px 16px;border-radius:4px;margin:16px 0">
          <p style="margin:0 0 4px;font-size:13px;color:#666">검토 의견</p>
          <p style="margin:0;white-space:pre-wrap">${(data.message || '').replace(/^.*사유:\s*/, '')}</p>
        </div>
        <p>제품 라인업 보강이나 추가 자료 준비 후 재신청을 환영합니다.</p>
        <p style="margin-top:20px">
          <a href="https://www.applywalmart.info"
             style="background:#0071dc;color:#fff;padding:12px 24px;border-radius:8px;text-decoration:none;display:inline-block">
            프로그램 안내 보기
          </a>
        </p>
        <hr style="border:none;border-top:1px solid #eee;margin:24px 0">
        <p style="color:#999;font-size:12px">Walmart Entry Program by 3Stripe Venture Studio</p>
      </div>
    `,
  }),

  contract_created: (data) => ({
    subject: `[월마트 입점] 계약서가 생성되었습니다 — ${data.brandName}`,
    to: [ADMIN_EMAIL],
    html: `
      <div style="font-family:sans-serif;max-width:600px;margin:0 auto;padding:20px">
        <h2 style="color:#0071dc">계약서가 생성되었습니다</h2>
        <p>계약 ID: <strong>${data.contractId}</strong></p>
        <p>브랜드: <strong>${data.brandName}</strong></p>
        <p>${data.message || ''}</p>
        <hr style="border:none;border-top:1px solid #eee;margin:24px 0">
        <p style="color:#999;font-size:12px">Walmart Entry Program by 3Stripe Venture Studio</p>
      </div>
    `,
  }),

  contract_signed: (data) => ({
    subject: `[월마트 입점] 계약서 서명 — ${data.contractId}`,
    to: [ADMIN_EMAIL],
    html: `
      <div style="font-family:sans-serif;max-width:600px;margin:0 auto;padding:20px">
        <h2 style="color:#f0ad4e">계약서 서명 알림</h2>
        <p>${data.message || ''}</p>
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
    subject: `[월마트 입점] 계약 체결 완료! — ${data.contractId}`,
    to: [ADMIN_EMAIL],
    html: `
      <div style="font-family:sans-serif;max-width:600px;margin:0 auto;padding:20px">
        <h2 style="color:#00875a">🎉 계약이 체결되었습니다!</h2>
        <p>계약 ID: <strong>${data.contractId}</strong></p>
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
  // CORS
  if (req.method === "OPTIONS") {
    return new Response(null, {
      headers: {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Methods": "POST, OPTIONS",
        "Access-Control-Allow-Headers": "Content-Type, Authorization",
      },
    });
  }

  try {
    const payload: NotificationPayload = await req.json();
    const { type, data } = payload;

    // Get email template
    const templateFn = emailTemplates[type];
    if (!templateFn) {
      return new Response(JSON.stringify({ error: "Unknown notification type" }), {
        status: 400,
        headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
      });
    }

    const { subject, html, to } = templateFn(data);

    // Send via Resend
    if (!RESEND_API_KEY) {
      console.log("RESEND_API_KEY not set — skipping email, logging only");
      return new Response(JSON.stringify({ success: true, message: "Logged (no email API key)" }), {
        headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
      });
    }

    const emailRes = await fetch("https://api.resend.com/emails", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${RESEND_API_KEY}`,
      },
      body: JSON.stringify({
        from: FROM_EMAIL,
        to,
        subject,
        html,
      }),
    });

    const emailData = await emailRes.json();
    console.log("Email sent:", emailData);

    return new Response(JSON.stringify({ success: true, emailData }), {
      headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
    });
  } catch (error) {
    console.error("Notification error:", error);
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
    });
  }
});

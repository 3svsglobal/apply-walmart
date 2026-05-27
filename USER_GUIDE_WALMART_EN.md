# Walmart Entry Program — Buyer Portal User Guide

**For:** Startup Junkie Consulting team (US-side buyer support)
**Portal URL:** https://www.applywalmart.info
**Last updated:** 2026-05-28

---

## 1. Overview

This portal is the operational hub for the Walmart Entry Program operated jointly by **3Stripe Venture Studio** (3SVS, Korea) and **Startup Junkie Consulting** (Arkansas, US).
Korean brands apply through the public site, 3SVS handles initial review and contracting, and your team coordinates the US-side activities — buyer introductions, line reviews, P.O. management, store entry.

The portal connects three parties on shared real-time data:

```
Brand (Korea)  ───┐
                  ├──→ Same DB, same messages, same documents
3SVS Admin  ──────┤    (you see what the brand sees, and vice versa)
                  │
Startup Junkie ───┘  ← that's you
```

Anything you write (notes, tasks, meetings, document requests) is **immediately visible** to the brand and to 3SVS Admin. Conversely, you'll see brand inquiries and 3SVS notes in real time.

---

## 2. Logging in

1. Go to **https://www.applywalmart.info**
2. Click the **Log in** tab at the top
3. Select the **Walmart / Startup Junkie** login tab
4. Enter your credentials:
   - **Username:** `louis` (default account)
   - **Password:** `123456` (change immediately — see Section 9)
5. You'll land on the **Pipeline** page

> 📌 **Security note:** The default password is for first-day access only. Ask the 3SVS Admin to add an additional account or to reset your password from **Settings → Staff Accounts**.

---

## 3. The Pipeline view (your home screen)

After logging in, you see:

### 3.1 Meeting Requests Panel (top, yellow)
- Only appears when brands have submitted meeting requests awaiting confirmation.
- Each card shows the brand name, proposed title, agenda, and proposed time slots (KST).
- Three quick actions: **Confirm**, **Decline**, **View Brand**.

### 3.2 Stat summary
- Total brands · Under Review · Phase 1 / 2 / 3 counts.

### 3.3 Brand cards
- Approved brands appear as clickable cards.
- Each card shows: brand name, type (Direct / Voucher), current phase, contact email.
- **Click anywhere on the card** → opens the full brand detail page.
- **Messages button** (right side) → opens just the message thread modal.
  Red badge = unread brand messages.

To **refresh** the list, click **Pipeline** in the left sidebar again.

---

## 4. Brand Detail page

Click a brand card → you'll see 10 sections, top to bottom:

| # | Section | What it does |
|---|---------|--------------|
| 1 | **Header** | Brand name, phase, category |
| 2 | **Phase Management** | Click any of `Contract / Phase 1 / Phase 2 / Phase 3 / Completed` to change the brand's current phase. Updates instantly. Brand sees the same. |
| 3 | **Company Information** | CEO / Category / Website / Revenue / Email — from the application form |
| 4 | **🗒 Internal Notes** | **Visible to you and 3SVS Admin only. NOT shown to the brand.** Use this for contact history, negotiation notes, internal observations. Notes are tagged per phase (see Section 4.1). |
| 5 | **Tasks** | To-dos assigned to or about this brand. Phase-tagged. |
| 6 | **Meetings** | All meetings — proposed by you, by 3SVS, or by the brand |
| 7 | **Documents** | Brand-uploaded files + your document requests |
| 8 | **Application & Attachments** | The original application form data + any files the brand attached when applying |
| 9 | **Recent Messages** | Last 4 messages, with a button to open the full thread |
| 10 | **Contracts** | Service agreements for 3-party signing |

### 4.1 Phase tabs (under Notes and Tasks)

Above the Notes textarea and above the Tasks list, you'll see tabs:
`[General] [Contract] [Phase 1●] [Phase 2] [Phase 3] [Completed]`

The green dot (●) marks the brand's **current** phase.

- Click any tab → Notes textarea loads notes for that phase; Tasks list filters to that phase.
- Saving a note only affects the selected phase (others are preserved).
- When you change the brand's current phase via the buttons above, the tabs auto-jump to the new phase.

This is how you keep, for example, "Phase 2 buyer meeting prep notes" separate from "Phase 3 line-review feedback."

---

## 5. Messages — replying to brand inquiries

Click the **Messages** button on a brand card, OR the **Open / Reply** button inside the brand detail page.

A modal opens with the full conversation:
- Brand messages appear with the brand's name
- 3SVS Admin messages show "3SVS Admin"
- Your messages will be tagged "Startup Junkie"
- Times are in KST (Korean time)

Type in the input at the bottom and press **Enter** (or click **Send**). The brand sees your reply in their portal in real time, and the unread badge on their side increments.

> 🔔 When you open the modal, all unread messages from the brand are automatically marked as read on your side.

---

## 6. Creating Tasks for a brand

From the brand detail page, click **+ Add task** in the Tasks section.

Form fields:
- **Title** (required): e.g., "Submit Item 360 SKU data sheet"
- **Description** (optional): detailed instructions, links, format requirements
- **Priority**: Urgent / High / Normal / Low (color-coded)
- **Category**: Walmart / 3SVS / Compliance / Internal / General
- **Phase**: tag the task to a specific phase (or General)
- **Due date** (optional)

After submit:
- The task appears immediately in the brand's portal under their **To-do** menu
- The brand checks it off when complete
- You see the completion status update in real time

---

## 7. Proposing Meetings

Click **+ Propose meeting** in the Meetings section.

Fields:
- **Title** (required)
- **Agenda** (optional)
- **Proposed times — 1 to 3 slots** in KST (30-minute increments only)
- **Meeting URL** (optional): Zoom / Google Meet

The brand sees the proposal with up to 3 time options and picks one to confirm.

**When the brand REQUESTS a meeting** instead:
- It appears in the yellow Meeting Requests Panel on your Pipeline page
- You can **Confirm** (pick the final time), **Decline**, or click **View Brand** for full context

---

## 8. Requesting Documents

Click **+ Request document** in the Documents section.

Fields:
- **Document name**: e.g., "2026 Q3 SKU Master List"
- **Description**: format, deadline, required fields
- **Category**: Walmart Request / 3SVS Request / Compliance / Product Spec / General
- **Requested by**: 월마트 (Walmart) / 3SVS / Startup Junkie

The brand's Documents tab shows it as **Requested** status. When they upload the file, the status changes to **Uploaded**. You can then click **Approve** if it meets requirements.

---

## 9. Contracts — 3-party e-signing

When a service agreement is ready, 3SVS Admin creates a contract for the brand. You'll see it in:
1. The brand's Contracts section in their detail page, **or**
2. By clicking the **Contracts** link in the contract (admin sends URL)

The contract page has three signature sections: **Brand / 3SVS / Startup Junkie**.

To sign as Startup Junkie:
1. Click the **Sign as Startup Junkie** button in the contract list (only visible when not yet signed)
2. Scroll to the Startup Junkie signature section
3. Choose signing method:
   - **✍️ Draw**: sign with mouse/touchpad directly on the canvas
   - **🖼 Upload**: upload a pre-prepared signature image
4. Check **both consent boxes**:
   - I understand this e-signature has the same legal effect as a handwritten signature (under Korean Electronic Signature Act and US ESIGN Act)
   - I have read and understood the full agreement
5. Click **Step 1: Send OTP** — a 6-digit code is sent to your registered email
6. Enter the code (5-minute validity, max 5 attempts)
7. Click **Step 2: Sign** — your signature is locked in

> 🔒 **After signing**, your signature section becomes locked. You cannot re-sign. The lock badge "Signed · Locked" appears.

When all three parties have signed, the contract is finalized:
- A PDF is auto-generated with all signatures embedded
- SHA-256 hash is calculated and stored
- Final PDF URL is added to the contract record
- Email notification "contract_completed" is sent to admin

---

## 10. Settings — managing your account

Currently the **Settings** menu is only accessible from the 3SVS Admin side. If you need to:
- Change your password
- Add another Startup Junkie team member account
- Deactivate an account

→ Ask the 3SVS Admin (`jw@3svs.com`) to do it via:
**Admin Portal → Settings → Staff Accounts → + Add account** (or **🔑 Reset password**)

---

## 11. Language toggle

The Walmart portal is **English-only by design**. The Pipeline and brand detail pages always render in English regardless of any other state.

If you ever see Korean text, it's a bug — please report to `jw@3svs.com` with a screenshot.

---

## 12. Logout

Sidebar footer → **← Log out**

Your session is in browser sessionStorage, so closing the tab also clears it. Use the explicit Log Out for shared computers.

---

## 13. Troubleshooting

| Symptom | Cause / Fix |
|---------|------------|
| "Username or password is incorrect" | Check spelling. Username is case-sensitive lowercase. Ask Admin to reset if forgotten. |
| Pipeline shows "No brands registered yet" | Either no brands are approved yet, or your session expired. Click **Pipeline** again to reload. |
| Brand card click does nothing | Browser console (F12) will show the error. Most likely an outdated browser cache — Ctrl+Shift+R to hard refresh. |
| OTP email not arriving for contract signing | Check spam folder. OTP is sent from `noreply@applywalmart.info`. If the domain isn't yet verified in Resend, it falls back to `onboarding@resend.dev`. |
| "Application not found (no email match)" in brand detail | The brand was added directly without an application form. Not an error — the section is informational. |
| Meeting time appears wrong | All times are KST (Korea Standard Time, UTC+9). If you're in the US, subtract 13–14 hours depending on Daylight Saving. |

---

## 14. Key principles

1. **Single source of truth**: brands, contracts, messages, tasks, meetings, documents — all in one shared database. No need to email PDFs back and forth.
2. **Phase-aware**: pin information to the right phase so it stays meaningful as the brand progresses.
3. **Audit trail**: every signature has IP, user agent, session ID, SHA-256 hash stored — defensible under US ESIGN Act and KR Electronic Signature Act.
4. **Brand sees what they should**: Internal Notes are private (admin/Startup Junkie only). Tasks, meetings, document requests, messages are shared by design.

---

## 15. Contact

- **3SVS (Korea) — primary operator**: 배종원 (Jongwon Bae) · `jw@3svs.com`
- **Domain / hosting issues**: ask 3SVS to coordinate (Vercel + Supabase backend)
- **Bug reports**: include screenshot + browser console log (F12 → Console tab)

---

*End of Walmart Buyer Portal User Guide.*

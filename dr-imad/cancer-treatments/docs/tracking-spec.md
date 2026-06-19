# GTM Tracking Spec — Dr. Imad Site

**Container:** `GTM-PSVM4HGG`

This document maps every event the website fires (`window.dataLayer.push`) to the GTM tags that should fire when it happens.

---

## Tracking IDs

| Tool | ID |
|---|---|
| GTM Container | `GTM-PSVM4HGG` |
| Meta Pixel | `2033473084217961` |
| GA4 | `G-9P3T3BGW15` |
| Microsoft Clarity | `wluoj19dnw` |
| Google Ads Conversion ID | `AW-18008224941` |
| Google Ads Conversion Label (Lead) | `COjwCL6KtKccEK3p_opD` |

---

## Architecture Principle

**No direct fbq/gtag/clarity calls in the website code.** Everything goes through `window.dataLayer.push()` → GTM picks it up → GTM fires the right tags.

This means: change tracking config in GTM, no code edits to website.

---

## Events Fired by Website

All events prefixed `cion_` for easy filtering in GTM.

| Event Name | When Fires | Key Params |
|---|---|---|
| `cion_page_view` | Every page load | doctor_name, page_type, page_name, attribution |
| `cion_view_content` | Every page load | content_category, content_name (Meta-safe — no cancer concern) |
| `cion_call_click` | User clicks tel: link | cta_position, intent, session_score |
| `cion_whatsapp_click` | User clicks WhatsApp link | cta_position, intent, session_score |
| `cion_form_jump_click` | User clicks "scroll to form" CTA | cta_position, intent |
| `cion_report_upload_click` | User clicks online second opinion CTA | cta_position |
| `cion_form_start` | First focus on a form field | (page context) |
| `cion_form_submit_attempt` | User clicks Submit | (page context) |
| `cion_form_submit_success` | API returns success | event_id |
| `cion_form_submit_error` | Validation error before submit | errors (csv) |
| `cion_form_submit_failure` | API returns failure | error message |
| `cion_form_field_error` | Field validation error | field name |
| `cion_section_view` | Section enters viewport (40%) | section_name |
| `cion_scroll_50` / `_75` / `_90` | Scroll depth reached | (page context) |
| `cion_time_30s` / `_60s` / `_120s` | Time on page | (page context) |
| `cion_faq_open` | FAQ accordion expanded | faq_question (first 80 chars) |
| `cion_language_toggle` | Language switched | lang (te/en) |
| `cion_doctor_profile_click` | Click on a CION doctor link | doctor_clicked |
| `cion_location_map_click` | Map clicked | (page context) |

---

## Tags to Configure in GTM

### A. Universal page tracking

**Tag 1: GA4 Configuration**
- Tag type: GA4 Configuration
- Measurement ID: `G-9P3T3BGW15`
- Trigger: All Pages

**Tag 2: Meta Pixel Base**
- Tag type: Custom HTML
- HTML: standard Meta Pixel base code with `2033473084217961`
- Trigger: All Pages

**Tag 3: Microsoft Clarity**
- Tag type: Custom HTML
- HTML: Clarity script with `wluoj19dnw`
- Trigger: All Pages

**Tag 4: Google Ads Site Tag**
- Tag type: Google Ads Conversion (config)
- Conversion ID: `AW-18008224941`
- Trigger: All Pages

### B. Engagement events → GA4

**Tag 5: GA4 Event — Call Click**
- Tag type: GA4 Event
- Event name: `cion_call_click`
- Trigger: Custom Event = `cion_call_click`

(Repeat pattern for: whatsapp_click, form_start, form_submit_success, scroll_50/75/90, time_30s/60s/120s, faq_open, language_toggle)

### C. Meta Pixel events (sanitized — no cancer data)

**Tag 6: Meta Pixel — ViewContent**
- Tag type: Custom HTML or Meta Pixel
- Pixel event: `ViewContent`
- Params: `{content_category: 'doctor_landing_page', content_name: '{{cion_content_name}}'}`
- Trigger: Custom Event = `cion_view_content`

**Tag 7: Meta Pixel — Contact (engagement signal)**
- Pixel event: `Contact`
- Trigger: Custom Event = `cion_call_click` OR `cion_whatsapp_click`

**Tag 8: Meta Pixel — Lead (CONVERSION — fires on thank-you only)**
- Pixel event: `Lead`
- Params: `{value: 1500, currency: 'INR'}`
- Trigger: Page URL contains `/thank-you/?ref=lead` (not on form submit, only on thank-you visit)

**Tag 9: Meta Pixel — Custom Engagement**
- Pixel event: Custom `Scroll75`
- Trigger: Custom Event = `cion_scroll_75`

### D. Google Ads conversion (CONVERSION — fires on thank-you only)

**Tag 10: Google Ads Lead Conversion**
- Conversion ID: `AW-18008224941`
- Conversion Label: `COjwCL6KtKccEK3p_opD`
- Conversion Value: 1500
- Currency: INR
- Trigger: Page URL contains `/thank-you/?ref=lead`

### E. GA4 Conversion

**Tag 11: GA4 Generate Lead Event**
- Event name: `generate_lead`
- Params: `{value: 1500, currency: 'INR'}`
- Trigger: Page URL contains `/thank-you/?ref=lead`

---

## Variables to Create in GTM

**Built-in variables to enable:**
- Page URL
- Page Path
- Page Hostname
- Click Element
- Click URL

**Data Layer Variables:**
| Variable name in GTM | dataLayer key |
|---|---|
| `cion_doctor_name` | doctor_name |
| `cion_page_type` | page_type |
| `cion_page_name` | page_name |
| `cion_lp_variant` | lp_variant |
| `cion_offer_type` | offer_type |
| `cion_condition_page` | condition_page |
| `cion_content_name` | content_name |
| `cion_content_category` | content_category |
| `cion_intent` | intent |
| `cion_cta_position` | cta_position |
| `cion_session_score` | session_score |
| `cion_event_id` | event_id |
| `cion_utm_source` | utm_source |
| `cion_utm_medium` | utm_medium |
| `cion_utm_campaign` | utm_campaign |
| `cion_gclid` | gclid |
| `cion_fbclid` | fbclid |

---

## Triggers to Create

| Trigger Name | Type | Condition |
|---|---|---|
| All Pages | Page View | (default) |
| Page View Thank You Lead | Page View | Page URL contains `/thank-you/?ref=lead` |
| Custom — Call Click | Custom Event | Event = `cion_call_click` |
| Custom — WhatsApp Click | Custom Event | Event = `cion_whatsapp_click` |
| Custom — Form Submit Success | Custom Event | Event = `cion_form_submit_success` |
| Custom — View Content | Custom Event | Event = `cion_view_content` |
| Custom — Scroll 75 | Custom Event | Event = `cion_scroll_75` |
| Custom — Time 60s | Custom Event | Event = `cion_time_60s` |
| Custom — Language Toggle | Custom Event | Event = `cion_language_toggle` |
| Custom — FAQ Open | Custom Event | Event = `cion_faq_open` |

---

## What NOT to Send to Meta

**These fields stay in HubSpot/Sheet ONLY. NEVER add to Meta Pixel events:**
- `condition_interest_key` (cancer concern dropdown)
- `condition_page` (which cancer page they came from)
- Patient name, phone, city
- Full landing page URL with query strings

**Reason:** Meta's Health & Wellness ad policies. Sending health-condition data risks ad account suspension.

---

## What CAN Go to Meta

- Generic page categorization: `content_category="doctor_landing_page"`, `content_name="surgical_oncology"`
- Engagement events: ViewContent, Scroll, Contact, Lead
- Static lead value: ₹1500 (placeholder for now; refine in Phase 2 with offline conversion API)

---

## Phase 2 — Meta Conversions API (CAPI)

Not in Phase 1. Build later via n8n:
- Trigger: HubSpot deal stage = "OP Visit Confirmed" → fire CAPI event with offline value
- Use `event_id` (UUID stored at form submit) for client-side / server-side dedup

---

## Testing Checklist

After GTM published:
- [ ] GTM Preview mode → load home page → verify all tags fire
- [ ] Click WhatsApp → verify `cion_whatsapp_click` event in dataLayer
- [ ] Click Call → verify `cion_call_click` event
- [ ] Submit form → verify redirect to `/thank-you/?ref=lead&eid=...`
- [ ] On thank-you page → verify Google Ads conversion + Meta Lead + GA4 generate_lead all fire
- [ ] Use Meta Pixel Helper Chrome extension → verify Pixel events
- [ ] Use Tag Assistant Companion → verify GA4 events
- [ ] Microsoft Clarity dashboard → verify session recordings appearing (within 2 hours)

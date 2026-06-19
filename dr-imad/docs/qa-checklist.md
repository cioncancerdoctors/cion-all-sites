# QA Checklist — Pre-Launch Testing

Run this before each batch goes live on Hostinger.

---

## A. Per-Page QA (Run on Every Page)

### Visual & Layout
- [ ] Mobile (375px width): no horizontal scroll, sticky bar visible, hamburger works
- [ ] Tablet (768px width): hero 2-column, header phone visible
- [ ] Desktop (1280px width): full nav inline, 3-col grids
- [ ] Telugu rendering: Noto Sans Telugu loads, no boxes/missing chars
- [ ] English rendering: Cormorant serif loads for headings
- [ ] Language toggle: clicks correctly, persists in localStorage
- [ ] Hero portrait loads (Imad photo)
- [ ] All section images load (no broken links)

### Content
- [ ] All Telugu sections present alongside English equivalents
- [ ] First-person doctor voice in prose (Telugu + English)
- [ ] Credentials match doctor-facts.json exactly (14+ years, AIIMS, etc.)
- [ ] No "AIIMS New Delhi" — only "AIIMS"
- [ ] No fabricated stats
- [ ] No competitor disparagement
- [ ] Cost figures show "starting at" or range (no exact ₹467,500-style numbers)
- [ ] Listicle pages have "In no particular order" disclaimer

### CTAs
- [ ] All Call CTAs link to `tel:+919063490160`
- [ ] All WhatsApp CTAs link to `https://wa.me/919063490160?text=...`
- [ ] Form Jump CTAs scroll to form smoothly
- [ ] Sticky bottom bar shows on mobile only
- [ ] All CTAs have data-cta, data-cta-pos, data-intent attributes

### Tracking
- [ ] GTM container loads (`GTM-PSVM4HGG`)
- [ ] In GTM Preview Mode → page view fires
- [ ] Click WhatsApp → `cion_whatsapp_click` event in dataLayer
- [ ] Click Call → `cion_call_click` event
- [ ] Scroll past 50%/75%/90% → events fire
- [ ] Stay 30s/60s → events fire
- [ ] FAQ accordion expand → `cion_faq_open` fires
- [ ] Language toggle → `cion_language_toggle` fires

### Form (if page has one)
- [ ] Form loads with correct intent (data-intent attr)
- [ ] Empty submit → validation errors show
- [ ] Invalid phone → error shows
- [ ] Honeypot field is hidden
- [ ] Submit valid form → redirects to `/thank-you/?ref=lead&eid=...`
- [ ] Server (`api/submit.php`) receives all 30+ hidden fields
- [ ] Sheet row created (after n8n integration)
- [ ] HubSpot contact + deal created (after n8n)
- [ ] Gmail alert sent (after n8n)
- [ ] CSV backup row appended in `api/leads.csv`

### Schema
- [ ] JSON-LD blocks present in `<head>`
- [ ] No JSON syntax errors (check via Rich Results Test)
- [ ] Schema matches page type per schema-spec.md

### SEO
- [ ] Title tag in English, ≤60 chars
- [ ] Meta description in English, ≤155 chars
- [ ] Canonical URL set
- [ ] hreflang for te-IN and en-IN
- [ ] Open Graph image, title, description
- [ ] H1 tag (one per page) contains primary keyword
- [ ] H2/H3 tags structure content properly
- [ ] All images have alt text
- [ ] Internal links to 10+ other pages present
- [ ] Breadcrumb navigation present (sub-pages)

### Compliance
- [ ] Privacy link in footer
- [ ] Editorial trust block on medical content pages
- [ ] No email shown anywhere
- [ ] No "guarantees" / "100% cure" / "miracle" language
- [ ] Patient testimonials marked as illustrative (or absent)
- [ ] DPDP consent checkbox on form

### Copy Protection
- [ ] Right-click → context menu blocked (except on phone numbers)
- [ ] Ctrl+C / Cmd+C → blocked (except on phone numbers + addresses)
- [ ] Image drag → blocked
- [ ] Phone numbers (.phone-number) ARE selectable

### Performance
- [ ] Page loads in <3s on mobile (test via PageSpeed Insights)
- [ ] LCP < 2.5s
- [ ] No layout shifts (CLS < 0.1)
- [ ] CSS file gzipped (verify in Network tab)
- [ ] Images lazy-loaded (except hero)

### Browser compatibility
- [ ] Chrome (Android + Desktop)
- [ ] Safari (iOS + macOS)
- [ ] Firefox
- [ ] Samsung Internet (high India share)

---

## B. Form-to-CRM Testing (After n8n setup)

Submit a test form with name "TEST-XX" (where XX is timestamp):

- [ ] Page → submit.php returns success JSON
- [ ] submit.php → n8n webhook called (5s timeout)
- [ ] n8n flow execution completes
- [ ] Google Sheet row created with all 30+ fields
- [ ] HubSpot Contact created with custom fields populated
- [ ] HubSpot Deal created in correct pipeline stage
- [ ] Gmail alert delivered to cioncancerdoctors@gmail.com
- [ ] CSV file `api/leads.csv` has new row
- [ ] Thank-you page loads with `?ref=lead&eid=UUID`
- [ ] On thank-you: Google Ads conversion fires (check via Tag Assistant)
- [ ] On thank-you: Meta Lead pixel fires (check via Pixel Helper)
- [ ] On thank-you: GA4 generate_lead fires

Delete TEST-XX rows after testing.

---

## C. Failure Path Testing

- [ ] Submit form with rate-limited IP → returns 429 error
- [ ] Submit form with same phone twice in 30 min → returns dedup error
- [ ] Submit form with phone that doesn't start with 6-9 → validation error
- [ ] n8n webhook DOWN → form still succeeds (CSV backup written)
- [ ] Slow network → form shows "Sending..." state
- [ ] Honeypot filled (bot test) → returns silent success, no row written

---

## D. Search Console Checks (after publishing)

- [ ] Property created at `https://cioncancerdrimad.com`
- [ ] Verification meta tag added to head (or DNS)
- [ ] sitemap.xml submitted
- [ ] No coverage errors after 7 days
- [ ] Mobile Usability: no errors
- [ ] Core Web Vitals: passing
- [ ] No security issues
- [ ] No manual actions

---

## E. GMB / Local SEO Sync

- [ ] GMB profile NAP matches website footer exactly
- [ ] GMB website link includes UTM: `?utm_source=gmb&utm_medium=organic`
- [ ] Service list on GMB matches website service list
- [ ] Hours match: Mon-Sat 10AM-5PM
- [ ] Phone matches: +91 90634 90160
- [ ] Address consistent

---

## F. Cross-Profile Consistency (Practo/JustDial/etc.)

- [ ] Doctor name spelled identically (Dr. Mohammed Imaduddin)
- [ ] Experience matches (14+ years)
- [ ] Qualifications match (M.B.B.S, MS, M.Ch AIIMS, FEBS, FACS)
- [ ] Specialty matches (Surgical Oncology)
- [ ] Phone matches
- [ ] Address consistent

If any mismatch found → log in `consistency-check.md` for fix.

---

## G. Pre-Launch Backup

- [ ] Backup current Hostinger `public_html` as `public_html_backup_YYYYMMDD.zip`
- [ ] Save backup off-server (Google Drive, local)
- [ ] Document rollback steps
- [ ] Test rollback works (on staging if possible)

---

## H. Post-Launch Monitoring (First 48 hours)

- [ ] Check live site every 4 hours for first 24h
- [ ] Monitor `api/errors.log` daily
- [ ] Watch n8n execution log for failures
- [ ] Check Search Console for new errors
- [ ] Check Meta Pixel Helper on live site
- [ ] Check GA4 Realtime to confirm events flowing
- [ ] Check HubSpot for incoming test contacts
- [ ] Check Microsoft Clarity for first sessions

---

## I. Per-Batch Special Tests

### Batch 1 (Brand pages)
- [ ] Hero portrait shows on all pages where used
- [ ] Doctor card renders on bottom of each page
- [ ] Footer mega-nav links all work
- [ ] Internal links from Home → all other pages work

### Batch 2 (Service pages)
- [ ] PET CT pricing shows ₹10,000 + footnote
- [ ] Genetic testing tier table renders correctly
- [ ] Cancer vaccination page has correct vaccine info (HPV, Hep B)
- [ ] Free Online Second Opinion form has correct WhatsApp redirect with case ID

### Batch 5 (Listicles)
- [ ] CION/Imad at #1 on relevant lists
- [ ] Other doctors/hospitals randomized order
- [ ] CION doctor websites linked correctly
- [ ] "In no particular order" disclaimer at top
- [ ] CION affiliation disclosed in footer

---

## Sign-off Template

| Item | Tester | Date | Pass/Fail |
|---|---|---|---|
| Visual & Layout | | | |
| Content accuracy | | | |
| CTAs | | | |
| Tracking events | | | |
| Form submission | | | |
| Schema validation | | | |
| Browser compat | | | |
| Performance | | | |
| Security/Compliance | | | |
| Backup taken | | | |

**Approved for live by:** ___________ Date: ___________

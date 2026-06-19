# Publishing Plan — Dr. Imad Site

**Goal:** Stage page launches to avoid Google "scaled content abuse" flag while building topical authority systematically.

---

## Build vs Publish Velocity

**Build velocity:** Fast (Claude generates pages in batches over a few sessions)
**Publish velocity:** Staged (10-15 pages live first, add 5-8 every 5-7 days)

This keeps Search Console happy and gives you data to refine before scaling.

---

## Phase 1 — 32 Pages Total

### Wave 1 — Foundation Live (Day 1-3)
**Upload all at once. Submit sitemap to Search Console.**

10 pages:
- `/` (Home)
- `/why-dr-imad/`
- `/advanced-surgeries/`
- `/book-appointment/`
- `/free-second-opinion/`
- `/free-online-second-opinion/`
- `/privacy/`
- `/thank-you/`
- `/404.html`
- `/types-of-cancer/` (hub — placeholder if not built yet)

### Wave 2 — Service & High-Intent SEO (Day 5-8)
**Wait 3-4 days after Wave 1. Verify Wave 1 pages indexed in Search Console.**

8 pages:
- `/pet-ct-scan-hyderabad/`
- `/genetic-testing-for-cancer/`
- `/cancer-vaccination/`
- `/hyderabad/surgical-oncologist-hyderabad/`
- `/hyderabad/hipec-treatment-hyderabad/`
- `/hyderabad/second-opinion-cancer-hyderabad/`
- `/hyderabad/cancer-surgery-cost-hyderabad/`
- `/hyderabad/aarogyasri-cancer-treatment-hyderabad/`

Update sitemap.xml. Submit again.

### Wave 3 — Imad Strength Cancer Pages (Day 10-15)
8 pages, batch in 2 groups of 4:

**Group A (Day 10):**
- `/types-of-cancer/gastric-stomach-cancer/`
- `/types-of-cancer/colorectal-cancer/`
- `/types-of-cancer/peritoneal-cancer/`
- `/types-of-cancer/ovarian-cancer/`

**Group B (Day 13):**
- `/types-of-cancer/pancreatic-cancer/`
- `/types-of-cancer/oesophageal-cancer/`
- `/types-of-cancer/liver-cancer/`
- `/types-of-cancer/appendix-cancer-pmp/`

Update sitemap. Internal linking from Wave 1+2 pages to these.

### Wave 4 — Treatment + Hyderabad SEO (Day 17-22)
6 treatment + 3 Hyderabad pages:

**Day 17:**
- `/cancer-treatments/hipec-pipac/`
- `/cancer-treatments/whipples-procedure/`
- `/cancer-treatments/cytoreductive-surgery/`

**Day 20:**
- `/cancer-treatments/laparoscopic-cancer-surgery/`
- `/cancer-treatments/surgical-oncology/`
- `/cancer-treatments/gi-cancer-surgery/`

**Day 22:**
- `/hyderabad/gastric-cancer-surgery-hyderabad/`
- `/hyderabad/colorectal-cancer-surgery-hyderabad/`
- `/hyderabad/peritoneal-cancer-hyderabad/`

### Wave 5 — Listicles (Day 24-28)
3 listicles, staggered:

**Day 24:** `/hyderabad/best-cancer-hospital-hyderabad/`
**Day 26:** `/hyderabad/best-cancer-surgeons-hyderabad/`
**Day 28:** `/hyderabad/best-hipec-surgeons-hyderabad/`

---

## Internal Linking Updates Schedule

After each wave, update internal links FROM existing pages TO new pages:

- Wave 2 live → Update Wave 1 pages to link to new service pages
- Wave 3 live → Update Why Dr. Imad + Advanced Surgeries to link to cancer type pages
- Wave 4 live → Update cancer type pages to link to treatment pages
- Wave 5 live → Update Hyderabad SEO pages to link to listicles

---

## Search Console Checkpoints

- **Day 3:** Confirm Wave 1 pages indexed. Check Coverage report.
- **Day 8:** Wave 2 indexed? Any errors?
- **Day 15:** Wave 3 indexed? Any duplicate content warnings?
- **Day 22:** Look at first impressions/clicks data.
- **Day 28:** Full Phase 1 review. Any pages with crawl issues?
- **Day 35:** First ranking insights. Identify wins.

---

## Phase 2 Triggers (after Phase 1 complete)

**Add Phase 2 pages ONLY if:**
- Phase 1 pages mostly indexed (>80%)
- No spam policy warnings in Search Console
- Some pages getting impressions
- No duplicate content flags

**If Phase 1 healthy:** Start Phase 2 (hubs, A-Z Q&As, more listicles, more cancer types).
**If Phase 1 issues:** Fix issues first, don't add more pages.

---

## Phase 2 Pages (Future)
- 4 hub pages (Types, Treatments, A-Z, Hyderabad)
- 80 A-Z Q&A pages (15/week pace)
- 7 more cancer types
- 7 more listicles
- 4 more Hyderabad SEO pages
- More landing pages for ads

Total Phase 2: ~100 pages over 2-3 months.

---

## Ad Campaign Sync

- **Wave 1 live:** Pause all old WordPress traffic. Don't run ads yet.
- **Wave 2 live:** Run Meta ads to `/hyderabad/second-opinion-cancer-hyderabad/`
- **Wave 3 live:** Run Google Ads to `/hyderabad/hipec-treatment-hyderabad/` + cancer type pages
- **Wave 5 live:** Run Meta ads to listicles

Always check tracking fires before increasing spend.

---

## Backup + Rollback Plan

Before each wave:
1. Backup current Hostinger public_html as `public_html_backup_YYYYMMDD.zip`
2. Test new pages on staging path (e.g., `/preview/`) first
3. Verify forms work, GTM fires, mobile renders correctly
4. Move to live URL only after testing

If issues post-launch:
- Restore from backup zip
- Issue takes <30 min to revert

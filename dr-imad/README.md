# DEPLOYMENT GUIDE — Dr. Imad Website

**Read this first. Step-by-step Hostinger deployment.**

---

## What you have

**33 files** organized into:
- 1 homepage (`index.php`)
- 1 error page (`404.php`)
- 8 reusable partials (PHP includes)
- 1 form gateway (`api/submit.php`)
- 1 CSS, 6 JS, 1 image (assets)
- 4 data files (JSON — single source of truth)
- 6 docs (markdown — for your reference, not on live site)
- 3 config files (`robots.txt`, `sitemap.xml`, `.htaccess`)

---

## EXACT structure on Hostinger after deployment

```
public_html/                                ← Hostinger's web root
│
├── index.php                               ← Homepage (https://cioncancerdrimad.com/)
├── 404.php                                 ← 404 error page
├── .htaccess                               ← Server config
├── robots.txt                              ← SEO crawl rules
├── sitemap.xml                             ← SEO sitemap
├── README.md                               ← This file (optional, can delete after deploy)
│
├── partials/                               ← PHP includes (NOT in URLs)
│   ├── header.php
│   ├── footer.php
│   ├── meta-tags.php
│   ├── form-module.php
│   ├── doctor-card.php
│   ├── cta-strip.php
│   ├── related-pages.php
│   └── editorial-trust-block.php
│
├── assets/                                 ← Static assets
│   ├── css/
│   │   └── styles.css
│   ├── js/
│   │   ├── doctor-data.js
│   │   ├── tracking.js
│   │   ├── form.js
│   │   ├── nav.js
│   │   ├── lang-toggle.js
│   │   └── copy-protect.js
│   └── images/
│       └── dr-imad-portrait.jpg
│
├── data/                                   ← JSON (BLOCKED from web by .htaccess)
│   ├── doctor-facts.json
│   ├── cion-doctors.json
│   ├── centres.json
│   └── cancer-types.json
│
├── api/                                    ← Form gateway
│   └── submit.php
│   (auto-creates: leads.csv, rate-limit.json, recent-phones.json, errors.log)
│
└── docs/                                   ← Reference docs (BLOCKED from web)
    ├── publishing-plan.md
    ├── source-library.md
    ├── tracking-spec.md
    ├── schema-spec.md
    ├── qa-checklist.md
    └── consistency-check.md
```

---

## ⚠️ CRITICAL — the cion-imad/ wrapper problem

**The zip extracts to a folder called `cion-imad/`. You must NOT keep that wrapper.**

### WRONG — files inside `cion-imad/` subfolder:
```
public_html/
└── cion-imad/                              ← ❌ THIS IS WRONG
    ├── index.php
    ├── partials/
    └── ...
```
Result: Site URL would be `cioncancerdrimad.com/cion-imad/` — broken.

### RIGHT — files directly in `public_html/`:
```
public_html/
├── index.php                               ← ✓ CORRECT
├── partials/
└── ...
```
Result: Site URL is `cioncancerdrimad.com/` — works.

---

## Step-by-step deployment

### Step 1: Backup current site (MANDATORY)
1. Hostinger File Manager → right-click `public_html` → **Compress** → save as `public_html_backup_20260506.zip`
2. **Download to your computer**
3. Verify download

### Step 2: Empty `public_html/`
1. Select all files/folders inside `public_html/`
2. Delete (your backup is safety net)
3. `public_html/` should be empty

### Step 3: Upload zip
1. Upload `cion-imad-batch1-homepage.zip` to `public_html/`
2. Right-click → **Extract** → extract to current folder
3. You'll see a `cion-imad/` folder appear

### Step 4: Move files OUT of `cion-imad/` wrapper

**Option A — File Manager:**
1. Open `public_html/cion-imad/`
2. Select ALL contents (Ctrl+A or Cmd+A)
3. Cut (Ctrl+X)
4. Navigate up to `public_html/`
5. Paste (Ctrl+V)
6. Delete the now-empty `cion-imad/` folder
7. Delete the zip too

**Option B — Re-upload flat (if Option A fails):**
1. Extract zip on your computer
2. Open `cion-imad/` folder
3. Select contents (NOT the folder)
4. Re-zip the contents → `cion-imad-flat.zip`
5. Upload to empty `public_html/` and extract — files land directly

### Step 5: Verify structure
`public_html/` should look like:
```
public_html/
├── index.php          ← Should be HERE, not in subfolder
├── 404.php
├── .htaccess
├── partials/
├── assets/
├── data/
├── api/
└── docs/
```

If you see `public_html/cion-imad/index.php` — go back to Step 4.

### Step 6: Set permissions
| Item | Permission |
|---|---|
| All folders | **755** |
| All files | **644** |
| `api/` folder | **755** (writable for CSV) |

### Step 7: Test PHP works
Visit: `https://cioncancerdrimad.com/api/submit.php`

**Expected:** `{"success":false,"error":"Method not allowed"}`

If you see PHP code as text → enable PHP 7.4+ in Hostinger control panel.

### Step 8: Test homepage
Visit: `https://cioncancerdrimad.com/`

**Expected:** Site loads, Telugu default, EN toggle works, sticky bar on mobile.

### Step 9: Test security blocks
All should return **403 Forbidden**:
- `/data/doctor-facts.json`
- `/api/leads.csv`
- `/docs/qa-checklist.md`

### Step 10: Test 404
Visit any fake URL: `https://cioncancerdrimad.com/fake-page`

**Expected:** Custom purple 404 page with "Go Home" + "WhatsApp" buttons.

---

## What WORKS now

✅ Homepage `/`
✅ 404 page (any wrong URL)
✅ Form submission (CSV backup; n8n integration is separate)
✅ Sticky CTA, hamburger nav, language toggle
✅ Tracking (GTM container loads; tags configured separately)

## What DOESN'T work yet (404s expected — Batch 2)

❌ `/why-dr-imad/` `/advanced-surgeries/` `/types-of-cancer/`
❌ `/cancer-treatments/` `/a-z-of-cancer/`
❌ All cancer type pages (gastric, colorectal, etc.)
❌ All listicle pages
❌ `/free-second-opinion/` `/free-online-second-opinion/` `/pet-ct-scan-hyderabad/` `/genetic-testing-for-cancer/` `/cancer-vaccination/`
❌ `/book-appointment/` `/privacy/` `/contact/` `/thank-you/`

The friendly 404 page recovers these users with "Go Home" button. Build Batch 2 to fix.

---

## Common errors

### Error: HTTP 500
Rename `.htaccess` to `.htaccess.bak`. Reload. If site loads → htaccess issue, contact Hostinger. If still 500 → check error logs.

### Error: PHP shows as text
Hostinger control panel → set PHP version to 7.4 or 8.x.

### Error: No styling
DevTools → Network → reload. Look for `styles.css` 404. File path issue — recheck Step 5.

### Error: Telugu shows boxes
Noto Sans Telugu font not loading from Google Fonts. Check internet, rare issue.

---

## Recovery if something breaks

1. Empty `public_html/`
2. Upload your Step 1 backup zip
3. Extract
4. Site is back to previous state

That's why Step 1 backup is mandatory.

---

## Next steps after deployment works

1. Reply **"Build Batch 2"** → I build 7 more pages (Why Dr. Imad, Advanced Surgeries, 5 service pages)
2. Set up GTM tags (use `docs/tracking-spec.md`)
3. Set up n8n workflow for form → HubSpot/Sheet/Gmail
4. Submit sitemap to Google Search Console
5. Update GMB profile with new URL + UTM tracking

---

## Quick file reference

**Public pages:**
- `index.php` → `/`
- `404.php` → auto on errors

**Server config:**
- `.htaccess` HTTPS, gzip, security, blocks /data /docs from web
- `robots.txt` SEO crawl rules
- `sitemap.xml` page index

**Reusable code (PHP includes):**
- `partials/*.php` — header, footer, meta, form, CTAs, doctor card

**Static assets:**
- `assets/css/styles.css` — all styling
- `assets/js/*.js` — tracking, form, nav, lang, copy-protect
- `assets/images/dr-imad-portrait.jpg` — doctor photo

**Data layer (blocked from web):**
- `data/*.json` — facts, doctors, centres, cancer types

**Form processing:**
- `api/submit.php` — gateway
- `api/leads.csv` (auto-created) — backup

**Docs (blocked from web):**
- `docs/*.md` — your operational reference

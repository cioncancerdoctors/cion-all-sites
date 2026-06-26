# PHP Architecture Migration Plan
## Move 8 static sites to Dr. Imad's PHP partial architecture

**Status: Planned — not started**
**Discussed: 2026-06-26**
**Decision: Do not build yet. Document for future session.**

---

## Why

The 8 static sites (dr-owais, dr-vinay, dr-murali, dr-sandeep, dr-kiranmayee, dr-basudev,
dr-raghvendra, dr-craghavendra) are pure static HTML. Every page duplicates the nav, footer,
CSS, JS, and form inline. A nav change requires editing 19 files per site × 8 sites = 152 edits.

Dr. Imad's site uses PHP partials: one `header.php`, one `footer.php`, one `styles.css`, one
`form-module.php`. A nav change touches 1 file. This is the right architecture.

**Goal:** migrate all 8 static sites to match Dr. Imad's PHP partial pattern so the nightly
runner generates one type of page (PHP) for all 9 sites in a single unified code path.

---

## Locked Decisions

### URL strategy: keep `.html` public URLs, back them with PHP internally

- Existing 152 `.html` pages already indexed by Google with backlinks — no 301 redirects
- `.htaccess` rewrites `/slug.html` → `/slug.php` server-side; canonical stays `/slug.html`
- New generated pages: `dr-owais/slug.php` served at `https://domain/slug.html`
- Dr. Imad stays extensionless (`/free-second-opinion/`). Two URL shapes, one architecture.

```apache
RewriteEngine On
RewriteCond %{DOCUMENT_ROOT}/$1.php -f
RewriteRule ^([a-z0-9-]+)\.html$ /$1.php [L]
```

### Per-site config: one `_inc.php` per site, shared parameterised partials

Dr. Imad's partials hardcode 27 values that differ per doctor (name in EN+TE, phone, WhatsApp
URL+message, nav links, GTM ID, credentials, clinic hours, copyright, portrait image path, etc.).

Pattern:
- Each site gets its own `_inc.php` defining all 27 variables
- `partials/*.php` files are identical PHP code that reads from those variables
- `_data/doctor-profiles.filled.csv` drives a `build-site-config.ps1` script that generates
  `_inc.php` + `partials/` for any site automatically

### Chrome injection in nightly runner: replace 3KB HTML with 3-line PHP contract

Current: `Get-SiteChrome` pastes nav+footer HTML (~3KB) into the codex prompt.
After migration, replace with:

```
This is a PHP-partial site. Set $page_title, $page_description, $page_canonical,
$page_og_image, then require _inc.php. Use include $ROOT/partials/header.php,
footer.php, form-module.php, cta-strip.php. Do not recreate nav, footer, CSS, or JS.
```

### Nightly runner: 6 places that assume `.html` — update all together

GPT identified these 6 places in `scripts/nightly-runner.ps1` that must all change at once:
1. `Get-SiteChrome` call — remove entirely for PHP sites
2. Prompt — "write `$Site/<slug>.html`" → "write `$Site/<slug>.php`"
3. Contract check — `Get-ChildItem ... -Filter *.html` → include `.php`
4. Sitemap — URL builder uses `$fileName` (`.html`) → rewrite as `.html` for PHP files
5. Smoke test — URL must be `https://domain/slug.html` even though file is `slug.php`
6. Tracker rebuild — `Get-ChildItem ... -Filter *.html` → include `.php` source

**If any one of these 6 is missed, the runner generates valid PHP but fails its own checks.**

---

## Generated PHP page shell (template for runner)

```php
<?php
$page_title       = "...";
$page_description = "...";
$page_canonical   = "https://$SITE_DOMAIN/$SLUG.html";
$page_robots      = "index, follow, max-image-preview:large";
$page_og_image    = "https://$SITE_DOMAIN/$PORTRAIT_IMAGE";
require __DIR__ . '/_inc.php';
?>
<!DOCTYPE html>
<html lang="en">
<head>
<?php include $ROOT . '/partials/meta-tags.php'; ?>
<script type="application/ld+json">{ MedicalWebPage }</script>
<script type="application/ld+json">{ FAQPage }</script>
<script type="application/ld+json">{ BreadcrumbList — last item = canonical }</script>
<script>window.cionPageData = { doctor_name, specialty, page_type, intent, ... };</script>
</head>
<body data-page-type="seo_article" data-page-name="$SLUG">
<?php include $ROOT . '/partials/header.php'; ?>
<!-- bilingual content: <span class="te-content">, <span class="en-content"> -->
<!-- FAQ section -->
<?php include $ROOT . '/partials/form-module.php'; ?>
<?php include $ROOT . '/partials/cta-strip.php'; ?>
<?php include $ROOT . '/partials/footer.php'; ?>
</body>
</html>
```

---

## CSV columns to add to `_data/doctor-profiles.filled.csv`

Currently has ~20 columns. Need ~17 more:

```
gtm_id
job_title_en
job_title_te
brand_subtitle_en
brand_subtitle_te
phone_e164
phone_display
whatsapp_number
whatsapp_default_message
default_og_image
portrait_image
clinic_hours_en
clinic_hours_te
primary_state
copyright_owner
desktop_nav_json
footer_nav_json
```

---

## 4 Phases

### Phase 1 — Pilot on dr-owais (~10 files)
- Create `dr-owais/_inc.php` (all 27 variables for Dr. Owais)
- Create `dr-owais/partials/` (parameterised copies of Dr. Imad's 8 partials)
- Add `.htaccess` rewrite rule
- Generate one new `.php` SEO page end-to-end
- Verify it renders correctly on Hostinger
- **Do not touch the runner yet**

### Phase 2 — Generalise (~15 files)
- Fill missing CSV columns for all 9 doctors
- Build `scripts/build-site-config.ps1` (CSV → `_inc.php` + `partials/`)
- Update all 6 `.html` assumptions in `nightly-runner.ps1`
- Update `scripts/validate-page.py` to accept `.php` source files
- Update `qa/Check-Network.ps1` to validate PHP-backed pages
- **Sequential: must follow Phase 1**

### Phase 3 — Roll to remaining 7 sites
- Run `build-site-config.ps1` for each of the 7 remaining sites
- Smoke test each site
- **Can parallelise across sites after Phase 2**

### Phase 4 — Legacy page conversion (optional, gradual)
- Convert existing 152 `.html` pages to PHP-backed one by one
- Preserve all public URLs and canonicals
- **Never blocks Phase 3; do whenever convenient**

---

## Open Decision (needed before Phase 1 starts)

**CSS/branding:** Dr. Imad's `styles.css` uses his specific design (Cormorant + DM Sans fonts,
his colour palette). The 8 static sites use different inline CSS (Plus Jakarta Sans). Options:

| Option | Description | Trade-off |
|---|---|---|
| A. Adopt Dr. Imad's CSS for all 9 | Uniform CION network branding, one stylesheet | Visual redesign of 8 sites required |
| B. Each site keeps own `assets/css/styles.css` | Different branding per doctor | More maintenance; harder to update |
| C. Shared base CSS + per-site accent | Cleanest long-term | Most upfront build work |

**This decision gates Phase 1. Resolve before starting.**

---

## Reference files

| File | Role |
|---|---|
| `dr-imad/_inc.php` | Path bootstrap + default page variable fallbacks |
| `dr-imad/partials/meta-tags.php` | Full `<head>` output (GTM, OG, CSS, fonts) |
| `dr-imad/partials/header.php` | Nav, mobile drawer, sticky bar |
| `dr-imad/partials/footer.php` | Footer nav, credentials, JS loading |
| `dr-imad/partials/form-module.php` | Lead form (name, phone, concern, attachments) |
| `dr-imad/partials/cta-strip.php` | Bottom CTA with WhatsApp + call |
| `dr-imad/free-second-opinion/index.php` | Example inner page (good template reference) |
| `dr-owais/second-opinion.html` | Example static page (what we're migrating away from) |
| `_data/doctor-profiles.filled.csv` | Doctor config source of truth |
| `scripts/nightly-runner.ps1` | Nightly page generator (needs 6 changes in Phase 2) |

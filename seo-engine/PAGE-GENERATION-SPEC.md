# CION Page Generation Spec
**Version 1.0 — authoritative reference for all LLM page generation.**
This document defines EXACTLY what Claude must produce in the `mainHtml` JSON field.
Do not improvise structure. Every component has a fixed class name and fixed markup pattern.

---

## 1. mainHtml — required sequence

The `mainHtml` value must contain these 11 sections IN THIS ORDER:

```
1.  <nav class="breadcrumb">
2.  <h1>
3.  <p class="lede">
4.  <div class="answer-box">
5.  Body prose sections (h2 + <div class="prose"> + tables/callouts)
6.  <div class="leadform" id="lead-form">   ← FIXED BLOCK, copy verbatim
7.  <div class="doctor-card">               ← FIXED BLOCK, copy verbatim
8.  <h2> FAQ heading + <details class="faq"> items
9.  <div class="ilinks">
10. <div class="reviewer">
11. <div class="disclaimer">
```

**NEVER include:** `<style>`, `<script>`, `<head>`, `<html>`, `<body>`, `<header>`, `<nav id="navDrawer">`, `<footer>`, sticky bar, language toggle, hamburger.

---

## 2. Component markup — copy exactly, substitute values in CAPS

### 2.1 Breadcrumb
```html
<nav class="breadcrumb" aria-label="Breadcrumb">
  <a href="index.html"><span class="te-content">హోమ్</span><span class="en-content">Home</span></a> ›
  <span class="te-content">TELUGU_PAGE_NAME</span><span class="en-content">ENGLISH_PAGE_NAME</span>
</nav>
```

### 2.2 H1 + lede
```html
<h1><span class="te-content">TELUGU_H1</span><span class="en-content">ENGLISH_H1</span></h1>
<p class="lede">
  <span class="te-content">TELUGU_LEDE (2–3 sentences, first-person voice from doctor)</span>
  <span class="en-content">ENGLISH_LEDE (2–3 sentences, first-person voice from doctor)</span>
</p>
```

### 2.3 Answer box (LLM-citable direct answer — 40–60 words per language)
```html
<div class="answer-box">
  <div class="lbl">
    <svg class="ic" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"><path d="M9 11l3 3L22 4"/><path d="M21 12v7a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11"/></svg>
    <span class="te-content">సూటి సమాధానం</span><span class="en-content">Direct answer</span>
  </div>
  <p>
    <span class="te-content">TELUGU_DIRECT_ANSWER</span>
    <span class="en-content">ENGLISH_DIRECT_ANSWER</span>
  </p>
</div>
```

### 2.4 Body prose section (repeat 3–4 times with different h2s)
```html
<h2><span class="te-content">TELUGU_H2</span><span class="en-content">ENGLISH_H2</span></h2>
<div class="prose">
  <p>
    <span class="te-content">TELUGU_PARAGRAPH</span>
    <span class="en-content">ENGLISH_PARAGRAPH</span>
  </p>
</div>
```

### 2.5 Comparison table (use inside a prose section when comparing items)
```html
<table class="cmp">
  <thead>
    <tr>
      <th><span class="te-content">TELUGU_COL1</span><span class="en-content">ENGLISH_COL1</span></th>
      <th><span class="te-content">TELUGU_COL2</span><span class="en-content">ENGLISH_COL2</span></th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td><span class="te-content">TELUGU_CELL</span><span class="en-content">ENGLISH_CELL</span></td>
      <td><span class="te-content">TELUGU_CELL</span><span class="en-content">ENGLISH_CELL</span></td>
    </tr>
  </tbody>
</table>
```

### 2.6 Checklist callout (use for action lists, warning signs, what to bring)
```html
<div class="callout">
  <h3><span class="te-content">TELUGU_HEADING</span><span class="en-content">ENGLISH_HEADING</span></h3>
  <ul class="checklist">
    <li><span class="te-content">TELUGU_ITEM</span><span class="en-content">ENGLISH_ITEM</span></li>
  </ul>
</div>
```

### 2.7 Warning box (use for urgent clinical signals — fever, bleeding, etc.)
```html
<div class="warn">
  <span class="te-content"><b>TELUGU_BOLD_LABEL:</b> TELUGU_WARNING_TEXT</span>
  <span class="en-content"><b>ENGLISH_BOLD_LABEL:</b> ENGLISH_WARNING_TEXT</span>
</div>
```

### 2.8 Neutral callout (use for myth-busting, neutral notes)
```html
<div class="neutral">
  <span class="te-content">TELUGU_TEXT</span>
  <span class="en-content">ENGLISH_TEXT</span>
</div>
```

### 2.9 Lead form — COPY THIS BLOCK VERBATIM (substitute SLUG_VALUE and DOCTOR_KEY)
```html
<div class="leadform" id="lead-form">
  <h2><span class="te-content">మీ రిపోర్టులు సమీక్ష కోసం పంపండి.</span><span class="en-content">Send your reports for review.</span></h2>
  <p class="sub">
    <span class="te-content">మీ వివరాలు ఇవ్వండి, పని వేళల్లో మా టీమ్ మిమ్మల్ని కాల్ చేస్తుంది.</span>
    <span class="en-content">Submit your details and my team will call you during working hours.</span>
  </p>
  <form id="cion-form" enctype="multipart/form-data" novalidate>
    <div class="honeypot"><label>Website<input type="text" name="website" tabindex="-1" autocomplete="off"></label></div>
    <div class="field">
      <label><span class="te-content">మీ పేరు *</span><span class="en-content">Your Name *</span></label>
      <input type="text" name="name" required maxlength="80" autocomplete="name">
    </div>
    <div class="field">
      <label><span class="te-content">ఫోన్ నంబర్ *</span><span class="en-content">Phone Number *</span></label>
      <input type="tel" name="phone" required pattern="[0-9+\-\s]{10,15}" autocomplete="tel" inputmode="tel">
    </div>
    <div class="field">
      <label><span class="te-content">క్యాన్సర్ రకం / సమస్య</span><span class="en-content">Cancer Type / Concern</span></label>
      <input type="text" name="concern" maxlength="120" placeholder="e.g. Breast, Lung, Stomach">
    </div>
    <div class="field">
      <label><span class="te-content">నగరం</span><span class="en-content">City</span></label>
      <input type="text" name="city" maxlength="60" placeholder="Hyderabad">
    </div>
    <p class="hint" style="margin:0 0 4px"><span class="te-content">రిపోర్టులు / స్కాన్లు ఉన్నాయా? సమర్పించిన తర్వాత వాట్సాప్‌లో పంపండి.</span><span class="en-content">Have reports or scans? Send them on WhatsApp after you submit.</span></p>
    <input type="hidden" name="doctor_name" value="DOCTOR_KEY">
    <input type="hidden" name="page_type" value="SLUG_VALUE">
    <input type="hidden" name="event_id" value="">
    <input type="hidden" name="meta_lead_id" value="">
    <input type="hidden" name="fbclid" value=""><input type="hidden" name="gclid" value="">
    <input type="hidden" name="fbp" value=""><input type="hidden" name="fbc" value="">
    <input type="hidden" name="utm_source" value=""><input type="hidden" name="utm_medium" value="">
    <input type="hidden" name="utm_campaign" value=""><input type="hidden" name="utm_content" value="">
    <input type="hidden" name="utm_term" value=""><input type="hidden" name="submit_timestamp" value="">
    <button type="submit" class="submit"><span class="te-content">నా సంప్రదింపు బుక్ చేయండి</span><span class="en-content">Book My Consultation</span></button>
    <p class="consent">
      <span class="te-content">సమర్పించడం ద్వారా, ఫాలో-అప్ కోసం డాక్టర్ టీమ్ మిమ్మల్ని సంప్రదించడానికి మీరు అంగీకరిస్తున్నారు.</span>
      <span class="en-content">By submitting, you consent to the doctor's team contacting you for follow-up.</span>
    </p>
  </form>
  <div class="form-error" id="cion-form-error">
    <span class="te-content">ఏదో తప్పు జరిగింది. దయచేసి వాట్సాప్ చేయండి.</span>
    <span class="en-content">Something went wrong. Please message on WhatsApp.</span>
  </div>
  <div class="form-success" id="cion-form-success">
    <span class="big"><span class="te-content">ధన్యవాదాలు.</span><span class="en-content">Thank you.</span></span>
    <span class="te-content">మా టీమ్ త్వరలో మిమ్మల్ని కాల్ చేస్తుంది.</span><span class="en-content">My team will call you shortly.</span>
  </div>
</div>
```

### 2.10 Doctor card — COPY VERBATIM (runner substitutes DOCTOR_IMG, DOCTOR_NAME, CREDENTIALS, WA_URL)
```html
<div class="doctor-card">
  <img src="DOCTOR_IMG" alt="DOCTOR_NAME">
  <div>
    <div class="dc-name">DOCTOR_NAME</div>
    <div class="dc-cred"><span class="te-content">TELUGU_CREDENTIALS</span><span class="en-content">ENGLISH_CREDENTIALS</span></div>
    <a href="WA_URL" class="dc-cta">
      <svg class="ic-sm" viewBox="0 0 24 24" fill="currentColor"><path d="M17.472 14.382c-.297-.149-1.758-.867-2.03-.967-.273-.099-.471-.148-.67.15-.197.297-.767.966-.94 1.164-.173.199-.347.223-.644.075-.297-.15-1.255-.463-2.39-1.475-.883-.788-1.48-1.761-1.653-2.059-.173-.297-.018-.458.13-.606.134-.133.298-.347.446-.52.149-.174.198-.298.298-.497.099-.198.05-.371-.025-.52-.075-.149-.669-1.612-.916-2.207-.242-.579-.487-.5-.669-.51-.173-.008-.371-.01-.57-.01-.198 0-.52.074-.792.372-.272.297-1.04 1.016-1.04 2.479 0 1.462 1.065 2.875 1.213 3.074.149.198 2.096 3.2 5.077 4.487.709.306 1.262.489 1.694.625.712.227 1.36.195 1.871.118.571-.085 1.758-.719 2.006-1.413.248-.694.248-1.289.173-1.413-.074-.124-.272-.198-.57-.347M12.05 21.785a9.87 9.87 0 01-5.031-1.378l-.361-.214-3.741.982.998-3.648-.235-.374a9.86 9.86 0 01-1.51-5.26c.001-5.45 4.436-9.884 9.888-9.884 2.64 0 5.122 1.03 6.988 2.898a9.825 9.825 0 012.893 6.994c-.003 5.45-4.437 9.884-9.885 9.884"/></svg>
      <span class="te-content">సెకండ్ ఒపీనియన్ తీసుకోండి</span><span class="en-content">Book a second opinion</span>
    </a>
  </div>
</div>
```

### 2.11 FAQ section (minimum 5 items — FAQ heading + details elements)
```html
<h2><span class="te-content">తరచుగా అడిగే ప్రశ్నలు</span><span class="en-content">Frequently asked questions</span></h2>

<details class="faq">
  <summary>
    <span><span class="te-content">TELUGU_QUESTION</span><span class="en-content">ENGLISH_QUESTION</span></span>
    <span class="faq-plus"><svg class="ic-sm" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"><path d="M12 5v14M5 12h14"/></svg></span>
  </summary>
  <div class="faq-ans">
    <span class="te-content">TELUGU_ANSWER</span>
    <span class="en-content">ENGLISH_ANSWER</span>
  </div>
</details>
```
*(Repeat `<details class="faq">` block for each question. Minimum 5.)*

### 2.12 Internal links (4–6 links, pill style with info icon)
```html
<div class="ilinks">
  <a href="https://DOMAIN/PAGE.html">
    <svg class="ic" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="9"/><path d="M9.3 9.3a2.7 2.7 0 0 1 5.2 1c0 1.8-2.7 2.3-2.7 4"/><path d="M12 17.5h.01"/></svg>
    <span class="te-content">TELUGU_LINK_TEXT</span><span class="en-content">ENGLISH_LINK_TEXT</span>
  </a>
</div>
```

### 2.13 Reviewer block (E-E-A-T signal — mandatory)
```html
<div class="reviewer">
  <svg class="ic" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"><path d="M12 3l7 3v5c0 4.4-3 7.7-7 9-4-1.3-7-4.6-7-9V6l7-3Z"/><path d="m9 12 2 2 4-4"/></svg>
  <div class="rv-tx">
    <span class="te-content"><strong>వైద్య సమీక్ష మరియు ఆమోదం: DOCTOR_NAME_TE</strong> (CREDENTIALS_SHORT), SPECIALTY_TE. చివరి సమీక్ష: DATE_TE.</span>
    <span class="en-content"><strong>Medically reviewed and approved by DOCTOR_NAME_EN</strong> (CREDENTIALS_SHORT), SPECIALTY_EN. Last reviewed: DATE_EN.</span>
  </div>
</div>
```

### 2.14 Disclaimer (mandatory — copy verbatim, adjust doctor name only)
```html
<div class="disclaimer">
  <span class="te-content">ఈ పేజీ చదవడం లేదా వాట్సాప్‌లో సందేశం పంపడం వైద్యుడు-రోగి సంబంధాన్ని సృష్టించదు. చికిత్స పరీక్ష, మీ రిపోర్టులు మరియు అవసరమైన చోట ట్యూమర్ బోర్డ్ సమీక్షపై ఆధారపడుతుంది. అత్యవసర పరిస్థితిలో వెంటనే దగ్గరి ఆసుపత్రికి వెళ్ళండి. ఈ పేజీ ఆధారంగా ఏ మందునూ మొదలుపెట్టవద్దు లేదా ఆపవద్దు.</span>
  <span class="en-content">Reading this page or messaging on WhatsApp does not create a doctor-patient relationship. Treatment depends on examination, your reports, and tumour-board review where relevant. In an emergency, go to the nearest hospital now. Do not start or stop any medicine based on this page.</span>
</div>
```

---

## 3. Schema fields (jsonLd1 — MedicalWebPage)

```json
{
  "@context": "https://schema.org",
  "@type": "MedicalWebPage",
  "name": "FULL_OG_TITLE",
  "url": "https://DOMAIN/SLUG.html",
  "inLanguage": ["en", "te"],
  "about": {"@type": "MedicalCondition", "name": "TOPIC"},
  "datePublished": "YYYY-MM-DD",
  "dateModified": "YYYY-MM-DD",
  "lastReviewed": "YYYY-MM-DD",
  "author": {
    "@type": "Physician",
    "name": "DOCTOR_FULL_NAME",
    "medicalSpecialty": "Oncologic",
    "hasCredential": ["CREDENTIAL_1", "CREDENTIAL_2"]
  },
  "reviewedBy": {
    "@type": "Physician",
    "name": "DOCTOR_FULL_NAME",
    "medicalSpecialty": "Oncologic",
    "hasCredential": ["CREDENTIAL_1", "CREDENTIAL_2"]
  },
  "publisher": {"@type": "MedicalOrganization", "name": "CLINIC_NAME"}
}
```

**Critical:** `author.name` and `reviewedBy.name` must be the doctor's real full name (e.g. `"Dr. Owais Mohammed"`), never a placeholder.

---

## 4. og:title format

Must be: `PAGE_TITLE | DOCTOR_FULL_NAME`
Example: `"Tumor Markers in Cancer: What They Mean | Dr. Owais Mohammed"`

---

## 5. Content voice rules

- **First person from the doctor**: "I explain…", "In my experience…", "I tell each patient…", "My team will call you"
- **Warm but clinical**: not casual, not textbook — a doctor talking to a worried patient
- **No fabricated statistics**: "studies show X%" is forbidden unless quoting a named standard
- **Conservative claims**: say "may help" not "cures"; "can suggest" not "confirms"
- **Both languages equal**: same depth in Telugu as in English — never translate less content in one language

---

## 6. Bilingual rules

Every visible text node must be wrapped in a span pair:
```html
<span class="te-content">తెలుగు</span><span class="en-content">English</span>
```

- Telugu default, English hidden — CSS and JS toggle flips them
- Telugu script only — no Devanagari, no Kannada, no Malayalam codepoints
- Headings, button text, table cells, link text, form labels — all bilingual
- `<title>`, meta tags, og:title, og:description — English only (for crawlers)

---

## 7. What NOT to generate

| Wrong | Correct |
|---|---|
| `<ul class="related-links">` | `<div class="ilinks">` |
| `<div class="faq"><details>` | `<details class="faq">` |
| `<table>` (no class) | `<table class="cmp">` |
| `<p>` without `.prose` wrapper | `<div class="prose"><p>` |
| `reviewedBy.name: "the doctor"` | real doctor name |
| Answer box with no `.lbl` div | include the `.lbl` with SVG icon |
| FAQ answer in `<p>` directly in `<details>` | wrap in `<div class="faq-ans">` |
| Invent new class names | use only class names defined in this spec |

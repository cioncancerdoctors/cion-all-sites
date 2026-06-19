# Schema Markup Spec — Per Page Type

Every page type has specific Schema.org JSON-LD blocks. Use this as the reference when generating each page.

All schema in **English** (SEO is English-first per requirement).

---

## Universal — On Every Page

### Physician schema (Dr. Imad)
Always present in homepage; can be referenced on other pages.

```json
{
  "@context": "https://schema.org",
  "@type": "Physician",
  "name": "Dr. Mohammed Imaduddin",
  "alternateName": "Dr. Imad",
  "description": "Surgical Oncologist with 14+ years of medical training and surgical practice. Expert in HIPEC, PIPAC, Whipple's Procedure, advanced GI & peritoneal cancer surgery.",
  "url": "https://cioncancerdrimad.com/",
  "image": "https://cioncancerdrimad.com/assets/images/dr-imad-portrait.jpg",
  "telephone": "+91-9063490160",
  "medicalSpecialty": "SurgicalOncology",
  "alumniOf": [
    {"@type": "EducationalOrganization", "name": "AIIMS"},
    {"@type": "EducationalOrganization", "name": "Osmania Medical College"},
    {"@type": "EducationalOrganization", "name": "University Hospital Hannover, Germany"},
    {"@type": "EducationalOrganization", "name": "Charité University Hospital, Berlin"}
  ],
  "memberOf": [
    {"@type": "Organization", "name": "American College of Surgeons (FACS)"},
    {"@type": "Organization", "name": "European Board of Surgery (FEBS)"},
    {"@type": "Organization", "name": "European Society of Surgical Oncology (ESSO)"}
  ]
}
```

### MedicalBusiness / LocalBusiness
For local SEO + GMB alignment.

```json
{
  "@context": "https://schema.org",
  "@type": "MedicalBusiness",
  "name": "CION Cancer Clinics — Dr. Mohammed Imaduddin",
  "image": "https://cioncancerdrimad.com/assets/images/dr-imad-portrait.jpg",
  "url": "https://cioncancerdrimad.com/",
  "telephone": "+91-9063490160",
  "address": {
    "@type": "PostalAddress",
    "addressLocality": "Hyderabad",
    "addressRegion": "Telangana",
    "postalCode": "500016",
    "addressCountry": "IN"
  },
  "openingHours": "Mo-Sa 10:00-17:00",
  "priceRange": "$$"
}
```

---

## Page-Type-Specific Schema

### 1. Cancer Type Pages (Bucket 3)
Add MedicalCondition + FAQPage on top of universals.

```json
{
  "@context": "https://schema.org",
  "@type": "MedicalCondition",
  "name": "Gastric Cancer",
  "alternateName": "Stomach Cancer",
  "description": "Cancer of the stomach lining...",
  "code": {"@type": "MedicalCode", "code": "C16", "codingSystem": "ICD-10"},
  "possibleTreatment": [
    {"@type": "MedicalProcedure", "name": "Total Gastrectomy with D2 Lymphadenectomy"},
    {"@type": "MedicalProcedure", "name": "Partial Gastrectomy"},
    {"@type": "MedicalProcedure", "name": "Chemotherapy"}
  ],
  "signOrSymptom": [
    {"@type": "MedicalSignOrSymptom", "name": "Persistent indigestion"},
    {"@type": "MedicalSignOrSymptom", "name": "Loss of appetite"}
  ]
}
```

Plus FAQPage (see below).

### 2. Treatment / Procedure Pages (Bucket 4)
MedicalProcedure schema.

```json
{
  "@context": "https://schema.org",
  "@type": "MedicalProcedure",
  "name": "HIPEC + Cytoreductive Surgery",
  "alternateName": "Hyperthermic Intraperitoneal Chemotherapy",
  "procedureType": "https://schema.org/SurgicalProcedure",
  "description": "Combined surgical approach...",
  "preparation": "Pre-operative imaging and Tumor Board review.",
  "indication": [
    {"@type": "MedicalIndication", "name": "Peritoneal carcinomatosis from gastric, colorectal, ovarian, or appendix cancer"}
  ]
}
```

### 3. Listicle Pages (Bucket 6)
ItemList schema.

```json
{
  "@context": "https://schema.org",
  "@type": "ItemList",
  "name": "Best Cancer Hospitals in Hyderabad",
  "description": "Editorial guide to leading cancer care centres in Hyderabad.",
  "itemListOrder": "https://schema.org/ItemListUnordered",
  "numberOfItems": 10,
  "itemListElement": [
    {
      "@type": "ListItem",
      "position": 1,
      "item": {
        "@type": "MedicalBusiness",
        "name": "CION Cancer Clinics",
        "url": "https://cioncancerdrimad.com/"
      }
    },
    {
      "@type": "ListItem",
      "position": 2,
      "item": {
        "@type": "MedicalBusiness",
        "name": "Apollo Hospitals (Jubilee Hills)"
      }
    }
  ]
}
```

### 4. FAQ Pages / FAQ Sections (Bucket 7 + every page with FAQs)
FAQPage schema for rich snippets.

```json
{
  "@context": "https://schema.org",
  "@type": "FAQPage",
  "mainEntity": [
    {
      "@type": "Question",
      "name": "What is HIPEC surgery?",
      "acceptedAnswer": {
        "@type": "Answer",
        "text": "HIPEC stands for Hyperthermic Intraperitoneal Chemotherapy..."
      }
    }
  ]
}
```

### 5. Service Pages (Phase 1 service pages)
Service schema.

```json
{
  "@context": "https://schema.org",
  "@type": "MedicalService",
  "name": "PET CT Scan in Hyderabad",
  "provider": {
    "@type": "MedicalBusiness",
    "name": "CION Cancer Clinics — Dr. Mohammed Imaduddin"
  },
  "offers": {
    "@type": "Offer",
    "price": "10000",
    "priceCurrency": "INR",
    "description": "PET CT Scan starting at ₹10,000"
  }
}
```

### 6. Hyderabad Local SEO Pages (Bucket 5)
LocalBusiness + relevant secondary schema (MedicalProcedure or ItemList).

### 7. Breadcrumb (every sub-page)

```json
{
  "@context": "https://schema.org",
  "@type": "BreadcrumbList",
  "itemListElement": [
    {"@type": "ListItem", "position": 1, "name": "Home", "item": "https://cioncancerdrimad.com/"},
    {"@type": "ListItem", "position": 2, "name": "Types of Cancer", "item": "https://cioncancerdrimad.com/types-of-cancer/"},
    {"@type": "ListItem", "position": 3, "name": "Gastric Cancer", "item": "https://cioncancerdrimad.com/types-of-cancer/gastric-stomach-cancer/"}
  ]
}
```

### 8. Article schema (for content-heavy pages — A-Z, in-depth pages)

```json
{
  "@context": "https://schema.org",
  "@type": "MedicalWebPage",
  "headline": "What is HIPEC Surgery?",
  "datePublished": "2026-05-06",
  "dateModified": "2026-05-06",
  "author": {
    "@type": "Person",
    "name": "Dr. Mohammed Imaduddin",
    "jobTitle": "Surgical Oncologist",
    "url": "https://cioncancerdrimad.com/why-dr-imad/"
  },
  "reviewedBy": {
    "@type": "Person",
    "name": "Dr. Mohammed Imaduddin"
  },
  "lastReviewed": "2026-05-06",
  "specialty": "Surgical Oncology"
}
```

---

## Per-Page Schema Combinations

| Page | Schemas |
|---|---|
| Home | Physician + MedicalBusiness |
| Why Dr. Imad | Physician (extended) + Person + MedicalWebPage |
| Advanced Surgeries | Physician + ItemList of MedicalProcedure |
| Book Appointment | MedicalBusiness + ContactPoint |
| Cancer type page | MedicalCondition + FAQPage + Breadcrumb + MedicalWebPage |
| Treatment page | MedicalProcedure + FAQPage + Breadcrumb + MedicalWebPage |
| Service page (PET CT etc.) | MedicalService + Offer + FAQPage + Breadcrumb |
| Hyderabad SEO page | LocalBusiness + Service + FAQPage + Breadcrumb |
| Listicle | ItemList + FAQPage + Breadcrumb |
| A-Z Q&A page | MedicalWebPage + FAQPage + Breadcrumb |
| Landing page (ad) | MedicalBusiness only (noindex) |
| Privacy / Thank You / 404 | Minimal — Organization only |

---

## Validation

After each page goes live:
1. Test with **Google Rich Results Test:** https://search.google.com/test/rich-results
2. Test with **Schema.org Validator:** https://validator.schema.org/
3. Verify in Google Search Console → Enhancements → which rich result types Google detected

---

## NEVER Add to Schema

- Patient names
- Specific medical advice (don't put treatment dosages in schema)
- Outcome promises ("100% cure rate")
- Fake reviews (`AggregateRating` only if you have real, verifiable reviews)
- Prices that are not actually charged

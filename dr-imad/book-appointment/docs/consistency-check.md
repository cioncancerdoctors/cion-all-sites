# Consistency Check — Cross-Profile Alignment

Information about Dr. Imad must be **identical** across all his online profiles. Mismatches kill trust + conversions when patients cross-check.

---

## Master Source of Truth

**File:** `/data/doctor-facts.json`

All profiles must align with this. If any profile shows different info, update the profile (don't update the JSON).

---

## Profiles to Audit

### Profile 1: Website (cioncancerdrimad.com)
- [x] Source of truth (this is what we're building)

### Profile 2: Google Business Profile (GMB)
- [ ] NAP matches: "Dr. Mohammed Imaduddin, CION Cancer Clinics, Hyderabad, Telangana 500016"
- [ ] Phone: +91 90634 90160
- [ ] Hours: Mon-Sat 10AM-5PM
- [ ] Website link: https://cioncancerdrimad.com/?utm_source=gmb&utm_medium=organic
- [ ] Description includes: "AIIMS, Germany & Europe-trained"
- [ ] Services list matches: HIPEC, PIPAC, Whipple's, Surgical Oncology
- [ ] Languages: English, Telugu, Hindi, Urdu

**Action:** Update GMB if any field is missing or different.

### Profile 3: Practo (if Dr. Imad has profile)
- [ ] Name: Dr. Mohammed Imaduddin
- [ ] Specialty: Surgical Oncology
- [ ] Experience: 14+ years
- [ ] Qualifications match: M.B.B.S, MS, M.Ch (AIIMS), FEBS, FACS
- [ ] Hospital: CION Cancer Clinics
- [ ] Languages: English, Telugu, Hindi, Urdu

**Action:** Claim profile if not claimed; align fields.

### Profile 4: JustDial (if listed)
- [ ] Same NAP
- [ ] Phone: +91 90634 90160
- [ ] Specialty correct

### Profile 5: CION main brand site (cioncancerclinics.com)
- [ ] Dr. Imad's profile page exists and matches
- [ ] Photo same as our website portrait
- [ ] Credentials match
- [ ] Link to cioncancerdrimad.com from his bio page

### Profile 6: LinkedIn (if maintained)
- [ ] Same name, qualifications
- [ ] Current role: Consultant Surgical Oncologist at CION Cancer Clinics
- [ ] Education: AIIMS (M.Ch), Osmania (MBBS, MS), University Hospital Hannover (Fellowship)

### Profile 7: ResearchGate / ORCID (publications)
- [ ] All 4 named publications listed
- [ ] DOI links work

---

## Information That Must Match Everywhere

| Field | Value | Status |
|---|---|---|
| Name (full) | Dr. Mohammed Imaduddin | □ |
| Name (short) | Dr. Imad | □ |
| Specialty | Surgical Oncology | □ |
| Sub-specialty | Advanced GI & Peritoneal Cancer Surgeon | □ |
| Experience | 14+ years | □ |
| Qualifications | M.B.B.S, MS, M.Ch (AIIMS), FEBS, FACS | □ |
| Hospital | CION Cancer Clinics | □ |
| City | Hyderabad | □ |
| State | Telangana | □ |
| Pin | 500016 | □ |
| Phone | +91 90634 90160 | □ |
| Hours | Mon–Sat 10AM–5PM | □ |
| Languages | English, Telugu, Hindi, Urdu | □ |

---

## Cross-Profile Audit Process

**Schedule:** Quarterly (Jan, Apr, Jul, Oct).

**Steps:**
1. Open `doctor-facts.json` (canonical)
2. Open each profile in tabs
3. Compare row-by-row
4. Document mismatches
5. Update profile (NEVER update doctor-facts.json — it's source of truth)
6. Re-verify after 24h (some profiles cache)

---

## Common Mismatches to Watch

- **Phone format** — some profiles strip "+91", some have "+91-XXXXX", normalize to one format
- **Specialty wording** — "Cancer Surgeon" vs "Surgical Oncologist" — use "Surgical Oncologist"
- **Hospital name** — "CION" vs "CION Cancer Clinics" vs "CION Hospital" — use "CION Cancer Clinics"
- **AIIMS** — "AIIMS" only (not "AIIMS New Delhi" or "All India Institute") per memory
- **Hours format** — "10:00 AM - 5:00 PM" vs "10am - 5pm" — use "10:00 AM – 5:00 PM" with em-dash

---

## When CION Onboarding Other Doctors

If/when we replicate this site structure to other CION doctors (Dr. Owais, Dr. Sandeep, etc.):
1. Each gets their own `doctor-facts.json`
2. Each must run their own consistency check
3. CION doctors should cross-link only on listicle pages, not personal bios

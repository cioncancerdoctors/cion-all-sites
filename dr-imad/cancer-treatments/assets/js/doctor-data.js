/* ─────────────────────────────────────────────────────────────
   doctor-data.js
   Exposes window.CION_DOCTOR with key facts used across pages.
   For canonical source see /data/doctor-facts.json
───────────────────────────────────────────────────────────── */

window.CION_DOCTOR = {
  doctor_name_key: "dr_imaduddin_mohammed",
  doctor_name: "Dr. Mohammed Imaduddin",
  doctor_short: "Dr. Imad",
  doctor_specialty_key: "surgical_oncology",
  doctor_specialty: "Surgical Oncology",
  experience_years: 14,
  experience_phrase: "14+ years",
  phone_e164: "919063490160",
  phone_display: "+91 90634 90160",
  languages: ["English", "Telugu", "Hindi", "Urdu"],
  hours: "Mon–Sat · 10:00 AM – 5:00 PM",
  centres: [
    { key: "kukatpally", label: "Kukatpally" },
    { key: "kompally", label: "Kompally" },
    { key: "ameerpet", label: "Ameerpet" },
    { key: "tolichowki", label: "Tolichowki" },
    { key: "masab_tank", label: "Masab Tank" },
    { key: "lb_nagar", label: "LB Nagar" },
    { key: "banjara_hills", label: "Banjara Hills" }
  ],
  conditions: [
    { key: "gastric_cancer", label: "Stomach / Gastric Cancer" },
    { key: "colorectal_cancer", label: "Colorectal Cancer" },
    { key: "ovarian_cancer", label: "Ovarian Cancer" },
    { key: "hipec_peritoneal", label: "Peritoneal / HIPEC" },
    { key: "breast_cancer", label: "Breast Cancer" },
    { key: "lung_cancer", label: "Lung Cancer" },
    { key: "other", label: "Other Cancer" },
    { key: "unknown", label: "Not Sure" }
  ],
  wa_messages: {
    appointment: "Hello, I would like to book a consultation with Dr. Imaduddin at CION Cancer Clinics.",
    second_opinion: "Hello, I would like a second surgical opinion from Dr. Imaduddin.",
    online_second_opinion: "Hello, I am sharing my reports for Dr. Imaduddin's free online second opinion.",
    cost: "Hello, I would like a cost estimate for cancer surgery.",
    report_review: "Hello, I would like to share my reports for review by Dr. Imaduddin.",
    pet_ct: "Hello, I would like to book a PET CT scan at the special rate.",
    genetic_testing: "Hello, I would like more information on cancer genetic testing.",
    cancer_vaccination: "Hello, I would like more information on cancer vaccination.",
    general: "Hello, I would like to consult Dr. Imaduddin at CION Cancer Clinics."
  }
};

window.cionWaUrl = function(intent, extra) {
  var msg = (window.CION_DOCTOR.wa_messages[intent] || window.CION_DOCTOR.wa_messages.general);
  if (extra) msg += " " + extra;
  return "https://wa.me/" + window.CION_DOCTOR.phone_e164 + "?text=" + encodeURIComponent(msg);
};
window.cionTelUrl = function() {
  return "tel:+" + window.CION_DOCTOR.phone_e164;
};

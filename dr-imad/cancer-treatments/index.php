<?php
$page_title       = "Dr. Mohammed Imaduddin | Surgical Oncologist Hyderabad | HIPEC, GI Cancer Surgery";
$page_description = "I am Dr. Mohammed Imaduddin, an AIIMS and Hannover-trained Head of Department, Surgical Oncology in Hyderabad. I treat GI cancers and peritoneal cancers, including HIPEC, PIPAC and Whipple's surgery.";
$page_canonical   = "https://cioncancerdrimad.com/";
$page_robots      = "index, follow, max-image-preview:large";

require __DIR__ . '/_inc.php';
?>
<!DOCTYPE html>
<html lang="te">
<head>
<?php include $ROOT . '/partials/meta-tags.php'; ?>
<script type="application/ld+json">
{"@context":"https://schema.org","@type":"Physician","name":"Dr. Mohammed Imaduddin","alternateName":"Dr. Imad","medicalSpecialty":"SurgicalOncology","url":"https://cioncancerdrimad.com/","image":"https://cioncancerdrimad.com/assets/images/dr-imad-portrait.jpg","telephone":"+91-9063490160","areaServed":{"@type":"City","name":"Hyderabad"},"affiliation":{"@type":"MedicalOrganization","name":"CION Cancer Clinics"}}
</script>

<script type="application/ld+json">{
  "@context":"https://schema.org",
  "@type":"Physician",
  "name":"Dr. Mohammed Imaduddin",
  "jobTitle":"Head of Department, Surgical Oncology",
  "affiliation":{"@type":"MedicalOrganization","name":"CION Cancer Clinics","url":"https://cioncancerdrimad.com/"},
  "alumniOf":[{"@type":"CollegeOrUniversity","name":"AIIMS"},{"@type":"CollegeOrUniversity","name":"University Hospital Hannover"}],
  "url":"https://cioncancerdrimad.com/",
  "telephone":"+91-9063490160",
  "areaServed":{"@type":"City","name":"Hyderabad"}
}</script>
<script type="application/ld+json">{"@context":"https://schema.org","@type":"BreadcrumbList","itemListElement":[{"@type":"ListItem","position":1,"name":"Home","item":"https://cioncancerdrimad.com/"}]}</script>
<script>
window.cionPageData = {
  doctor_name:       "Dr. Mohammed Imaduddin",
  doctor_speciality: "Surgical Oncology",
  page_type:         "doctor_landing_page",
  intent:            "general_consultation",
  offer_type:        "consultation",
  cancer_type:       "",
  location:          "Hyderabad",
  language:          "Telugu",
  funnel_stage:      "high_intent"
};
</script>
</head>
<body data-page-type="homepage" data-page-name="home">

<?php include $ROOT . '/partials/header.php'; ?>

<!-- HERO -->
<section class="hero-home">
  <!-- Photo panel: photo fills top, name+creds overlay at bottom (mobile) / right half (desktop) -->
  <div class="hero-photo-panel">
    <picture>
      <source srcset="/assets/images/dr-imad-face-crop.webp" type="image/webp">
      <img src="/assets/images/dr-imad-face-crop.jpg" alt="Dr. Mohammed Imaduddin — Head of Department, Surgical Oncology, Hyderabad" width="600" height="700" loading="eager">
    </picture>
    <!-- Name + credentials overlay — visible on mobile only, hidden on desktop -->
    <div class="hero-photo-overlay">
      <div class="hero-desig"><span class="te-content">హెడ్ ఆఫ్ డిపార్ట్‌మెంట్, సర్జికల్ ఆంకాలజీ · హైదరాబాద్</span><span class="en-content">Head of Department, Surgical Oncology · Hyderabad</span></div>
      <div class="hero-name"><span class="te-content">డా. మహమ్మద్ ఇమాదుద్దీన్</span><span class="en-content">Dr. Mohammed Imaduddin</span></div>
      <div class="hero-creds-mobile">M.Ch (AIIMS) &middot; ESSO Fellow Hannover &middot; FEBS &middot; FACS &middot; 14+ Years</div>
    </div>
  </div>

  <!-- Text panel: tagline + lede + CTAs (below photo on mobile, left half on desktop) -->
  <div class="hero-text-panel">
    <!-- Eyebrow + name shown only on desktop (mobile sees it in the photo overlay) -->
    <div class="hero-desktop-eyebrow"><span class="te-content">హెడ్ ఆఫ్ డిపార్ట్‌మెంట్, సర్జికల్ ఆంకాలజీ · హైదరాబాద్ · Dr. Mohammed Imaduddin</span><span class="en-content">Dr. Mohammed Imaduddin · Head of Department, Surgical Oncology · Hyderabad</span></div>
    <h1 class="hero-h1">
      <span class="te-content">కష్టమైన cancer surgeries కోసం, <em>నేను ఇక్కడ ఉన్నాను.</em></span>
      <span class="en-content">For the cancer surgeries others won&rsquo;t take on, <em>I&rsquo;m here.</em></span>
    </h1>
    <p class="hero-lede">
      <span class="te-block">AIIMS M.Ch తరువాత Germany లో Prof. Beate Rau దగ్గర peritoneal surface malignancy fellowship చేశాను. "Surgery possible కాదు" అని చెప్పారా? నాకు మీ reports చూపించండి.</span>
      <span class="en-block">After my M.Ch at AIIMS, I trained under Prof. Beate Rau in Germany on peritoneal surface malignancy. If someone has told you surgery isn&rsquo;t possible, show me your reports first.</span>
    </p>
    <div class="hero-ctas">
      <a href="https://wa.me/919063490160?text=Hello%20Dr.%20Imad%2C%20I%20would%20like%20to%20share%20my%20reports%20with%20you." class="btn btn-wa" data-cta="whatsapp" data-cta-pos="hero" data-intent="consultation" target="_blank" rel="noopener">
        <svg class="btn-icon" viewBox="0 0 24 24" fill="currentColor"><path d="M17.472 14.382c-.297-.149-1.758-.867-2.03-.967-.273-.099-.471-.148-.67.15-.197.297-.767.966-.94 1.164-.173.199-.347.223-.644.075-.297-.15-1.255-.463-2.39-1.475-.883-.788-1.48-1.761-1.653-2.059-.173-.297-.018-.458.13-.606.134-.133.298-.347.446-.52.149-.174.198-.298.298-.497.099-.198.05-.371-.025-.52-.075-.149-.669-1.612-.916-2.207-.242-.579-.487-.5-.669-.51-.173-.008-.371-.01-.57-.01-.198 0-.52.074-.792.372-.272.297-1.04 1.016-1.04 2.479 0 1.462 1.065 2.875 1.213 3.074.149.198 2.096 3.2 5.077 4.487.709.306 1.262.489 1.694.625.712.227 1.36.195 1.871.118.571-.085 1.758-.719 2.006-1.413.248-.694.248-1.289.173-1.413-.074-.124-.272-.198-.57-.347m-5.421 7.403h-.004a9.87 9.87 0 01-5.031-1.378l-.361-.214-3.741.982.998-3.648-.235-.374a9.86 9.86 0 01-1.51-5.26c.001-5.45 4.436-9.884 9.888-9.884 2.64 0 5.122 1.03 6.988 2.898a9.825 9.825 0 012.893 6.994c-.003 5.45-4.437 9.884-9.885 9.884m8.413-18.297A11.815 11.815 0 0012.05 0C5.495 0 .16 5.335.157 11.892c0 2.096.547 4.142 1.588 5.945L.057 24l6.305-1.654a11.882 11.882 0 005.683 1.448h.005c6.554 0 11.89-5.335 11.893-11.893A11.821 11.821 0 0020.464 3.488"/></svg>
        <span class="te-content">Reports షేర్ చేయండి</span><span class="en-content">Send your reports</span>
      </a>
      <a href="/free-online-second-opinion/" class="btn btn-light" data-cta="link" data-cta-pos="hero" data-intent="second_opinion">
        <span class="te-content">Free Online Second Opinion</span><span class="en-content">Free Online Second Opinion</span>
      </a>
    </div>
  </div>
</section>

<!-- STATS STRIP -->
<section class="section section-grey" style="padding-top:36px; padding-bottom:36px;">
  <div class="section-inner">
    <div class="stat-grid">
      <div class="stat-card"><div class="stat-num">14+</div><div class="stat-label"><span class="te-content">సంవత్సరాల అనుభవం</span><span class="en-content">Years of Practice</span></div></div>
      <div class="stat-card"><div class="stat-num">15+</div><div class="stat-label"><span class="te-content">పబ్లికేషన్స్</span><span class="en-content">Publications</span></div></div>
      <div class="stat-card"><div class="stat-num">5</div><div class="stat-label"><span class="te-content">ఇంటర్నేషనల్ Fellowships</span><span class="en-content">International Fellowships</span></div></div>
      <div class="stat-card"><div class="stat-num">7</div><div class="stat-label"><span class="te-content">హైదరాబాద్ Centres</span><span class="en-content">Hyderabad Centres</span></div></div>
    </div>
  </div>
</section>

<!-- FEATURED SERVICES -->
<section class="section">
  <div class="section-inner">
    <div class="sec-eyebrow"><span class="te-content">Most Asked Services</span><span class="en-content">Most Asked Services</span></div>
    <h2 class="sec-h"><span class="te-content">పేషెంట్లు ఎక్కువగా <em>నన్ను అడిగే విషయాలు</em></span><span class="en-content">What patients <em>ask me about most</em></span></h2>

    <div class="service-grid">
      <a href="/free-second-opinion/" class="service-card">
        <div class="service-card-header"><div class="service-icon">💬</div><h4><span class="te-content">Free Second Opinion</span><span class="en-content">Free Second Opinion</span></h4></div>
        <p><span class="te-content">"Surgery possible కాదు" అని ఎవరైనా చెప్పారా? Reports తీసుకువచ్చి నన్ను కలవండి. Charge లేదు.<span class="service-arrow"> →</span></span><span class="en-content">Told surgery isn&rsquo;t possible? Bring your reports. A fresh perspective is your right. No fee for the first consultation.<span class="service-arrow"> →</span></span></p>
      </a>
      <a href="/free-online-second-opinion/" class="service-card">
        <div class="service-card-header"><div class="service-icon">📄</div><h4><span class="te-content">Free Online Second Opinion</span><span class="en-content">Free Online Second Opinion</span></h4></div>
        <p><span class="te-content">Hospital రాకుండానే. WhatsApp లో reports పంపండి, 48 hours లోపు నేను personally review చేస్తాను.<span class="service-arrow"> →</span></span><span class="en-content">Without coming in. Send reports on WhatsApp, I personally review and reply within 48 hours.<span class="service-arrow"> →</span></span></p>
      </a>
      <a href="/pet-ct-scan-hyderabad/" class="service-card featured">
        <div class="service-card-header"><div class="service-icon">🔬</div><h4><span class="te-content">PET CT Scan · ₹10,000</span><span class="en-content">PET CT Scan · ₹10,000</span></h4></div>
        <p><span class="te-content">CION-affiliated centres లో lowest rate*. Cancer staging, treatment planning.<span class="service-arrow"> →</span></span><span class="en-content">Lowest rate among CION-affiliated centres*. Cancer staging and treatment planning.<span class="service-arrow"> →</span></span></p>
      </a>
      <a href="/cancer-treatments/hipec-pipac/" class="service-card">
        <div class="service-card-header"><div class="service-icon">🩺</div><h4>HIPEC &amp; PIPAC</h4></div>
        <p><span class="te-content">Peritoneal cancer కి advanced surgical treatment. ESSO Hannover fellowship లో specifically train అయిన technique.<span class="service-arrow"> →</span></span><span class="en-content">Advanced surgical treatment for peritoneal cancer. The technique I trained in specifically at my ESSO Hannover Fellowship.<span class="service-arrow"> →</span></span></p>
      </a>
      <a href="/cancer-treatments/whipples-procedure/" class="service-card">
        <div class="service-card-header"><div class="service-icon">⚕️</div><h4><span class="te-content">Whipple's Procedure</span><span class="en-content">Whipple&rsquo;s Procedure</span></h4></div>
        <p><span class="te-content">Pancreatic cancer surgery. AIIMS M.Ch training లో regularly perform చేసిన most demanding GI operation.<span class="service-arrow"> →</span></span><span class="en-content">Surgery for pancreatic cancer. One of the most demanding GI operations, which I performed regularly at AIIMS.<span class="service-arrow"> →</span></span></p>
      </a>
      <a href="/genetic-testing-for-cancer/" class="service-card">
        <div class="service-card-header"><div class="service-icon">🧬</div><h4><span class="te-content">Genetic Testing</span><span class="en-content">Genetic Testing</span></h4></div>
        <p><span class="te-content">Family లో cancer history ఉందా? BRCA, Lynch syndrome screening. ₹10,000 నుండి.<span class="service-arrow"> →</span></span><span class="en-content">Cancer history in your family? BRCA and Lynch syndrome screening. Starting at ₹10,000.<span class="service-arrow"> →</span></span></p>
      </a>
    </div>
  </div>
</section>

<!-- WHY DR IMAD - personal voice section -->
<section class="section section-grey">
  <div class="section-inner">
    <div class="sec-eyebrow"><span class="te-content">A Note From Dr. Imad</span><span class="en-content">A Note From Dr. Imad</span></div>
    <h2 class="sec-h"><span class="te-content"><em>నన్ను</em> ఎందుకు consult చేయాలి?</span><span class="en-content"><em>Why</em> consult me?</span></h2>

    <div class="prose">
      <div class="te-block">
        <p>Cancer treatment లో ఒక్క విషయం clear గా చెబుతాను. <strong>Surgical oncology general surgery కంటే వేరు speciality</strong>. AIIMS లో M.Ch training అంటే 11+ years dedicated medical education, ఇది cancer surgery specifically కోసం. ఈ difference outcomes లో ముఖ్యమైనది.</p>
        <p>Hannover లో నా ESSO Peritoneal Surface Malignancy Fellowship time లో, Prof. Beate Rau పదే పదే ఒక విషయం repeat చేసేవారు. <em>"Patient selection comes before surgical skill."</em> CRS+HIPEC consider చేసే ప్రతి case లో PCI (Peritoneal Carcinomatosis Index) score systematic గా calculate చేయడం, surgery feasibility అంచనా వేయడం nonnegotiable. ఈ discipline నేను Hyderabad practice లో follow అవుతున్నాను.</p>
        <p>నేను patients కి ఒక promise చేస్తాను. <strong>I will not recommend surgery I would not recommend for my own family.</strong> Patient candidate కాకపోతే, చెబుతాను. Better option ఉంటే, refer చేస్తాను. Honest discussion <em>బాధ्</em>తో ఉన్న family కి due ఇస్తుంది.</p>
        <p style="font-size:13px; color:var(--ink3); margin-top:18px;"><a href="/why-dr-imad/"><span class="te-content">పూర్తి profile, training, publications →</span><span class="en-content">Full profile, training, publications →</span></a></p>
      </div>
      <div class="en-block">
        <p>I&rsquo;ll be direct about one thing in cancer treatment. <strong>Surgical oncology is a different speciality from general surgery.</strong> An M.Ch from AIIMS means 11+ years of dedicated medical training, specifically for cancer surgery. That difference matters in outcomes.</p>
        <p>During my ESSO Peritoneal Surface Malignancy Fellowship in Hannover, Prof. Beate Rau drilled one principle into us repeatedly. <em>"Patient selection comes before surgical skill."</em> For every case where CRS+HIPEC is considered, calculating the PCI (Peritoneal Carcinomatosis Index) score systematically and assessing feasibility is non-negotiable. That discipline is something I carry into my Hyderabad practice.</p>
        <p>I make patients one promise. <strong>I will not recommend a surgery I would not recommend for my own family.</strong> If you are not a candidate, I will tell you. If a better option exists somewhere else, I will refer you there. An honest conversation is what a worried family deserves.</p>
        <p style="font-size:13px; color:var(--ink3); margin-top:18px;"><a href="/why-dr-imad/">Full profile, training and publications →</a></p>
      </div>
    </div>
  </div>
</section>

<!-- CANCER TYPES -->
<section class="section">
  <div class="section-inner">
    <div class="sec-eyebrow"><span class="te-content">Cancer Types</span><span class="en-content">Cancer Types I Treat</span></div>
    <h2 class="sec-h"><span class="te-content">నేను treat చేసే <em>cancer types</em></span><span class="en-content">Cancer types <em>I treat</em></span></h2>
    <div class="reason-grid">
      <a href="/types-of-cancer/peritoneal-cancer/" class="service-card"><div class="service-card-header"><div class="service-icon">🎗️</div><h4>Peritoneal Cancer</h4></div><p>Primary &amp; metastatic peritoneal cancers. CRS, HIPEC, PIPAC.<span class="service-arrow"> →</span></p></a>
      <a href="/types-of-cancer/gastric-stomach-cancer/" class="service-card"><div class="service-card-header"><div class="service-icon">🎗️</div><h4>Gastric (Stomach) Cancer</h4></div><p>D2 gastrectomy. My AIIMS thesis area, 15+ published papers.<span class="service-arrow"> →</span></p></a>
      <a href="/types-of-cancer/colorectal-cancer/" class="service-card"><div class="service-card-header"><div class="service-icon">🎗️</div><h4>Colorectal Cancer</h4></div><p>TME for rectal cancer, laparoscopic colon resection.<span class="service-arrow"> →</span></p></a>
      <a href="/types-of-cancer/pancreatic-cancer/" class="service-card"><div class="service-card-header"><div class="service-icon">🎗️</div><h4>Pancreatic Cancer</h4></div><p>Whipple&rsquo;s Procedure, distal pancreatectomy.<span class="service-arrow"> →</span></p></a>
      <a href="/types-of-cancer/ovarian-cancer/" class="service-card"><div class="service-card-header"><div class="service-icon">🎗️</div><h4>Ovarian Cancer</h4></div><p>Debulking surgery, interval debulking, CRS+HIPEC.<span class="service-arrow"> →</span></p></a>
      <a href="/types-of-cancer/oesophageal-cancer/" class="service-card"><div class="service-card-header"><div class="service-icon">🎗️</div><h4>Oesophageal Cancer</h4></div><p>Minimally Invasive Esophagectomy (MIE).<span class="service-arrow"> →</span></p></a>
      <a href="/types-of-cancer/liver-cancer/" class="service-card"><div class="service-card-header"><div class="service-icon">🎗️</div><h4>Liver Cancer</h4></div><p>Hepatectomy, colorectal liver metastases resection.<span class="service-arrow"> →</span></p></a>
      <a href="/types-of-cancer/appendix-cancer-pmp/" class="service-card"><div class="service-card-header"><div class="service-icon">🎗️</div><h4>Appendix Cancer / PMP</h4></div><p>Pseudomyxoma peritonei, CRS+HIPEC long-term curative.<span class="service-arrow"> →</span></p></a>
    </div>
  </div>
</section>

<!-- FORM -->

<script type="application/ld+json">{"@context":"https://schema.org","@type":"FAQPage","mainEntity":[{"@type":"Question","name":"Who is Dr. Mohammed Imaduddin?","acceptedAnswer":{"@type":"Answer","text":"Dr. Mohammed Imaduddin is Head of Department, Surgical Oncology at CION Cancer Clinics, Hyderabad. He holds M.Ch from AIIMS and an ESSO Fellowship from University Hospital Hannover, Germany."}},{"@type":"Question","name":"Does Dr. Imaduddin offer HIPEC in Hyderabad?","acceptedAnswer":{"@type":"Answer","text":"Yes. He trained specifically in HIPEC under Prof. Beate Rau at University Hospital Hannover. He offers CRS+HIPEC and PIPAC at CION Cancer Clinics, Hyderabad."}},{"@type":"Question","name":"Is there a free second opinion available?","acceptedAnswer":{"@type":"Answer","text":"Yes. Dr. Imaduddin offers a free first consultation and free online second opinion via WhatsApp. Call or WhatsApp +91 90634 90160."}}]}</script>
<section class="section section-grey" data-section-track="faq">
  <div class="section-inner">
    <div class="sec-eyebrow">FAQ</div>
    <h2 class="sec-h"><span class="te-content">తరచుగా అడిగే <em>Questions</em></span><span class="en-content">Frequently Asked <em>Questions</em></span></h2>
    <div class="faq-list">
      <div class="faq-item">
        <button class="faq-q" type="button" aria-expanded="false">Who is Dr. Mohammed Imaduddin?</button>
        <div class="faq-a" hidden>Dr. Mohammed Imaduddin is Head of Department, Surgical Oncology at CION Cancer Clinics, Hyderabad. He holds M.Ch from AIIMS and an ESSO Fellowship from University Hospital Hannover, Germany.</div>
      </div>
      <div class="faq-item">
        <button class="faq-q" type="button" aria-expanded="false">Does Dr. Imaduddin offer HIPEC in Hyderabad?</button>
        <div class="faq-a" hidden>Yes. He trained specifically in HIPEC under Prof. Beate Rau at University Hospital Hannover. He offers CRS+HIPEC and PIPAC at CION Cancer Clinics, Hyderabad.</div>
      </div>
      <div class="faq-item">
        <button class="faq-q" type="button" aria-expanded="false">Is there a free second opinion available?</button>
        <div class="faq-a" hidden>Yes. Dr. Imaduddin offers a free first consultation and free online second opinion via WhatsApp. Call or WhatsApp +91 90634 90160.</div>
      </div>
    </div>
  </div>
</section>
<section class="section section-grey" id="appointment">
  <div class="section-inner">
    <div class="sec-eyebrow"><span class="te-content">Get In Touch</span><span class="en-content">Get In Touch</span></div>
    <h2 class="sec-h" style="text-align:center; margin-left:auto; margin-right:auto;"><span class="te-content">Reports తీసుకువచ్చి, <em>నాతో మాట్లాడండి</em></span><span class="en-content">Bring your reports. <em>Let&rsquo;s talk.</em></span></h2>
    <?php
    $form_intent     = 'consultation';
    $form_heading_te = 'Free Consultation Request';
    $form_heading_en = 'Request a Free Consultation';
    include $ROOT . '/partials/form-module.php';
    ?>
  </div>
</section>

<?php
$cta_intent     = 'consultation';
$cta_heading_te = 'Cancer treatment గురించి clear answers కోసం';
$cta_heading_en = 'For clear answers about cancer treatment';
$cta_wa_msg     = 'Hello%20Dr.%20Imad%2C%20I%20would%20like%20to%20discuss%20my%20case.';
include $ROOT . '/partials/cta-strip.php';
?>

<?php include $ROOT . '/partials/footer.php'; ?>
</body>
</html>

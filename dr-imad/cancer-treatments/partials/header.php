<?php
/* header.php — Site header with desktop nav + mobile drawer + sticky bar */
?>
<header class="site-header">
  <div class="header-inner">
    <a href="/" class="brand">
      <span class="brand-name"><span class="te-content">డా. మహమ్మద్ ఇమాదుద్దీన్</span><span class="en-content">Dr. Mohammed Imaduddin</span></span>
      <span class="brand-sub"><span class="te-content">హెడ్ ఆఫ్ డిపార్ట్‌మెంట్, సర్జికల్ ఆంకాలజీ · హైదరాబాద్</span><span class="en-content">Head of Department, Surgical Oncology · Hyderabad</span></span>
    </a>

    <nav class="main-nav" aria-label="Main navigation">
      <ul>
        <li><a href="/why-dr-imad/"><span class="te-content">డా. ఇమాద్</span><span class="en-content">About</span></a></li>
        <li><a href="/advanced-surgeries/"><span class="te-content">Surgeries</span><span class="en-content">Surgeries</span></a></li>
        <li><a href="/cancer-treatments/surgical-oncology/"><span class="te-content">Treatments</span><span class="en-content">Treatments</span></a></li>
        <li><a href="/types-of-cancer/peritoneal-cancer/"><span class="te-content">Cancer Types</span><span class="en-content">Cancer Types</span></a></li>
        <li><a href="/free-second-opinion/"><span class="te-content">2nd Opinion</span><span class="en-content">2nd Opinion</span></a></li>
        <li><a href="/book-appointment/"><span class="te-content">Book</span><span class="en-content">Book</span></a></li>
      </ul>
    </nav>

    <div class="header-right">
      <a href="tel:+919063490160" class="header-phone phone-number" data-cta="call" data-cta-pos="header" data-intent="appointment">
        <svg class="btn-icon" viewBox="0 0 24 24" fill="currentColor"><path d="M20 15.5c-1.25 0-2.45-.2-3.57-.57-.35-.11-.74-.03-1.02.24l-2.2 2.2c-2.83-1.44-5.15-3.75-6.59-6.58l2.2-2.21c.28-.27.36-.66.25-1.01C8.7 6.45 8.5 5.25 8.5 4c0-.55-.45-1-1-1H4c-.55 0-1 .45-1 1 0 9.39 7.61 17 17 17 .55 0 1-.45 1-1v-3.5c0-.55-.45-1-1-1z"/></svg>
        +91 90634 90160
      </a>
      <div class="lang-toggle" role="group" aria-label="Language">
        <button class="active" id="lang-te" type="button" aria-label="Telugu">తె</button>
        <button id="lang-en" type="button" aria-label="English">EN</button>
      </div>
      <button class="hamburger" id="hamburger" aria-label="Open menu"><span></span><span></span><span></span></button>
    </div>
  </div>
</header>

<!-- Mobile drawer -->
<div class="drawer-overlay" id="drawerOverlay"></div>
<aside class="mobile-drawer" id="mobileDrawer" aria-label="Mobile navigation">
  <button class="mobile-drawer-close" id="drawerClose" aria-label="Close menu">×</button>
  <ul>
    <li><a href="/"><span class="te-content">హోమ్</span><span class="en-content">Home</span></a></li>
    <li><a href="/why-dr-imad/"><span class="te-content">డా. ఇమాద్ గురించి</span><span class="en-content">About Dr. Imad</span></a></li>
    <li><a href="/advanced-surgeries/"><span class="te-content">Advanced Surgeries</span><span class="en-content">Advanced Surgeries</span></a></li>
    <li><a href="/cancer-treatments/surgical-oncology/"><span class="te-content">Cancer Treatments</span><span class="en-content">Cancer Treatments</span></a></li>
    <li><a href="/types-of-cancer/peritoneal-cancer/"><span class="te-content">Types of Cancer</span><span class="en-content">Types of Cancer</span></a></li>
    <li><a href="/free-second-opinion/"><span class="te-content">Free Second Opinion</span><span class="en-content">Free Second Opinion</span></a></li>
    <li><a href="/free-online-second-opinion/"><span class="te-content">Online Second Opinion</span><span class="en-content">Online Second Opinion</span></a></li>
    <li><a href="/pet-ct-scan-hyderabad/"><span class="te-content">PET CT Scan</span><span class="en-content">PET CT Scan</span></a></li>
    <li><a href="/book-appointment/"><span class="te-content">Book Appointment</span><span class="en-content">Book Appointment</span></a></li>
  </ul>
  <div style="margin-top:18px; display:flex; flex-direction:column; gap:8px;">
    <a href="https://wa.me/919063490160?text=Hello%2C%20I%20would%20like%20to%20book%20a%20consultation%20with%20Dr.%20Imaduddin." class="btn btn-wa" data-cta="whatsapp" data-cta-pos="drawer" data-intent="appointment" target="_blank" rel="noopener">
      <svg class="btn-icon" viewBox="0 0 24 24" fill="currentColor"><path d="M17.472 14.382c-.297-.149-1.758-.867-2.03-.967-.273-.099-.471-.148-.67.15-.197.297-.767.966-.94 1.164-.173.199-.347.223-.644.075-.297-.15-1.255-.463-2.39-1.475-.883-.788-1.48-1.761-1.653-2.059-.173-.297-.018-.458.13-.606.134-.133.298-.347.446-.52.149-.174.198-.298.298-.497.099-.198.05-.371-.025-.52-.075-.149-.669-1.612-.916-2.207-.242-.579-.487-.5-.669-.51-.173-.008-.371-.01-.57-.01-.198 0-.52.074-.792.372-.272.297-1.04 1.016-1.04 2.479 0 1.462 1.065 2.875 1.213 3.074.149.198 2.096 3.2 5.077 4.487.709.306 1.262.489 1.694.625.712.227 1.36.195 1.871.118.571-.085 1.758-.719 2.006-1.413.248-.694.248-1.289.173-1.413-.074-.124-.272-.198-.57-.347m-5.421 7.403h-.004a9.87 9.87 0 01-5.031-1.378l-.361-.214-3.741.982.998-3.648-.235-.374a9.86 9.86 0 01-1.51-5.26c.001-5.45 4.436-9.884 9.888-9.884 2.64 0 5.122 1.03 6.988 2.898a9.825 9.825 0 012.893 6.994c-.003 5.45-4.437 9.884-9.885 9.884m8.413-18.297A11.815 11.815 0 0012.05 0C5.495 0 .16 5.335.157 11.892c0 2.096.547 4.142 1.588 5.945L.057 24l6.305-1.654a11.882 11.882 0 005.683 1.448h.005c6.554 0 11.89-5.335 11.893-11.893A11.821 11.821 0 0020.464 3.488"/></svg>
      <span class="te-content">వాట్సాప్</span><span class="en-content">WhatsApp</span>
    </a>
    <a href="tel:+919063490160" class="btn btn-light phone-number" data-cta="call" data-cta-pos="drawer" data-intent="appointment">
      <svg class="btn-icon" viewBox="0 0 24 24" fill="currentColor"><path d="M20 15.5c-1.25 0-2.45-.2-3.57-.57-.35-.11-.74-.03-1.02.24l-2.2 2.2c-2.83-1.44-5.15-3.75-6.59-6.58l2.2-2.21c.28-.27.36-.66.25-1.01C8.7 6.45 8.5 5.25 8.5 4c0-.55-.45-1-1-1H4c-.55 0-1 .45-1 1 0 9.39 7.61 17 17 17 .55 0 1-.45 1-1v-3.5c0-.55-.45-1-1-1z"/></svg>
      +91 90634 90160
    </a>
  </div>
</aside>

<!-- Sticky mobile bar -->
<div class="sticky-bar">
  <a href="tel:+919063490160" class="sticky-call phone-number" data-cta="call" data-cta-pos="sticky" data-intent="appointment">
    <svg class="btn-icon" viewBox="0 0 24 24" fill="currentColor"><path d="M20 15.5c-1.25 0-2.45-.2-3.57-.57-.35-.11-.74-.03-1.02.24l-2.2 2.2c-2.83-1.44-5.15-3.75-6.59-6.58l2.2-2.21c.28-.27.36-.66.25-1.01C8.7 6.45 8.5 5.25 8.5 4c0-.55-.45-1-1-1H4c-.55 0-1 .45-1 1 0 9.39 7.61 17 17 17 .55 0 1-.45 1-1v-3.5c0-.55-.45-1-1-1z"/></svg>
    <span class="te-content">కాల్</span><span class="en-content">Call</span>
  </a>
  <a href="https://wa.me/919063490160?text=Hello%2C%20I%20would%20like%20to%20book%20a%20consultation." class="sticky-wa" data-cta="whatsapp" data-cta-pos="sticky" data-intent="appointment" target="_blank" rel="noopener">
    <svg class="btn-icon" viewBox="0 0 24 24" fill="currentColor"><path d="M17.472 14.382c-.297-.149-1.758-.867-2.03-.967-.273-.099-.471-.148-.67.15-.197.297-.767.966-.94 1.164-.173.199-.347.223-.644.075-.297-.15-1.255-.463-2.39-1.475-.883-.788-1.48-1.761-1.653-2.059-.173-.297-.018-.458.13-.606.134-.133.298-.347.446-.52.149-.174.198-.298.298-.497.099-.198.05-.371-.025-.52-.075-.149-.669-1.612-.916-2.207-.242-.579-.487-.5-.669-.51-.173-.008-.371-.01-.57-.01-.198 0-.52.074-.792.372-.272.297-1.04 1.016-1.04 2.479 0 1.462 1.065 2.875 1.213 3.074.149.198 2.096 3.2 5.077 4.487.709.306 1.262.489 1.694.625.712.227 1.36.195 1.871.118.571-.085 1.758-.719 2.006-1.413.248-.694.248-1.289.173-1.413-.074-.124-.272-.198-.57-.347m-5.421 7.403h-.004a9.87 9.87 0 01-5.031-1.378l-.361-.214-3.741.982.998-3.648-.235-.374a9.86 9.86 0 01-1.51-5.26c.001-5.45 4.436-9.884 9.888-9.884 2.64 0 5.122 1.03 6.988 2.898a9.825 9.825 0 012.893 6.994c-.003 5.45-4.437 9.884-9.885 9.884m8.413-18.297A11.815 11.815 0 0012.05 0C5.495 0 .16 5.335.157 11.892c0 2.096.547 4.142 1.588 5.945L.057 24l6.305-1.654a11.882 11.882 0 005.683 1.448h.005c6.554 0 11.89-5.335 11.893-11.893A11.821 11.821 0 0020.464 3.488"/></svg>
    <span class="te-content">వాట్సాప్</span><span class="en-content">WhatsApp</span>
  </a>
</div>

<script>
(function(){
  var ham = document.getElementById('hamburger');
  var drawer = document.getElementById('mobileDrawer');
  var overlay = document.getElementById('drawerOverlay');
  var close = document.getElementById('drawerClose');
  function open(){ drawer.classList.add('open'); overlay.classList.add('open'); }
  function shut(){ drawer.classList.remove('open'); overlay.classList.remove('open'); }
  if(ham) ham.addEventListener('click', open);
  if(close) close.addEventListener('click', shut);
  if(overlay) overlay.addEventListener('click', shut);
})();
</script>

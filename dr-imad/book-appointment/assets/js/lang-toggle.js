/* ─────────────────────────────────────────────────────────────
   lang-toggle.js — Telugu default, English via toggle
   Saves choice in localStorage. Also reads ?lang= from URL.
───────────────────────────────────────────────────────────── */
(function() {
  "use strict";

  var teBtn = document.getElementById("lang-te");
  var enBtn = document.getElementById("lang-en");
  var html  = document.documentElement;
  var body  = document.body;

  if (!teBtn || !enBtn) return;

  function setLang(l) {
    if (l === "en") {
      body.classList.add("lang-en");
      html.lang = "en";
      teBtn.classList.remove("active");
      enBtn.classList.add("active");
    } else {
      body.classList.remove("lang-en");
      html.lang = "te";
      teBtn.classList.add("active");
      enBtn.classList.remove("active");
    }
    try { localStorage.setItem("cion_lang", l); } catch(e) {}
    if (window.cionTrack) {
      window.cionTrack("cion_language_toggle", { lang: l });
    }
  }

  // Initial language: URL param > localStorage > default Telugu
  var urlLang = null;
  try { urlLang = new URLSearchParams(location.search).get("lang"); } catch(e) {}
  var savedLang = null;
  try { savedLang = localStorage.getItem("cion_lang"); } catch(e) {}

  var initLang = "te";
  if (urlLang === "en" || urlLang === "te") initLang = urlLang;
  else if (savedLang === "en" || savedLang === "te") initLang = savedLang;

  setLang(initLang);

  teBtn.addEventListener("click", function() { setLang("te"); });
  enBtn.addEventListener("click", function() { setLang("en"); });
})();

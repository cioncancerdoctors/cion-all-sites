/* ─────────────────────────────────────────────────────────────
   nav.js — Mobile nav drawer + FAQ accordion + smooth-jump
───────────────────────────────────────────────────────────── */
(function() {
  "use strict";

  // ── Mobile nav drawer ──
  var hamb    = document.getElementById("hamburger");
  var drawer  = document.getElementById("navDrawer");
  var overlay = document.getElementById("navOverlay");

  if (hamb && drawer && overlay) {
    function toggle() {
      var open = drawer.classList.toggle("open");
      hamb.classList.toggle("open", open);
      overlay.classList.toggle("show", open);
    }
    function close() {
      drawer.classList.remove("open");
      hamb.classList.remove("open");
      overlay.classList.remove("show");
    }
    hamb.addEventListener("click", toggle);
    overlay.addEventListener("click", close);
    drawer.querySelectorAll("a").forEach(function(a) {
      a.addEventListener("click", close);
    });
  }

  // ── FAQ accordion ──
  document.querySelectorAll(".faq-item").forEach(function(item) {
    var btn = item.querySelector(".faq-q");
    if (!btn) return;
    btn.addEventListener("click", function() {
      var open = item.classList.toggle("open");
      if (open && window.cionTrack) {
        window.cionTrack("cion_faq_open", {
          faq_question: btn.textContent.trim().slice(0, 80)
        });
      }
    });
  });

  // ── Offset smooth scroll for anchor links (account for fixed header) ──
  document.querySelectorAll('a[href^="#"]:not([href="#"])').forEach(function(a) {
    a.addEventListener("click", function(e) {
      var id = this.getAttribute("href").slice(1);
      var target = document.getElementById(id);
      if (!target) return;
      e.preventDefault();
      var hdr = document.querySelector(".site-header");
      var offset = (hdr ? hdr.offsetHeight : 56) + 12;
      var top = target.getBoundingClientRect().top + window.pageYOffset - offset;
      window.scrollTo({ top: top, behavior: "smooth" });
    });
  });
})();

// FAQ accordion
document.addEventListener('click', function(e) {
  var btn = e.target.closest('.faq-q');
  if (!btn) return;
  var item = btn.closest('.faq-item');
  var ans  = item ? item.querySelector('.faq-a') : null;
  if (!ans) return;
  var open = btn.getAttribute('aria-expanded') === 'true';
  // Close all others
  document.querySelectorAll('.faq-q[aria-expanded="true"]').forEach(function(b) {
    b.setAttribute('aria-expanded','false');
    var a = b.closest('.faq-item').querySelector('.faq-a');
    if (a) a.hidden = true;
  });
  if (!open) {
    btn.setAttribute('aria-expanded','true');
    ans.hidden = false;
    if (window.cionTrack) window.cionTrack('cion_faq_open', { faq_question: btn.textContent.replace('+','').trim().slice(0,80) });
  }
});

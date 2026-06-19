/* ─────────────────────────────────────────────────────────────
   copy-protect.js — Block casual content copying
   Phone numbers + addresses (.copyable, [href^="tel:"]) remain selectable.
   Note: This stops casual users only. Anyone with dev tools can extract.
───────────────────────────────────────────────────────────── */
(function() {
  "use strict";

  function isCopyable(el) {
    if (!el) return false;
    while (el && el !== document.body) {
      if (el.classList && (
        el.classList.contains("copyable") ||
        el.classList.contains("address") ||
        el.classList.contains("phone-number")
      )) return true;
      var href = el.getAttribute && el.getAttribute("href");
      if (href && (href.indexOf("tel:") === 0 || href.indexOf("https://wa.me/") === 0)) return true;
      // Allow form fields
      var tag = el.tagName;
      if (tag === "INPUT" || tag === "TEXTAREA" || tag === "SELECT") return true;
      el = el.parentElement;
    }
    return false;
  }

  // Block right-click context menu (except on copyable)
  document.addEventListener("contextmenu", function(e) {
    if (!isCopyable(e.target)) {
      e.preventDefault();
      return false;
    }
  });

  // Block Ctrl+C / Cmd+C (except on copyable)
  document.addEventListener("copy", function(e) {
    if (!isCopyable(e.target)) {
      e.preventDefault();
      try { e.clipboardData.setData("text/plain", ""); } catch(err) {}
      return false;
    }
  });

  document.addEventListener("cut", function(e) {
    if (!isCopyable(e.target)) {
      e.preventDefault();
      return false;
    }
  });

  // Block drag (especially images)
  document.addEventListener("dragstart", function(e) {
    if (e.target && e.target.tagName === "IMG" && !e.target.classList.contains("interactive")) {
      e.preventDefault();
      return false;
    }
  });

  // Block common keyboard shortcuts (Ctrl+S save, Ctrl+U view source, F12 devtools)
  // Note: These can be bypassed by dev tools — purely a deterrent for casual users
  document.addEventListener("keydown", function(e) {
    if ((e.ctrlKey || e.metaKey) && (e.key === "s" || e.key === "S")) {
      e.preventDefault();
    }
    if ((e.ctrlKey || e.metaKey) && (e.key === "u" || e.key === "U")) {
      e.preventDefault();
    }
    if ((e.ctrlKey || e.metaKey) && e.shiftKey && (e.key === "i" || e.key === "I" || e.key === "j" || e.key === "J" || e.key === "c" || e.key === "C")) {
      // Devtools shortcut — blocked but easily bypassed
      // Don't be aggressive here, can frustrate legit users
    }
  });
})();

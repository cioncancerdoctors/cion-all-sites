/* ─────────────────────────────────────────────────────────────
   tracking.js — CION GTM-only event pusher
   Architecture: website fires dataLayer.push() only.
   GTM handles: GA4, Meta Pixel, Google Ads, Clarity.
   No fbq(), no gtag(), no Clarity init in this file.
   Standard across ALL CION doctor landing pages.
   Page-specific values come from window.cionPageData only.
───────────────────────────────────────────────────────────── */
(function() {
  "use strict";

  window.dataLayer = window.dataLayer || [];

  // ── Page metadata — read from window.cionPageData only ──
  // Each page sets this before this script loads. No body data-* fallbacks.
  var pd = window.cionPageData || {};
  var doctorName      = pd.doctor_name      || "";
  var doctorSpecialty = pd.doctor_speciality || "";
  var pageType        = pd.page_type        || "doctor_landing_page";
  var intent          = pd.intent           || "";
  var offerType       = pd.offer_type       || "";
  var cancerType      = pd.cancer_type      || "";
  var location        = pd.location         || "";
  var language        = pd.language         || "Telugu";
  var funnelStage     = pd.funnel_stage     || "";

  // ── URL params ──
  function getParam(name) {
    var match = new RegExp("[?&]" + name + "=([^&]*)").exec(location.search || window.location.search);
    return match ? decodeURIComponent(match[1].replace(/\+/g, " ")) : "";
  }
  function getAllParams() {
    var params = {};
    var query = window.location.search.substring(1);
    if (!query) return params;
    query.split("&").forEach(function(pair) {
      var parts = pair.split("=");
      if (parts[0]) params[decodeURIComponent(parts[0])] = parts[1] ? decodeURIComponent(parts[1].replace(/\+/g, " ")) : "";
    });
    return params;
  }
  var urlParams = getAllParams();

  // ── Persist UTMs + click IDs across navigation ──
  var ATTR_KEYS = ["utm_source","utm_medium","utm_campaign","utm_content","utm_term","gclid","fbclid","campaign_id","adset_id","ad_id"];
  function readAttr() { try { var r = sessionStorage.getItem("cion_attr"); return r ? JSON.parse(r) : {}; } catch(e) { return {}; } }
  function saveAttr(o) { try { sessionStorage.setItem("cion_attr", JSON.stringify(o)); } catch(e) {} }
  var stored = readAttr();
  var attr = {};
  ATTR_KEYS.forEach(function(k) { attr[k] = urlParams[k] || stored[k] || ""; });
  saveAttr(attr);

  // ── Base page context — sent with every event ──
  var pageCtx = {
    doctor_name:       doctorName,
    doctor_speciality: doctorSpecialty,
    page_type:         pageType,
    intent:            intent,
    offer_type:        offerType,
    cancer_type:       cancerType,
    location:          location,
    language:          language,
    funnel_stage:      funnelStage,
    landing_page_url:  window.location.href,
    referrer:          document.referrer || ""
  };

  // ── Session engagement score (internal only — not a conversion signal) ──
  window.cionScore = window.cionScore || 0;
  function bump(n) { window.cionScore = (window.cionScore || 0) + n; }

  // ── Core push helper ──
  function track(eventName, extra) {
    var payload = {};
    var keys = Object.keys ? Object.keys(pageCtx) : [];
    keys.forEach(function(k) { payload[k] = pageCtx[k]; });
    ATTR_KEYS.forEach(function(k) { payload[k] = attr[k] || ""; });
    if (extra) {
      var ekeys = Object.keys ? Object.keys(extra) : [];
      ekeys.forEach(function(k) { payload[k] = extra[k]; });
    }
    payload.event = eventName;
    window.dataLayer.push(payload);
  }
  window.cionTrack = track;

  // ── UUID for event_id — Meta CAPI deduplication ──
  window.cionUuid = function() {
    if (window.crypto && window.crypto.randomUUID) return window.crypto.randomUUID();
    return "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx".replace(/[xy]/g, function(c) {
      var r = Math.random() * 16 | 0;
      return (c === "x" ? r : (r & 0x3 | 0x8)).toString(16);
    });
  };

  // ── Expose helpers for form.js ──
  window.cionGetAttribution = function() { return attr; };
  window.cionGetPageContext  = function() { return pageCtx; };

  // ── Approved event: cion_page_view ──
  track("cion_page_view", { session_score: 0 });

  // ── Delegated CTA click handler (single listener only) ──
  document.addEventListener("click", function(e) {
    var el = e.target.closest("[data-cta]");
    if (!el) return;
    var ctaType = el.getAttribute("data-cta")    || "";
    var ctaPos  = el.getAttribute("data-cta-pos") || "unknown";
    var ctaIntent = el.getAttribute("data-intent") || "";

    if (ctaType === "call") {
      bump(5);
      track("cion_call_click", { cta_type: "Call", cta_position: ctaPos, intent: ctaIntent, session_score: window.cionScore, event_id: window.cionUuid ? window.cionUuid() : "" });
    } else if (ctaType === "whatsapp") {
      bump(5);
      track("cion_whatsapp_click", { cta_type: "WhatsApp", cta_position: ctaPos, intent: ctaIntent, session_score: window.cionScore, event_id: window.cionUuid ? window.cionUuid() : "" });
    } else if (ctaType === "doctor-link") {
      track("cion_doctor_profile_click", { doctor_clicked: el.getAttribute("data-doctor") || "" });
    } else if (ctaType === "map") {
      track("cion_location_click", { cta_position: ctaPos });
    } else {
      track("cion_cta_click", { cta_type: ctaType, cta_position: ctaPos, intent: ctaIntent });
    }
  });

  // ── Section view (IntersectionObserver) ──
  if ("IntersectionObserver" in window) {
    var seen = {};
    var secs = document.querySelectorAll("[data-section-track]");
    if (secs.length) {
      var obs = new IntersectionObserver(function(entries) {
        entries.forEach(function(entry) {
          if (!entry.isIntersecting) return;
          var name = entry.target.getAttribute("data-section-track");
          if (seen[name]) return;
          seen[name] = true;
          track("cion_section_view", { section_name: name });
        });
      }, { threshold: 0.4 });
      secs.forEach(function(s) { obs.observe(s); });
    }
  }

  // ── Scroll depth ──
  var scrollFired = {};
  var scrollTimer;
  window.addEventListener("scroll", function() {
    if (scrollTimer) return;
    scrollTimer = setTimeout(function() {
      scrollTimer = null;
      var pct = ((window.pageYOffset || document.documentElement.scrollTop) /
                 Math.max(document.documentElement.scrollHeight - window.innerHeight, 1)) * 100;
      [50, 90].forEach(function(mark) {
        if (pct >= mark && !scrollFired[mark]) {
          scrollFired[mark] = true;
          if (mark === 50) bump(2);
          track("cion_scroll_" + mark);
        }
      });
    }, 250);
  }, { passive: true });

  // ── Time milestones ──
  setTimeout(function() { track("cion_time_30s"); }, 30000);
  setTimeout(function() { bump(2); track("cion_time_60s"); }, 60000);

  // ── WhatsApp source-tag — runs on load + click (catches dynamic links) ──
  function tagWaLinks() {
    var slug = window.location.pathname.replace(/\//g, "_").replace(/^_|_$/g, "") || "home";
    document.querySelectorAll("a[href*='wa.me']").forEach(function(a) {
      try {
        var url = new URL(a.href);
        var text = url.searchParams.get("text") || "";
        if (text && text.indexOf("[src:") === -1) {
          url.searchParams.set("text", text + " [src:" + slug + "]");
          a.setAttribute("href", url.toString());
        }
      } catch(e) {}
    });
  }
  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", tagWaLinks);
  } else {
    tagWaLinks();
  }
  document.addEventListener("click", function(e) {
    if (e.target.closest("a[href*='wa.me']")) tagWaLinks();
  }, true);

})();

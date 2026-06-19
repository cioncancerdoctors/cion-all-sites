/* ─────────────────────────────────────────────────────────────
   form.js — validation + submission to /api/submit.php
───────────────────────────────────────────────────────────── */
(function() {
  "use strict";

  function initForm(form) {
    if (!form || form.dataset.cionInit) return;
    form.dataset.cionInit = "1";

    var formStarted = false;
    var formStartTime = Date.now();

    function ensureHidden(name, value) {
      var input = form.querySelector('input[name="' + name + '"]');
      if (!input) {
        input = document.createElement("input");
        input.type = "hidden";
        input.name = name;
        form.appendChild(input);
      }
      if (value !== undefined) input.value = value;
      return input;
    }

    var ctx  = window.cionGetPageContext ? window.cionGetPageContext() : {};
    var attr = window.cionGetAttribution ? window.cionGetAttribution() : {};

    // Page context
    ensureHidden("doctor_name_key",      (window.CION_DOCTOR && window.CION_DOCTOR.doctor_name_key) || "");
    ensureHidden("doctor_specialty_key", (window.CION_DOCTOR && window.CION_DOCTOR.doctor_specialty_key) || "");
    ensureHidden("page_type",        ctx.page_type || "");
    ensureHidden("page_name",        ctx.page_name || "");
    ensureHidden("lp_variant",       ctx.lp_variant || "");
    ensureHidden("offer_type",       ctx.offer_type || "");
    ensureHidden("condition_page",   ctx.condition_page || "");
    ensureHidden("hostname",         ctx.hostname || "");
    ensureHidden("landing_page_url", ctx.landing_page_url || "");
    ensureHidden("referrer",         ctx.referrer || "");

    // Attribution
    ensureHidden("utm_source",   attr.utm_source || "");
    ensureHidden("utm_medium",   attr.utm_medium || "");
    ensureHidden("utm_campaign", attr.utm_campaign || "");
    ensureHidden("utm_content",  attr.utm_content || "");
    ensureHidden("utm_term",     attr.utm_term || "");
    ensureHidden("gclid",        attr.gclid || "");
    ensureHidden("fbclid",       attr.fbclid || "");
    ensureHidden("campaign_id",  attr.campaign_id || "");
    ensureHidden("adset_id",     attr.adset_id || "");
    ensureHidden("ad_id",        attr.ad_id || "");

    // Session
    ensureHidden("session_score", window.cionScore || 0);
    ensureHidden("form_intent", form.getAttribute("data-intent") || ctx.offer_type || "");

    // event_id (UUID) for Meta CAPI dedup later
    var eventId = window.cionUuid ? window.cionUuid() : (Date.now() + "-" + Math.random().toString(36).slice(2));
    window.cionEventId = eventId; // exposed for GTM DLV - event_id
    ensureHidden("event_id",     eventId);
    ensureHidden("meta_lead_id", eventId);

    // Consent metadata
    ensureHidden("consent_version",   "v1.0-2026-05-04");
    ensureHidden("consent_timestamp", new Date().toISOString());

    // Form open timestamp (for bot detection — server checks form_age)
    ensureHidden("form_opened_at", String(formStartTime));

    // ── FormStart on first focus ──
    var visibleInputs = form.querySelectorAll("input:not([type=hidden]), select, textarea");
    visibleInputs.forEach(function(el) {
      el.addEventListener("focus", function() {
        if (!formStarted && window.cionTrack) {
          formStarted = true;
          window.cionTrack("cion_form_start");
        }
      }, { once: true });
    });

    // ── Validation helpers ──
    function setError(field, msg) {
      var wrap = field.closest(".field");
      if (wrap) {
        wrap.classList.add("error");
        var err = wrap.querySelector(".field-error");
        if (err && msg) err.textContent = msg;
      }
    }
    function clearError(field) {
      var wrap = field.closest(".field");
      if (wrap) wrap.classList.remove("error");
    }
    function isValidPhone(p) {
      var digits = p.replace(/\D/g, "");
      if (digits.indexOf("91") === 0 && digits.length === 12) digits = digits.slice(2);
      if (digits.indexOf("0")  === 0 && digits.length === 11) digits = digits.slice(1);
      if (digits.length !== 10) return false;
      return /^[6-9]/.test(digits);
    }
    function normalizePhone(p) {
      var digits = p.replace(/\D/g, "");
      if (digits.indexOf("91") === 0 && digits.length === 12) digits = digits.slice(2);
      if (digits.indexOf("0")  === 0 && digits.length === 11) digits = digits.slice(1);
      return digits;
    }

    var phoneInput = form.querySelector('input[name="phone"]');
    if (phoneInput) {
      phoneInput.addEventListener("blur", function() {
        if (this.value && !isValidPhone(this.value)) {
          setError(this, "Please enter a valid 10-digit Indian mobile number");
          if (window.cionTrack) window.cionTrack("cion_form_field_error", { field: "phone" });
        } else { clearError(this); }
      });
    }

    // ── Submit handler ──
    form.addEventListener("submit", function(e) {
      e.preventDefault();

      // refresh dynamic hidden fields
      ensureHidden("session_score", window.cionScore || 0);
      ensureHidden("form_age_ms", String(Date.now() - formStartTime));

      var errors = [];

      var name = form.querySelector('input[name="name"]');
      if (name && !name.value.trim()) { setError(name, "Please enter your name"); errors.push("name"); }
      else if (name) clearError(name);

      var phone = form.querySelector('input[name="phone"]');
      if (phone && !isValidPhone(phone.value)) { setError(phone, "Please enter a valid 10-digit Indian mobile number"); errors.push("phone"); }
      else if (phone) { phone.value = normalizePhone(phone.value); clearError(phone); }

      var concern = form.querySelector('select[name="condition_interest_key"]');
      if (concern && !concern.value) { setError(concern, "Please select a cancer concern"); errors.push("concern"); }
      else if (concern) clearError(concern);

      var city = form.querySelector('input[name="patient_city"]');
      if (city && !city.value.trim()) { setError(city, "Please enter your city"); errors.push("city"); }
      else if (city) clearError(city);

      var consent = form.querySelector('input[name="consent_marketing"]');
      if (consent && !consent.checked) {
        var consentField = consent.closest(".consent");
        if (consentField) consentField.style.color = "#C0392B";
        errors.push("consent");
      }

      if (errors.length) {
        if (window.cionTrack) window.cionTrack("cion_form_submit_error", { errors: errors.join(",") });
        showMsg("Please correct the highlighted fields", "error");
        return;
      }

      // ── Submit ──
      var submitBtn = form.querySelector(".btn-submit");
      if (submitBtn) {
        submitBtn.disabled = true;
        submitBtn.dataset.origText = submitBtn.textContent;
        submitBtn.textContent = "Sending…";
      }

      if (window.cionTrack) window.cionTrack("cion_form_submit_attempt");

      var formData = new FormData(form);
      var endpoint = form.getAttribute("action") || "/api/submit.php";

      fetch(endpoint, { method: "POST", body: formData, credentials: "same-origin" })
        .then(function(res) { return res.json().catch(function() { return { success: res.ok }; }); })
        .then(function(data) {
          if (data && data.success) {
            if (window.cionTrack) window.cionTrack("cion_form_submit_success", { event_id: eventId });
            var thankYou = form.getAttribute("data-thankyou") || "/thank-you/";
            var sep = thankYou.indexOf("?") > -1 ? "&" : "?";
            window.location.href = thankYou + sep + "ref=lead&eid=" + encodeURIComponent(eventId);
          } else {
            throw new Error((data && data.error) || "Submission failed");
          }
        })
        .catch(function(err) {
          console.error("Form submit error:", err);
          if (window.cionTrack) window.cionTrack("cion_form_submit_failure", { error: String(err && err.message || err) });
          showMsg("Something went wrong. Please WhatsApp us directly at +91 90634 90160.", "error");
          if (submitBtn) {
            submitBtn.disabled = false;
            submitBtn.textContent = submitBtn.dataset.origText || "Submit";
          }
        });

      function showMsg(text, type) {
        var msg = form.querySelector(".form-msg");
        if (!msg) return;
        msg.textContent = text;
        msg.classList.remove("success", "error");
        msg.classList.add(type, "show");
      }
    });
  }

  document.addEventListener("DOMContentLoaded", function() {
    document.querySelectorAll("form.cion-form").forEach(initForm);
  });
})();

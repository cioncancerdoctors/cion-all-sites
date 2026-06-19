/* ─────────────────────────────────────────────────────────────
   form.js — Lead form validation, submission, success handling
   Field names: name, phone, concern, city, attachments[]
   No consent checkbox. Disclaimer text only.
   On success: show inline message → fire cion_form_submit_success → redirect /thank-you/
───────────────────────────────────────────────────────────── */
(function() {
  "use strict";

  var MAX_FILE_SIZE  = 10 * 1024 * 1024;
  var MAX_FILES      = 3;
  var ALLOWED_TYPES  = ["application/pdf","image/jpeg","image/jpg","image/png"];
  var ALLOWED_EXTS   = /\.(pdf|jpg|jpeg|png)$/i;
  var REDIRECT_DELAY = 2000;

  function setError(el, msg) {
    el.classList.add("field-error");
    var row = el.closest(".form-row");
    if (!row) return;
    var existing = row.querySelector(".field-error-msg");
    if (existing) existing.remove();
    var span = document.createElement("span");
    span.className = "field-error-msg";
    span.textContent = msg;
    row.appendChild(span);
  }
  function clearError(el) {
    el.classList.remove("field-error");
    var row = el.closest(".form-row");
    if (row) { var m = row.querySelector(".field-error-msg"); if (m) m.remove(); }
  }

  function ensureHidden(form, name, value) {
    var el = form.querySelector("input[name='" + name + "']");
    if (!el) {
      el = document.createElement("input");
      el.type = "hidden";
      el.name = name;
      form.appendChild(el);
    }
    el.value = value != null ? String(value) : "";
  }

  function initForm(form) {
    var formStarted  = false;
    var submitBtn    = form.querySelector(".form-submit");
    var formLoadTime = Date.now();

    var ctx  = window.cionPageData || {};
    var attr = window.cionGetAttribution ? window.cionGetAttribution() : {};

    ensureHidden(form, "page_type",          ctx.page_type         || "doctor_landing_page");
    ensureHidden(form, "offer_type",          ctx.offer_type        || "");
    ensureHidden(form, "intent",              ctx.intent            || "");
    ensureHidden(form, "cancer_type",         ctx.cancer_type       || "");
    ensureHidden(form, "doctor_name",         ctx.doctor_name       || "");
    ensureHidden(form, "doctor_speciality",   ctx.doctor_speciality || "");
    ensureHidden(form, "location",            ctx.location          || "");
    ensureHidden(form, "language",            ctx.language          || "");
    ensureHidden(form, "landing_page_url",    window.location.href);
    ensureHidden(form, "hostname",            window.location.hostname);
    ensureHidden(form, "utm_source",          attr.utm_source       || "");
    ensureHidden(form, "utm_medium",          attr.utm_medium       || "");
    ensureHidden(form, "utm_campaign",        attr.utm_campaign     || "");
    ensureHidden(form, "utm_content",         attr.utm_content      || "");
    ensureHidden(form, "utm_term",            attr.utm_term         || "");
    ensureHidden(form, "utm_adset",           attr.adset_id         || "");
    ensureHidden(form, "utm_ad",              attr.ad_id            || "");
    ensureHidden(form, "gclid",               attr.gclid            || "");
    ensureHidden(form, "fbclid",              attr.fbclid           || "");
    ensureHidden(form, "session_score",       window.cionScore      || 0);
    ensureHidden(form, "form_age_ms",         0);
    ensureHidden(form, "consent_version",     "v2.0-2026-05");
    ensureHidden(form, "consent_timestamp",   new Date().toISOString());
    ensureHidden(form, "form_intent",         form.getAttribute("data-intent") || ctx.offer_type || "");

    var eventId = window.cionUuid ? window.cionUuid() : (Date.now() + "-" + Math.random().toString(36).slice(2));
    window.cionEventId = eventId;
    ensureHidden(form, "event_id",     eventId);
    ensureHidden(form, "meta_lead_id", eventId);

    // cion_form_start on first field interaction
    form.querySelectorAll("input, textarea, select").forEach(function(field) {
      field.addEventListener("focus", function() {
        if (formStarted) return;
        formStarted = true;
        if (window.cionTrack) window.cionTrack("cion_form_start");
      });
    });

    // File input validation on change
    var fileInput = form.querySelector("input[type='file']");
    if (fileInput) {
      fileInput.addEventListener("change", function() {
        clearError(fileInput);
        var files = Array.from(fileInput.files);
        if (files.length > MAX_FILES) {
          setError(fileInput, "Maximum " + MAX_FILES + " files allowed.");
          fileInput.value = ""; return;
        }
        for (var i = 0; i < files.length; i++) {
          var f = files[i];
          if (!ALLOWED_TYPES.includes(f.type) && !ALLOWED_EXTS.test(f.name)) {
            setError(fileInput, "Only PDF, JPG and PNG files are allowed.");
            fileInput.value = ""; return;
          }
          if (f.size > MAX_FILE_SIZE) {
            setError(fileInput, "Each file must be under 10MB. \"" + f.name + "\" is too large.");
            fileInput.value = ""; return;
          }
        }
      });
    }

    // Submit handler — async/await, full native prevention, strict event order
    form.addEventListener("submit", function(e) {
      e.preventDefault();
      e.stopPropagation();

      ensureHidden(form, "session_score", window.cionScore || 0);
      ensureHidden(form, "form_age_ms",   Date.now() - formLoadTime);

      var errors = [];

      var nameEl = form.querySelector("input[name='name']");
      if (nameEl) {
        if (!nameEl.value.trim()) { setError(nameEl, "Please enter your name."); errors.push("name"); }
        else clearError(nameEl);
      }

      var phoneEl = form.querySelector("input[name='phone']");
      if (phoneEl) {
        var ph = phoneEl.value.replace(/\D/g, "");
        if (ph.length === 12 && ph.substring(0,2) === "91") ph = ph.substring(2);
        if (ph.length === 11 && ph.substring(0,1) === "0")  ph = ph.substring(1);
        if (ph.length !== 10 || !/^[6-9]/.test(ph)) {
          setError(phoneEl, "Please enter a valid 10-digit Indian mobile number.");
          errors.push("phone");
        } else clearError(phoneEl);
      }

      if (fileInput && fileInput.hasAttribute("required")) {
        if (!fileInput.files || fileInput.files.length === 0) {
          setError(fileInput, "Please attach at least one report or scan.");
          errors.push("file");
        } else clearError(fileInput);
      }

      if (errors.length) {
        if (window.cionTrack) window.cionTrack("cion_form_submit_error", { errors: errors.join(",") });
        return false;
      }

      if (submitBtn) {
        submitBtn.disabled = true;
        var btnText = submitBtn.querySelector(".en-content");
        if (btnText) btnText.textContent = "Sending…";
      }

      if (window.cionTrack) window.cionTrack("cion_form_submit_attempt", {
        event_id: eventId,
        offer_type: ctx.offer_type || "",
        intent: ctx.intent || ""
      });

      var formData = new FormData(form);
      var endpoint = "/api/submit.php"; // forced — do not use form action attribute

      // Async IIFE — await fetch so dataLayer push happens before redirect
      (async function() {
        try {
          var response = await fetch(endpoint, {
            method: "POST",
            body: formData,
            credentials: "same-origin"
          });

          var data;
          try { data = await response.json(); }
          catch(parseErr) { data = { success: response.ok }; }

          // Debug log — remove after GTM Preview confirmed
          console.log("CION submit response", response.status, data);

          // Accept multiple success shapes from PHP
          var isSuccess = response.ok && (!data || data.success === true || data.ok === true || data.status === "success");

          if (isSuccess) {

            // 1. Push cion_form_submit_success FIRST — before DOM changes or redirect
            console.log("CION pushing cion_form_submit_success", eventId);
            if (window.cionTrack) window.cionTrack("cion_form_submit_success", {
              event_id:    eventId,
              offer_type:  ctx.offer_type  || "",
              intent:      ctx.intent      || "",
              doctor_name: ctx.doctor_name || "",
              page_type:   ctx.page_type   || "",
              cancer_type: ctx.cancer_type || ""
            });
            console.log("CION success in dataLayer", window.dataLayer && window.dataLayer.filter(function(x){ return x.event === "cion_form_submit_success"; }));

            // 2. Show inline success message
            var successEl = form.querySelector(".form-success");
            if (successEl) successEl.hidden = false;

            // 3. Hide form fields
            form.querySelectorAll(".form-row, .form-disclaimer, .form-submit").forEach(function(el) {
              el.style.display = "none";
            });

            // 4. No redirect — stay on page, success message already shown above
            // GTM tags fire cleanly without page navigation interference

          } else {
            throw new Error((data && data.error) || "Submission failed");
          }

        } catch(err) {
          if (window.cionTrack) window.cionTrack("cion_form_submit_error", {
            event_id: eventId,
            error: String(err && err.message || err)
          });
          if (submitBtn) {
            submitBtn.disabled = false;
            var btnText2 = submitBtn.querySelector(".en-content");
            if (btnText2) btnText2.textContent = "Send to Dr. Imad";
          }
          var errDiv = form.querySelector(".form-error-msg");
          if (!errDiv) {
            errDiv = document.createElement("p");
            errDiv.className = "form-error-msg";
            var successEl2 = form.querySelector(".form-success");
            if (successEl2) form.insertBefore(errDiv, successEl2);
            else form.appendChild(errDiv);
          }
          errDiv.textContent = "Something went wrong. Please WhatsApp us directly at +91 90634 90160.";
        }
      })();

      return false;
    }, true);
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", function() {
      document.querySelectorAll("form#leadForm, form.form-card").forEach(initForm);
    });
  } else {
    document.querySelectorAll("form#leadForm, form.form-card").forEach(initForm);
  }

})();

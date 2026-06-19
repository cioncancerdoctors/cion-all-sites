<?php
/* form-module.php — variables: $form_intent, $form_heading_te, $form_heading_en */
$form_intent     = $form_intent     ?? 'consultation';
$form_heading_te = $form_heading_te ?? 'Free Consultation Request';
$form_heading_en = $form_heading_en ?? 'Request a Free Consultation';
?>
<form class="form-card" id="leadForm" data-intent="<?php echo $form_intent; ?>" novalidate>
  <h3><span class="te-content"><?php echo $form_heading_te; ?></span><span class="en-content"><?php echo $form_heading_en; ?></span></h3>

  <div class="honeypot"><label>Website (leave blank)<input type="text" name="website" tabindex="-1" autocomplete="off"></label></div>

  <div class="form-row">
    <label for="lf-name"><span class="te-content">పేరు</span><span class="en-content">Your Name</span> *</label>
    <input type="text" id="lf-name" name="name" required>
  </div>
  <div class="form-row">
    <label for="lf-phone"><span class="te-content">ఫోన్ నంబర్</span><span class="en-content">Phone Number</span> *</label>
    <input type="tel" id="lf-phone" name="phone" required pattern="[0-9+\- ]{10,15}">
  </div>
  <div class="form-row">
    <label for="lf-concern"><span class="te-content">ఎందుకు సంప్రదిస్తున్నారు?</span><span class="en-content">What is your concern?</span></label>
    <textarea id="lf-concern" name="concern" rows="3" placeholder="<?php echo htmlspecialchars( $GLOBALS['form_placeholder_en'] ?? 'A brief note helps me prepare for our call.'); ?>"></textarea>
  </div>
  <div class="form-row">
    <label for="lf-city"><span class="te-content">నగరం</span><span class="en-content">City</span></label>
    <input type="text" id="lf-city" name="city" placeholder="Hyderabad">
  </div>

  <label class="form-consent">
    <input type="checkbox" name="consent" required>
    <span>
      <span class="te-content">నా phone number, message Dr. Imaduddin team తో share చేయడానికి, follow-up కోసం consent ఇస్తున్నాను. <a href="/privacy/">Privacy Policy</a></span>
      <span class="en-content">I consent to sharing my phone number and message with Dr. Imaduddin's team for follow-up. See <a href="/privacy/">Privacy Policy</a>.</span>
    </span>
  </label>

  <button type="submit" class="form-submit">
    <svg class="btn-icon" viewBox="0 0 24 24" fill="currentColor"><path d="M17.472 14.382c-.297-.149-1.758-.867-2.03-.967-.273-.099-.471-.148-.67.15-.197.297-.767.966-.94 1.164-.173.199-.347.223-.644.075-.297-.15-1.255-.463-2.39-1.475-.883-.788-1.48-1.761-1.653-2.059-.173-.297-.018-.458.13-.606.134-.133.298-.347.446-.52.149-.174.198-.298.298-.497.099-.198.05-.371-.025-.52-.075-.149-.669-1.612-.916-2.207-.242-.579-.487-.5-.669-.51-.173-.008-.371-.01-.57-.01-.198 0-.52.074-.792.372-.272.297-1.04 1.016-1.04 2.479 0 1.462 1.065 2.875 1.213 3.074.149.198 2.096 3.2 5.077 4.487.709.306 1.262.489 1.694.625.712.227 1.36.195 1.871.118.571-.085 1.758-.719 2.006-1.413.248-.694.248-1.289.173-1.413-.074-.124-.272-.198-.57-.347m-5.421 7.403h-.004a9.87 9.87 0 01-5.031-1.378l-.361-.214-3.741.982.998-3.648-.235-.374a9.86 9.86 0 01-1.51-5.26c.001-5.45 4.436-9.884 9.888-9.884 2.64 0 5.122 1.03 6.988 2.898a9.825 9.825 0 012.893 6.994c-.003 5.45-4.437 9.884-9.885 9.884m8.413-18.297A11.815 11.815 0 0012.05 0C5.495 0 .16 5.335.157 11.892c0 2.096.547 4.142 1.588 5.945L.057 24l6.305-1.654a11.882 11.882 0 005.683 1.448h.005c6.554 0 11.89-5.335 11.893-11.893A11.821 11.821 0 0020.464 3.488"/></svg>
    <span class="te-content">Submit చేయండి</span><span class="en-content">Send to Dr. Imad</span>
  </button>
</form>

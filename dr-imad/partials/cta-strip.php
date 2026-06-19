<?php
/* cta-strip.php — variables: $cta_intent, $cta_heading_te, $cta_heading_en, $cta_wa_msg */
$cta_intent     = $cta_intent     ?? 'appointment';
$cta_heading_te = $cta_heading_te ?? 'Dr. Imad తో మాట్లాడండి';
$cta_heading_en = $cta_heading_en ?? 'Talk to Dr. Imad';
$cta_wa_msg     = $cta_wa_msg     ?? 'Hello%2C%20I%20would%20like%20to%20book%20a%20consultation%20with%20Dr.%20Imaduddin.';
?>
<section class="cta-strip">
  <div class="cta-strip-inner">
    <h2><span class="te-content"><?php echo $cta_heading_te; ?></span><span class="en-content"><?php echo $cta_heading_en; ?></span></h2>
    <div class="cta-strip-ctas">
      <a href="https://wa.me/919063490160?text=<?php echo $cta_wa_msg; ?>" class="btn btn-wa" data-cta="whatsapp" data-cta-pos="cta_strip" data-intent="<?php echo $cta_intent; ?>" target="_blank" rel="noopener">
        <svg class="btn-icon" viewBox="0 0 24 24" fill="currentColor"><path d="M17.472 14.382c-.297-.149-1.758-.867-2.03-.967-.273-.099-.471-.148-.67.15-.197.297-.767.966-.94 1.164-.173.199-.347.223-.644.075-.297-.15-1.255-.463-2.39-1.475-.883-.788-1.48-1.761-1.653-2.059-.173-.297-.018-.458.13-.606.134-.133.298-.347.446-.52.149-.174.198-.298.298-.497.099-.198.05-.371-.025-.52-.075-.149-.669-1.612-.916-2.207-.242-.579-.487-.5-.669-.51-.173-.008-.371-.01-.57-.01-.198 0-.52.074-.792.372-.272.297-1.04 1.016-1.04 2.479 0 1.462 1.065 2.875 1.213 3.074.149.198 2.096 3.2 5.077 4.487.709.306 1.262.489 1.694.625.712.227 1.36.195 1.871.118.571-.085 1.758-.719 2.006-1.413.248-.694.248-1.289.173-1.413-.074-.124-.272-.198-.57-.347m-5.421 7.403h-.004a9.87 9.87 0 01-5.031-1.378l-.361-.214-3.741.982.998-3.648-.235-.374a9.86 9.86 0 01-1.51-5.26c.001-5.45 4.436-9.884 9.888-9.884 2.64 0 5.122 1.03 6.988 2.898a9.825 9.825 0 012.893 6.994c-.003 5.45-4.437 9.884-9.885 9.884m8.413-18.297A11.815 11.815 0 0012.05 0C5.495 0 .16 5.335.157 11.892c0 2.096.547 4.142 1.588 5.945L.057 24l6.305-1.654a11.882 11.882 0 005.683 1.448h.005c6.554 0 11.89-5.335 11.893-11.893A11.821 11.821 0 0020.464 3.488"/></svg>
        <span class="te-content">వాట్సాప్ చేయండి</span><span class="en-content">Message me on WhatsApp</span>
      </a>
      <a href="tel:+919063490160" class="btn btn-call phone-number" data-cta="call" data-cta-pos="cta_strip" data-intent="<?php echo $cta_intent; ?>">
        <svg class="btn-icon" viewBox="0 0 24 24" fill="currentColor"><path d="M20 15.5c-1.25 0-2.45-.2-3.57-.57-.35-.11-.74-.03-1.02.24l-2.2 2.2c-2.83-1.44-5.15-3.75-6.59-6.58l2.2-2.21c.28-.27.36-.66.25-1.01C8.7 6.45 8.5 5.25 8.5 4c0-.55-.45-1-1-1H4c-.55 0-1 .45-1 1 0 9.39 7.61 17 17 17 .55 0 1-.45 1-1v-3.5c0-.55-.45-1-1-1z"/></svg>
        +91 90634 90160
      </a>
    </div>
  </div>
</section>

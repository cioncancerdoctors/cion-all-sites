<?php
$page_title       = "Page Not Found | Dr. Mohammed Imaduddin";
$page_description = "The page you're looking for doesn't exist. Return to home or book a consultation.";
$page_canonical   = "https://cioncancerdrimad.com/";
$page_robots      = "noindex, follow";

require __DIR__ . '/_inc.php';
?>
<!DOCTYPE html>
<html lang="te">
<head>
<?php include $ROOT . '/partials/meta-tags.php'; ?>
</head>
<body data-page-type="error_404" data-page-name="404">

<noscript><iframe src="https://www.googletagmanager.com/ns.html?id=GTM-PSVM4HGG"
height="0" width="0" style="display:none;visibility:hidden"></iframe></noscript>

<?php include $ROOT . '/partials/header.php'; ?>

<div class="err-wrap">
  <div class="err-h1">404</div>
  <h2 class="err-h2">
    <span class="te-content">Page కనుగొనబడలేదు</span>
    <span class="en-content">Page Not Found</span>
  </h2>
  <p class="err-p">
    <span class="te-content">మీరు వెతుకుతున్న page ఇక్కడ లేదు. Homepage కి వెళ్దాం, లేదా directly సంప్రదించండి.</span>
    <span class="en-content">The page you're looking for doesn't exist. Let's get you back home, or you can reach us directly.</span>
  </p>
  <div class="cta-strip-btns" style="max-width:480px; margin:0 auto;">
    <a href="/" class="btn" style="background:var(--purple); color:#fff;" data-cta="form-jump" data-cta-pos="404" data-intent="home">
      🏠 <span class="te-content">Homepage</span><span class="en-content">Go Home</span>
    </a>
    <a href="https://wa.me/919063490160?text=Hello%2C%20I%20would%20like%20to%20consult%20Dr.%20Imaduddin." class="btn btn-wa" data-cta="whatsapp" data-cta-pos="404" data-intent="appointment" target="_blank" rel="noopener">
      💬 <span class="te-content">WhatsApp</span><span class="en-content">WhatsApp</span>
    </a>
  </div>
</div>

<?php include $ROOT . '/partials/footer.php'; ?>
</body>
</html>

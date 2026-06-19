<?php
/* ─────────────────────────────────────────────────────────────
   meta-tags.php — Generates <head> with full SEO meta + GTM
   Usage at top of every page:
     $page_title       = "Page Title | Dr. Mohammed Imaduddin | CION";
     $page_description = "Page description ≤155 chars.";
     $page_canonical   = "https://cioncancerdrimad.com/page-url/";
     $page_robots      = "index, follow"; // or "noindex, follow" for landing pages
     $page_og_image    = "https://cioncancerdrimad.com/assets/images/dr-imad-portrait.jpg";
     include 'partials/meta-tags.php';
───────────────────────────────────────────────────────────── */
$page_title       = $page_title       ?? 'Dr. Mohammed Imaduddin | Surgical Oncologist in Hyderabad | CION Cancer Clinics';
$page_description = $page_description ?? "Dr. Mohammed Imaduddin — AIIMS, Germany & Europe-trained Surgical Oncologist in Hyderabad. Expert in HIPEC, PIPAC, Whipple's, advanced GI & peritoneal cancer surgery. 14+ years.";
$page_canonical   = $page_canonical   ?? 'https://cioncancerdrimad.com/';
$page_robots      = $page_robots      ?? 'index, follow, max-image-preview:large';
$page_og_image    = $page_og_image    ?? 'https://cioncancerdrimad.com/assets/images/dr-imad-portrait.jpg';
?>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">

<title><?php echo htmlspecialchars($page_title); ?></title>
<meta name="description" content="<?php echo htmlspecialchars($page_description); ?>">
<meta name="robots" content="<?php echo $page_robots; ?>">
<link rel="canonical" href="<?php echo $page_canonical; ?>">

<!-- Bilingual hreflang -->
<link rel="alternate" hreflang="te-IN" href="<?php echo $page_canonical; ?>">
<link rel="alternate" hreflang="en-IN" href="<?php echo $page_canonical; ?>?lang=en">
<link rel="alternate" hreflang="x-default" href="<?php echo $page_canonical; ?>">

<!-- Open Graph -->
<meta property="og:type" content="website">
<meta property="og:url" content="<?php echo $page_canonical; ?>">
<meta property="og:title" content="<?php echo htmlspecialchars($page_title); ?>">
<meta property="og:description" content="<?php echo htmlspecialchars($page_description); ?>">
<meta property="og:image" content="<?php echo $page_og_image; ?>">
<meta property="og:locale" content="en_IN">
<meta property="og:locale:alternate" content="te_IN">
<meta name="twitter:card" content="summary_large_image">

<link rel="icon" type="image/x-icon" href="/assets/images/favicon.ico">
<link rel="icon" type="image/png" sizes="32x32" href="/assets/images/favicon-32.png">
<link rel="icon" type="image/png" sizes="16x16" href="/assets/images/favicon-16.png">
<link rel="apple-touch-icon" sizes="180x180" href="/assets/images/apple-touch-icon.png">

<!-- Preload critical -->
<link rel="preload" href="/assets/css/styles.css" as="style">
<link rel="preload" href="/assets/images/dr-imad-portrait.jpg" as="image">

<!-- Stylesheet -->
<link rel="stylesheet" href="/assets/css/styles.css">

<!-- Fonts -->
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Cormorant:ital,wght@0,400;0,500;1,400&family=DM+Sans:wght@400;500;600;700&family=Noto+Sans+Telugu:wght@400;500;600;700&display=swap" rel="stylesheet">

<!-- Google Tag Manager -->
<script>(function(w,d,s,l,i){w[l]=w[l]||[];w[l].push({'gtm.start':
new Date().getTime(),event:'gtm.js'});var f=d.getElementsByTagName(s)[0],
j=d.createElement(s),dl=l!='dataLayer'?'&l='+l:'';j.async=true;j.src=
'https://www.googletagmanager.com/gtm.js?id='+i+dl;f.parentNode.insertBefore(j,f);
})(window,document,'script','dataLayer','GTM-PSVM4HGG');</script>

<?php
/* ─────────────────────────────────────────────────────────────
   _inc.php — Path helper for all pages
   Use $ROOT to resolve partials from any subfolder depth.
───────────────────────────────────────────────────────────── */
$ROOT = $_SERVER['DOCUMENT_ROOT'];

// Defaults — override per page before including meta-tags.php
$page_title       = $page_title       ?? "Dr. Mohammed Imaduddin | Surgical Oncologist in Hyderabad";
$page_description = $page_description ?? "AIIMS, Germany & Europe-trained Surgical Oncologist. CION Cancer Clinics, Hyderabad.";
$page_canonical   = $page_canonical   ?? "https://cioncancerdrimad.com/";
$page_robots      = $page_robots      ?? "index, follow, max-image-preview:large";
$page_og_image    = $page_og_image    ?? "https://cioncancerdrimad.com/assets/images/dr-imad-portrait.jpg";

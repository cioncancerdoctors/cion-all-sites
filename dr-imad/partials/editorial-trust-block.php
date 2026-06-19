<?php
/* ─────────────────────────────────────────────────────────────
   editorial-trust-block.php — E-E-A-T signal block
   Place at top or bottom of medical/cancer content pages.
   Usage:
     $reviewed_date = "May 2026";
     include 'partials/editorial-trust-block.php';
───────────────────────────────────────────────────────────── */
$reviewed_date = $reviewed_date ?? 'May 2026';
?>
<div class="editorial-trust">
  <span class="te-content">
    <strong>📋 Medical content review:</strong> ఈ page Dr. Mohammed Imaduddin (M.B.B.S, MS, M.Ch AIIMS, FEBS, ESSO, FACS) ద్వారా reviewed. Last reviewed: <?php echo $reviewed_date; ?>.
    Sources: published medical literature, NCI, WHO, ASCO &amp; ESMO guidelines.
    <a href="/why-dr-imad/" style="color:var(--purple);">Editorial process</a>.
  </span>
  <span class="en-content">
    <strong>📋 Medically reviewed:</strong> This page is reviewed by Dr. Mohammed Imaduddin (M.B.B.S, MS, M.Ch AIIMS, FEBS, ESSO, FACS). Last reviewed: <?php echo $reviewed_date; ?>.
    Sources include published medical literature, NCI, WHO, ASCO &amp; ESMO guidelines.
    <a href="/why-dr-imad/" style="color:var(--purple);">Editorial process</a>.
  </span>
</div>

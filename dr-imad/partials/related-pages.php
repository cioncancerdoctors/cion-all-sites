<?php
/* ─────────────────────────────────────────────────────────────
   related-pages.php — 3 cards of related internal pages
   Usage:
     $related_pages = [
       ["url" => "/types-of-cancer/gastric-stomach-cancer/", "tag_te" => "క్యాన్సర్ రకం", "tag_en" => "CANCER TYPE", "title_te" => "Gastric Cancer", "title_en" => "Gastric Cancer", "desc_te" => "...", "desc_en" => "..."],
       ...
     ];
     include 'partials/related-pages.php';
───────────────────────────────────────────────────────────── */
$related_pages = $related_pages ?? [];
if (empty($related_pages)) return;
?>
<section class="section section-light" data-section-track="related_pages">
  <div class="section-inner">
    <div class="sec-eyebrow"><span class="te-content">సంబంధిత పేజీలు</span><span class="en-content">Related Pages</span></div>
    <h2 class="sec-h">
      <span class="te-content">మరింత <em>చదవండి</em></span>
      <span class="en-content">Continue <em>Reading</em></span>
    </h2>
    <div class="related-pages">
      <?php foreach ($related_pages as $p): ?>
      <a href="<?php echo htmlspecialchars($p['url']); ?>" class="rel-card">
        <div class="rel-tag">
          <span class="te-content"><?php echo $p['tag_te'] ?? ''; ?></span>
          <span class="en-content"><?php echo $p['tag_en'] ?? ''; ?></span>
        </div>
        <h4>
          <span class="te-content"><?php echo $p['title_te'] ?? ''; ?></span>
          <span class="en-content"><?php echo $p['title_en'] ?? ''; ?></span>
        </h4>
        <p>
          <span class="te-content"><?php echo $p['desc_te'] ?? ''; ?></span>
          <span class="en-content"><?php echo $p['desc_en'] ?? ''; ?></span>
        </p>
      </a>
      <?php endforeach; ?>
    </div>
  </div>
</section>

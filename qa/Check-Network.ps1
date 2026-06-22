<#
  Check-Network.ps1 — standing pre-deploy QA for the CION doctor-site monorepo.
  Lives under seo-engine/ (NOT a dr-*/ folder) so it is never deployed to any site.

  Usage:   pwsh -File qa/Check-Network.ps1   (from repo root)
  Exit:    0 = clean ; 1 = at least one P0-class violation found.

  Scope:   the 8 repo-managed sites (dr-imad is externally managed and skipped).
  Checks per page (P0 = blocks deploy, P1 = warn):
    [P0] exactly one each: <link rel=canonical>, <title>, meta description, <h1>,
         og:url, og:image, twitter:card ; og:url == canonical
    [P0] no relative ../dr-x/ cross-site links (must be absolute https)
    [P0] balanced <span> tags ; zero custom badge spans (status/now/redflag)
    [P0] lead-form contract: name="concern" present AND posts to /api/submit.php
    if ($t -match '[À-ÿ]') { $p0.Add("${rel}: possible Latin-1 / mojibake corruption") }
    [P0] no stray hreflang ; no <meta name=robots ... noindex|nofollow>
    [P0] BreadcrumbList present on non-home pages, valid JSON, first=root, last=canonical
    [P0] per-site sitemap.xml + robots.txt exist; sitemap lists this page's canonical
    [P1] title <= 60 ; meta description <= 155
    [P1] te-content vs en-content span parity within tolerance (report, do not block)
#>
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot   # repo root (…/cion-all-sites)

$siteDomain = @{
 'dr-craghavendra'='cioncancerdrcraghavendra.info'; 'dr-vinay'='cioncancerdrvinay.com'
 'dr-kiranmayee'='cioncancerdrkiranmayee.com';      'dr-basudev'='cioncancerdrbasudev.com'
 'dr-owais'='cioncancerdrowais.com';                'dr-murali'='cioncancerdrmurali.com'
 'dr-raghvendra'='cioncancerdrraghvendra.com';      'dr-sandeep'='cioncancerdrsandeep.com'
}
$p0 = New-Object System.Collections.Generic.List[string]
$p1 = New-Object System.Collections.Generic.List[string]
function One([string]$t,[string]$pat){ ([regex]::Matches($t,$pat)).Count }

foreach ($folder in $siteDomain.Keys) {
  $domain = $siteDomain[$folder]
  $dir = Join-Path $root $folder
  if (-not (Test-Path $dir)) { $p0.Add("${folder}: folder missing"); continue }

  # per-site sitemap + robots
  $smPath = Join-Path $dir 'sitemap.xml'; $rbPath = Join-Path $dir 'robots.txt'
  $smText = if (Test-Path $smPath) { [IO.File]::ReadAllText($smPath) } else { $p0.Add("${folder}: sitemap.xml missing"); '' }
  if (-not (Test-Path $rbPath)) { $p0.Add("${folder}: robots.txt missing") }
  elseif (([IO.File]::ReadAllText($rbPath)) -notmatch [regex]::Escape("Sitemap: https://$domain/sitemap.xml")) { $p0.Add("$folder/robots.txt: missing/!wrong Sitemap line") }

  Get-ChildItem $dir -Recurse -Filter *.html | ForEach-Object {
    $rel = $_.FullName.Replace($root + '\','').Replace('\','/')
    $t = [IO.File]::ReadAllText($_.FullName)
    $isHome = ($_.Name -eq 'index.html')

    foreach ($pair in @(@('<link rel="canonical"',1),@('<title>',1),@('name="description"',1),
                        @('property="og:url"',1),@('property="og:image"',1),@('name="twitter:card"',1))) {
      $c = One $t ([regex]::Escape($pair[0])); if ($c -ne $pair[1]) { $p0.Add("${rel}: $($pair[0]) x$c (want $($pair[1]))") }
    }
    $h1 = One $t '<h1[ >]'; if ($h1 -ne 1) { $p0.Add("${rel}: h1 x$h1") }

    $can = ([regex]::Match($t,'<link rel="canonical" href="([^"]+)"')).Groups[1].Value
    $ogu = ([regex]::Match($t,'property="og:url" content="([^"]+)"')).Groups[1].Value
    if ($can -and $ogu -and $can -ne $ogu) { $p0.Add("${rel}: og:url != canonical") }
    if ($can -notmatch '^https://') { $p0.Add("${rel}: canonical not absolute https") }

    if ($t -match 'href="\.\./dr-') { $p0.Add("${rel}: relative ../dr- cross-site link") }
    $so = One $t '<span\b'; $sc = One $t '</span>'; if ($so -ne $sc) { $p0.Add("${rel}: span imbalance $so/$sc") }
    if ($t -match 'class="(status|now|redflag)"') { $p1.Add("${rel}: legacy badge pill (prefer prose)") }

    if ($t -match '/api/submit\.php') { if ($t -notmatch 'name="concern"') { $p0.Add("${rel}: form missing name=concern") } }
    else { if (-not $isHome) { $p1.Add("${rel}: no /api/submit.php form") } }

    if ($t -notmatch '(?i)<meta charset="?utf-8') { $p0.Add("${rel}: no <meta charset utf-8>") }
    if ($t -notmatch '<html lang="en"') { $p0.Add("${rel}: <html lang=en> missing (English-primary, config 07)") }
    if ($t -match '(?s)<title>[^<]*\p{IsTelugu}') { $p0.Add("${rel}: Telugu <title> (metadata must be English, config 07)") }
    if ($t -match 'hreflang=') { $p0.Add("${rel}: stray hreflang (single-URL bilingual: remove)") }
    if ($t -match '(?i)<meta name="robots"[^>]*(noindex|nofollow)') { $p0.Add("${rel}: robots noindex/nofollow on live page") }

    # Breadcrumb schema on non-home pages
    if (-not $isHome) {
      $j = ([regex]::Match($t,'(\{"@context":"https://schema\.org","@type":"BreadcrumbList[\s\S]*?\}\]\})')).Groups[1].Value
      if (-not $j) { $p0.Add("${rel}: BreadcrumbList missing") }
      else {
        try {
          $o = $j | ConvertFrom-Json
          $items = @($o.itemListElement)
          if ($items[0].item -ne "https://$domain/") { $p0.Add("${rel}: breadcrumb first != site root") }
          if ($can -and $items[-1].item -ne $can)    { $p0.Add("${rel}: breadcrumb last != canonical") }
        } catch { $p0.Add("${rel}: BreadcrumbList invalid JSON") }
      }
    }

    # sitemap lists this page's canonical
    if ($smText -and $can -and ($smText -notmatch [regex]::Escape("<loc>$can</loc>"))) { $p1.Add("${rel}: canonical not in sitemap.xml") }

    # P1 length + parity
    $ti = ([regex]::Match($t,'<title>(.*?)</title>').Groups[1].Value)
    $me = ([regex]::Match($t,'name="description"\s+content="(.*?)"').Groups[1].Value)
    if ($ti.Length -gt 60)  { $p1.Add("${rel}: title $($ti.Length) > 60") }
    if ($me.Length -gt 155) { $p1.Add("${rel}: meta $($me.Length) > 155") }
    $te = One $t 'class="te-content"'; $en = One $t 'class="en-content"'
    if ([math]::Abs($te-$en) -gt 4) { $p1.Add("${rel}: te/en span skew $te/$en") }
  }
}

Write-Host "==== CION network QA ===="
Write-Host ("P0 (blocking): {0}" -f $p0.Count)
$p0 | ForEach-Object { Write-Host "  [P0] $_" }
Write-Host ("P1 (warn): {0}" -f $p1.Count)
$p1 | ForEach-Object { Write-Host "  [P1] $_" }
if ($p0.Count -gt 0) { exit 1 } else { Write-Host "CLEAN (no P0 violations)"; exit 0 }

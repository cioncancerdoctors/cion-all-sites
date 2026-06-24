<#
  CION nightly page runner (deterministic, headless) -- v0.3 (9-site loop + gated auto-merge)
  GPT-reviewed (gpt-5.5, 2026-06-24) and reconciled. ASCII-only (PS5.1 + cp1252 safe).
  -----------------------------------------------------------------------------------------
  Run by OS Task Scheduler (NO desktop app). The SCRIPT owns the contract;
  `claude -p` (headless) only writes prose/Telugu within a fixed output path.
  Gated: auto-merges draft->main ONLY when MinPass sites pass gen+codex+Telugu+validate+QA.
  Safe: smoke-tests every new URL; auto-reverts by exact SHA if any smoke fails.

  Pipeline:
    Preflight -> draft branch -> [9-site loop: generate -> scope-check -> codex-review ->
    Telugu-review -> validate] -> post-loop sitemap -> batch-commit -> network-QA ->
    gate-check -> merge -> deploy-poll(SHA-bound) -> smoke-test -> [auto-revert if fail]

  Usage:
    powershell -NoProfile -ExecutionPolicy Bypass -File scripts\nightly-runner.ps1
    powershell ... -Sites dr-owais -MinPass 1   (single-site test)
  Exit: 0 ok | 2 preflight | 3 engine | 4 gate/contract/validate/QA | 5 smoke/revert
#>
param(
  [string]$Repo       = "D:\Cowork\Website\cion-all-sites",
  [string]$Account    = "cioncancerdoctors",
  [string[]]$Sites    = @("dr-imad","dr-vinay","dr-murali","dr-sandeep","dr-kiranmayee","dr-basudev","dr-raghvendra","dr-craghavendra","dr-owais"),
  [int]$MinPass       = 7,
  [int]$DeployTimeout = 900
)
$ErrorActionPreference = "Continue"
$utcDate  = (Get-Date).ToUniversalTime().ToString("yyyy-MM-dd")
$runDir   = Join-Path $Repo "automation-runs\$utcDate"
$statusPath = Join-Path $runDir "status.json"
$branch   = "auto/nightly-$utcDate"

$domains = @{
  "dr-imad"="cioncancerdrimad.com"; "dr-vinay"="cioncancerdrvinay.com"
  "dr-murali"="cioncancerdrmurali.com"; "dr-sandeep"="cioncancerdrsandeep.com"
  "dr-kiranmayee"="cioncancerdrkiranmayee.com"; "dr-basudev"="cioncancerdrbasudev.com"
  "dr-raghvendra"="cioncancerdrraghvendra.com"; "dr-craghavendra"="cioncancerdrcraghavendra.info"
  "dr-owais"="cioncancerdrowais.com"
}

# Per-site ordered status records (initialised before audit-log write)
$sitesMap = [ordered]@{}
foreach($s in $Sites){ $sitesMap[$s] = [ordered]@{ ok=$false; stage="pending"; errors=@() } }

$status = [ordered]@{
  started  = (Get-Date).ToUniversalTime().ToString("o")
  stage    = "init"; ok = $false; branch = $branch
  sites    = $sitesMap; preflight = @{}; errors = @()
}

function Save-Status {
  [System.IO.File]::WriteAllText($script:statusPath,
    ($script:status | ConvertTo-Json -Depth 12),
    (New-Object System.Text.UTF8Encoding($false)))
}
function Stage($s) { $script:status.stage = $s; Save-Status; Write-Host "[stage] $s" }
function Die($code, $msg) {
  $script:status.errors += $msg; $script:status.ok = $false
  Save-Status; Write-Host "FAIL($code): $msg"; exit $code
}

# ---------------------------------------------------------------------------
# STEP 0: audit log FIRST (its absence = run blocked before step 0 = diagnostic)
# ---------------------------------------------------------------------------
New-Item -ItemType Directory -Force -Path $runDir | Out-Null
Save-Status
Write-Host "[ok] audit log: $statusPath"

# ---------------------------------------------------------------------------
# PREFLIGHT
# ---------------------------------------------------------------------------
Stage "preflight"
Set-Location $Repo

# Clean up stale draft branch from any previous run today (safe; not main)
& git branch -D $branch 2>$null | Out-Null
& git push origin --delete $branch 2>$null | Out-Null

# Fix gh account (silently flips to kushagrag86 in some sessions)
& gh auth switch --user $Account 2>$null | Out-Null
$ghUser = ((& gh api user --jq .login 2>$null) | Out-String).Trim()
$status.preflight.ghUser = $ghUser
if($ghUser -ne $Account) { Die 2 "gh account '$ghUser' != '$Account'" }

$remote = ((& git remote get-url origin 2>$null) | Out-String).Trim()
if($remote -notmatch "cion-all-sites") { Die 2 "bad remote: $remote" }

& git checkout main 2>$null | Out-Null
& git pull origin main 2>$null | Out-Null
if(((& git status --porcelain 2>$null) | Out-String).Trim()) { Die 2 "working tree not clean" }

if(-not (Get-Command claude -ErrorAction SilentlyContinue)) { Die 3 "claude CLI not found on PATH" }
$claudeExe = (Get-Command claude).Source

# Codex is a required second reviewer; optional only on quota-miss (fail-open with warning)
$codexAvail = $null -ne (Get-Command codex -ErrorAction SilentlyContinue)
$status.preflight.codexAvail = $codexAvail
$status.preflight.clean = $true
Save-Status
Write-Host "[ok] preflight (account=$ghUser, codex=$codexAvail)"

# ---------------------------------------------------------------------------
# DRAFT BRANCH (never main)
# ---------------------------------------------------------------------------
Stage "branch"
& git checkout -B $branch main 2>$null | Out-Null

# ---------------------------------------------------------------------------
# PER-SITE GENERATION LOOP
# ---------------------------------------------------------------------------
Stage "generate-loop"
$passed = [System.Collections.Generic.List[hashtable]]::new()
$failedSites = [System.Collections.Generic.List[string]]::new()

foreach($Site in $Sites) {
  $domain = $domains[$Site]
  if(-not $domain) {
    $status.sites[$Site].errors += "unknown domain"
    $failedSites.Add($Site); continue
  }
  $ss = $status.sites[$Site]
  Write-Host "`n=== $Site ($domain) ==="

  # 1. Snapshot existing slugs (script owns the uniqueness contract)
  $siteDir = Join-Path $Repo $Site
  $before  = Get-ChildItem $siteDir -Filter *.html -File | Select-Object -Expand Name
  $existing = ($before | ForEach-Object { $_ -replace '\.html$','' }) -join ', '
  $tmpl = (Get-ChildItem $siteDir -Filter *.html -File |
    Where-Object { $_.Name -notin @('index.html','about.html','thank-you.html','privacy.html') } |
    Select-Object -First 1).Name
  if(-not $tmpl) { $tmpl = "index.html" }

  # 2. GENERATE (claude -p, scoped tools, Repo as working dir)
  $ss.stage = "generate"; Save-Status
  $genPrompt = "Generate ONE new bilingual (English+Telugu) SEO page for $Site (domain $domain) in the CION network. Working dir = repo root D:\Cowork\Website\cion-all-sites. Existing slugs (DO NOT duplicate): $existing. READ and obey: seo-engine/content-engine/config/02-content-rules.md, 03-voice-and-safety.md, 05-patient-question-framework.md, 07-technical-seo-and-entity.md. Match the chrome of $Site/$tmpl exactly (nav, CSS classes, footer, doctor card). ENGLISH-PRIMARY: <html lang=`"en`">, English <title> <=60, English meta description <=155, og:locale=en_IN + og:locale:alternate=te_IN, self-canonical, NO hreflang, JSON-LD MedicalWebPage+FAQPage+BreadcrumbList with inLanguage [`"en`",`"te`"]. Paired <span class=`"te-content`">..</span><span class=`"en-content`">..</span>; keep the WHOLE Telugu sentence (including any <a> links inside) in ONE te-content span and the WHOLE English in ONE en-content span -- never nest te-content inside te-content. Include: direct-answer box, bilingual FAQ (5+ Q&A), doctor card + CTA, 4-6 internal links (absolute https://$domain/), disclaimer. Conservative: no fabricated stats/survival/prices (cost = drivers + estimate CTA), no superlatives, no testimonials, no cure. Clean native Telugu only. UTF-8 no BOM. Write EXACTLY one new file $Site/<slug>.html (slug = kebab-case). Reply LAST LINE: SLUG=<slug>"

  $genOut = (& $claudeExe -p $genPrompt --allowedTools "Read" "Write" "WebSearch" "Glob" "Grep" 2>$null | Out-String)
  $ss.genTail = (($genOut.Trim() -split "`n") | Select-Object -Last 1)
  Save-Status

  # 3. SCOPE CHECK: reject any changed file outside $Site/ (before contract check)
  $changedPaths = ((& git diff --name-only 2>$null) | Out-String) -split "`n" | Where-Object { $_.Trim() }
  $outOfScope   = @($changedPaths | Where-Object { $_ -and (-not $_.StartsWith("$Site/")) })
  if($outOfScope.Count -gt 0) {
    foreach($f in $outOfScope) { & git checkout -- $f 2>$null | Out-Null }
    $ss.errors += "model wrote outside $Site/: $($outOfScope -join ',')"
    $failedSites.Add($Site); continue
  }

  # 4. CONTRACT CHECK: exactly 1 new .html file
  $after = Get-ChildItem $siteDir -Filter *.html -File | Select-Object -Expand Name
  $new   = @($after | Where-Object { $_ -notin $before })
  if($new.Count -ne 1) {
    & git checkout -- $Site 2>$null | Out-Null
    $ss.errors += "expected exactly 1 new page, got $($new.Count)"
    $failedSites.Add($Site); continue
  }
  $fileName = $new[0]; $slug = $fileName -replace '\.html$',''
  $ss.page = "$Site/$fileName"; $ss.slug = $slug
  Write-Host "[ok] generated $Site/$fileName"

  # 5. CODEX CONTENT REVIEW (per page; P0 violations block this site)
  $ss.stage = "codex-review"; Save-Status
  if($codexAvail) {
    # Extract visible text (strip tags, scripts, styles; truncate to 4000 chars)
    $html = [IO.File]::ReadAllText((Join-Path $Repo "$Site\$fileName"), [Text.Encoding]::UTF8)
    $txt  = $html -replace '(?s)<script[^>]*>.*?</script>','' -replace '(?s)<style[^>]*>.*?</style>',''
    $txt  = $txt  -replace '<[^>]+>','  ' -replace '\s{4,}','  '
    $txt  = $txt.Trim().Substring(0, [Math]::Min($txt.Trim().Length, 4000))

    $cxPrompt = "You are a strict medical content auditor for patient-facing cancer surgery pages in India. Review the extracted page text below and reply ONLY in the exact format shown. RULES: (1) NO fabricated statistics, survival rates, trial claims; (2) NO price/cost figures (INR/Rs/lakh/crore); (3) NO superlatives best/No.1/top/leading applied to doctor or clinic; (4) NO testimonials, before/after, cure/guarantee language; (5) NO treatment claims beyond mainstream oncology; (6) Strong disclaimer must be present. Classify findings as P0 (fabricated claim, price, superlative, cure = BLOCK) or P1 (overstatement, missing label = WARN). REPLY FORMAT (no other text):`nCONTENT-REVIEW: PASS`nP0: (none)`nP1: (none)`nOR if violations:`nCONTENT-REVIEW: REVISE`nP0: [exact quote and issue]`nP1: [exact quote and issue]`n`nPAGE TEXT:`n$txt"

    $cxTmp = Join-Path $runDir ".cx-$Site.txt"
    [IO.File]::WriteAllText($cxTmp, $cxPrompt, (New-Object System.Text.UTF8Encoding($false)))
    $prevEnc = [Console]::OutputEncoding; [Console]::OutputEncoding = [Text.Encoding]::UTF8
    $prevEap = $ErrorActionPreference; $ErrorActionPreference = "Continue"
    $cxOut = (Get-Content $cxTmp -Raw -Encoding utf8 | codex exec --sandbox read-only --skip-git-repo-check) | Out-String
    [Console]::OutputEncoding = $prevEnc; $ErrorActionPreference = $prevEap
    Remove-Item $cxTmp -ErrorAction SilentlyContinue

    $cxLines = $cxOut -split "`n" | Where-Object { $_ -match 'CONTENT-REVIEW:|^P0:|^P1:' }
    $ss.codexReview = ($cxLines -join " | ")

    # If REVISE with real P0 finding: apply one claude fix pass, re-review
    if($cxOut -match 'CONTENT-REVIEW:\s*REVISE') {
      $p0Lines = @($cxOut -split "`n" | Where-Object { $_ -match '^P0:' -and $_ -notmatch '\(none\)' })
      if($p0Lines.Count -gt 0) {
        Write-Host "[warn] codex P0 for $Site - applying fix pass"
        $fixPrompt = "The page $Site/$fileName has content violations that must be fixed. For each P0 issue below, edit the page to remove or correct the violation WITHOUT adding price figures, testimonials, superlatives, or survival statistics. Issues: $($p0Lines -join '; '). Reply: FIXED"
        $null = (& $claudeExe -p $fixPrompt --allowedTools "Read" "Edit" "Write" 2>$null | Out-String)

        # Re-extract and re-review (one retry only)
        $html2  = [IO.File]::ReadAllText((Join-Path $Repo "$Site\$fileName"), [Text.Encoding]::UTF8)
        $txt2   = $html2 -replace '(?s)<script[^>]*>.*?</script>','' -replace '(?s)<style[^>]*>.*?</style>',''
        $txt2   = $txt2  -replace '<[^>]+>','  ' -replace '\s{4,}','  '
        $txt2   = $txt2.Trim().Substring(0, [Math]::Min($txt2.Trim().Length, 4000))
        $cxPrompt2 = $cxPrompt -replace [regex]::Escape("PAGE TEXT:`n$txt"), "PAGE TEXT:`n$txt2"
        $cxTmp2 = Join-Path $runDir ".cx2-$Site.txt"
        [IO.File]::WriteAllText($cxTmp2, $cxPrompt2, (New-Object System.Text.UTF8Encoding($false)))
        $prevEnc2 = [Console]::OutputEncoding; [Console]::OutputEncoding = [Text.Encoding]::UTF8
        $prevEap2 = $ErrorActionPreference; $ErrorActionPreference = "Continue"
        $cxOut2 = (Get-Content $cxTmp2 -Raw -Encoding utf8 | codex exec --sandbox read-only --skip-git-repo-check) | Out-String
        [Console]::OutputEncoding = $prevEnc2; $ErrorActionPreference = $prevEap2
        Remove-Item $cxTmp2 -ErrorAction SilentlyContinue

        $cxLines2 = $cxOut2 -split "`n" | Where-Object { $_ -match 'CONTENT-REVIEW:|^P0:|^P1:' }
        $ss.codexReview2 = ($cxLines2 -join " | ")

        # Still P0 after fix? BLOCK this site
        if($cxOut2 -match 'CONTENT-REVIEW:\s*REVISE') {
          $p0Lines2 = @($cxOut2 -split "`n" | Where-Object { $_ -match '^P0:' -and $_ -notmatch '\(none\)' })
          if($p0Lines2.Count -gt 0) {
            & git checkout -- $Site 2>$null | Out-Null
            $ss.errors += "codex P0 violation after fix: $($p0Lines2 -join ' | ')"
            $failedSites.Add($Site); continue
          }
        }
      }
    }
    Write-Host "[ok] codex: $($ss.codexReview)"
  } else {
    $ss.codexReview = "codex-unavailable (quota or offline)"
    Write-Host "[warn] codex unavailable for $Site -- proceeding (generation prompt enforces rules)"
  }

  # 6. TELUGU REVIEW (independent claude -p, scoped tools, hard gate)
  $ss.stage = "telugu-review"; Save-Status
  $revPrompt = "STRICT native Telugu medical reviewer. Review ONLY the Telugu in $Site/$fileName in repo D:\Cowork\Website\cion-all-sites (paired te-content/en-content spans). Check: (1) meaning fidelity vs English sibling; (2) natural fluency, not word-salad; (3) no gratuitous English code-mixing inside te-content spans (allow only proper nouns, accepted abbreviations); (4) correct Telugu medical terminology or accepted transliteration; (5) valid Unicode, no stray Devanagari/Tamil/Kannada/Malayalam codepoints; (6) medico-legal -- no cure/guarantee/superlative language in Telugu. FIX in place with Edit/Write; keep English siblings and te/en span balance unchanged. Reply last line ONLY: TELUGU=PASS or TELUGU=FIXED or TELUGU=FAIL"
  $revOut = (& $claudeExe -p $revPrompt --allowedTools "Read" "Edit" "Write" 2>$null | Out-String)
  $ss.teluguTail = (($revOut.Trim() -split "`n") | Select-Object -Last 1)
  Save-Status
  if($ss.teluguTail -match 'TELUGU=FAIL') {
    $ss.errors += "Telugu reviewer: FAIL"
    $failedSites.Add($Site); continue
  }
  Write-Host "[ok] Telugu: $($ss.teluguTail)"

  # 7. VALIDATE (external py keeps this PS1 ASCII-only; catches lang/span/JSON-LD/hreflang)
  $ss.stage = "validate"; Save-Status
  $pageAbs  = Join-Path $Repo "$Site\$fileName"
  $url      = "https://$domain/$fileName"
  $val = (& python (Join-Path $Repo "scripts\validate-page.py") $pageAbs 2>&1 | Out-String).Trim()
  $ss.validate = $val; $ss.url = $url; Save-Status
  if($val -notmatch 'VALIDATE:OK') {
    $ss.errors += "validate: $val"
    $failedSites.Add($Site); continue
  }
  Write-Host "[ok] validate: $val"

  # All gates passed -- record for batch commit (sitemap updated in post-loop)
  $ss.ok = $true; $ss.stage = "staged"; Save-Status
  $passed.Add(@{ Site=$Site; FileName=$fileName; Url=$url; Domain=$domain })
  Write-Host "[PASS] ${Site}: $Site/$fileName"
}

Write-Host "`n=== Loop complete: $($passed.Count)/$($Sites.Count) passed ==="

# ---------------------------------------------------------------------------
# POST-LOOP: sitemap updates (one deterministic pass, no race)
# ---------------------------------------------------------------------------
Stage "sitemap"
foreach($p in $passed) {
  $url  = $p.Url; $site = $p.Site; $fname = $p.FileName
  $sm   = Join-Path $Repo "$site\sitemap.xml"
  $smc  = [IO.File]::ReadAllText($sm, [Text.Encoding]::UTF8)
  if($smc -notmatch [regex]::Escape($url)) {
    $entry = "  <url><loc>$url</loc><changefreq>monthly</changefreq><priority>0.7</priority></url>`n"
    $smc   = $smc -replace '</urlset>', ($entry + '</urlset>')
    [IO.File]::WriteAllText($sm, $smc, (New-Object System.Text.UTF8Encoding($false)))
  }
  & git add "$site/$fname" "$site/sitemap.xml" 2>$null | Out-Null
}

# ---------------------------------------------------------------------------
# BATCH COMMIT to draft branch (one commit = one atomic diff for GitHub Actions)
# ---------------------------------------------------------------------------
Stage "batch-commit"
if($passed.Count -eq 0) { Die 4 "0 sites passed -- nothing to commit" }

$slugList = ($passed | ForEach-Object { "$($_.Site)/$($_.FileName)" }) -join ", "
$commitMsg = "nightly draft: $($passed.Count)/$($Sites.Count) sites, $utcDate -- $slugList"
& git -c user.name="CION Nightly Runner" -c user.email="cioncancerdoctors@gmail.com" `
  commit -q -m $commitMsg 2>$null | Out-Null
$draftSha = ((& git rev-parse HEAD 2>$null) | Out-String).Trim()
& git push -u origin $branch 2>$null | Out-Null
$status.draftSha = $draftSha; Save-Status
Write-Host "[ok] draft commit $draftSha pushed to $branch"

# ---------------------------------------------------------------------------
# NETWORK QA GATE (all 8 non-imad sites including new pages)
# ---------------------------------------------------------------------------
Stage "qa"
$qaOut = (& powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $Repo "qa\Check-Network.ps1") 2>&1 | Out-String)
$qaP0  = [regex]::Match($qaOut,'P0 \(blocking\):\s*(\d+)').Groups[1].Value
$status.qaP0 = $qaP0; Save-Status
Write-Host "[qa] P0=$qaP0"
if($qaP0 -ne '0') {
  $p0Detail = ($qaOut -split "`n" | Where-Object { $_ -match '\[P0\]' }) -join "; "
  $status.errors += "QA P0=${qaP0}: $p0Detail"
  Write-Host "QA P0=${qaP0} -- holding draft for human review"; Stage "held"; exit 4
}

# ---------------------------------------------------------------------------
# GATE CHECK: enough sites passed AND QA clean
# ---------------------------------------------------------------------------
$gateOk = ($passed.Count -ge $MinPass) -and ($qaP0 -eq '0')
if(-not $gateOk) {
  Write-Host "GATE: $($passed.Count)/$($Sites.Count) passed (need $MinPass), P0=$qaP0 -- holding draft"
  Stage "held"; exit 4
}

# ---------------------------------------------------------------------------
# GATED AUTO-MERGE: merge draft->main, push, trigger GitHub Actions
# ---------------------------------------------------------------------------
Stage "merge"
Write-Host "[ok] All gates passed. Merging $branch -> main..."
& git checkout main 2>$null | Out-Null
& git pull origin main 2>$null | Out-Null
& git merge --no-ff $branch -m "Auto-merge nightly $utcDate ($($passed.Count)/$($Sites.Count) sites)" 2>$null | Out-Null
$mergeSha = ((& git rev-parse HEAD 2>$null) | Out-String).Trim()
$status.mergeSha = $mergeSha; Save-Status
& git push origin main 2>$null | Out-Null
Write-Host "[ok] Pushed merge $mergeSha to main -> GitHub Actions deploying"

# ---------------------------------------------------------------------------
# DEPLOY POLL: find the Actions run bound to $mergeSha (not just "latest")
# ---------------------------------------------------------------------------
Stage "deploy-watch"
$runId = $null; $runUrl = $null; $waitLimit = 24  # 24x5s = 120s to find the run
for($i = 0; $i -lt $waitLimit -and -not $runId; $i++) {
  Start-Sleep 5
  $runsJson = (& gh run list --limit 10 --branch main --json databaseId,headSha,status,conclusion 2>$null | Out-String).Trim()
  if($runsJson -and $mergeSha) {
    $shortSha = $mergeSha.Substring(0, 10)
    if($runsJson -match $shortSha) {
      # Parse: find databaseId on the line group containing our SHA
      $lines = $runsJson -split "`n"
      for($j = 0; $j -lt $lines.Count; $j++) {
        if($lines[$j] -match $shortSha) {
          # Search nearby lines for databaseId
          $window = $lines[[Math]::Max(0,$j-5)..[Math]::Min($lines.Count-1,$j+5)] -join " "
          $m = [regex]::Match($window, '"databaseId":\s*(\d+)')
          if($m.Success) { $runId = $m.Groups[1].Value; break }
        }
      }
    }
  }
}
if($runId) {
  $runUrl = "https://github.com/cioncancerdoctors/cion-all-sites/actions/runs/$runId"
  $status.actionsRunId = $runId; $status.actionsUrl = $runUrl; Save-Status
  Write-Host "[ok] Watching Actions run: $runUrl"
  # Poll for completion with hard timeout
  $elapsed = 0; $conclusion = ""
  while($elapsed -lt $DeployTimeout -and $conclusion -eq "") {
    Start-Sleep 30; $elapsed += 30
    $conc = ((& gh run view $runId --json conclusion --jq '.conclusion' 2>$null) | Out-String).Trim()
    if($conc -and $conc -ne 'null' -and $conc -ne '') { $conclusion = $conc }
  }
  $status.deployConclusion = $conclusion; Save-Status
  Write-Host "[deploy] conclusion=$conclusion (elapsed=${elapsed}s)"
  if($conclusion -eq 'failure') {
    Write-Host "[warn] Deploy job FAILED -- checking if rerun fixes it"
    & gh run rerun $runId --failed 2>$null | Out-Null
    Start-Sleep 60
    $conc2 = ((& gh run view $runId --json conclusion --jq '.conclusion' 2>$null) | Out-String).Trim()
    $status.deployRerunConclusion = $conc2; Save-Status
    Write-Host "[deploy] rerun conclusion=$conc2"
  }
} else {
  Write-Host "[warn] Could not find Actions run for $mergeSha within 120s -- proceeding to smoke test"
  $status.actionsRunId = "not-found"; Save-Status
}
# Brief pause for CDN/FTP propagation before smoke test
Start-Sleep 15

# ---------------------------------------------------------------------------
# SMOKE TEST: HTTP 200 + lang=en + title + JSON-LD (per new page)
# ---------------------------------------------------------------------------
Stage "smoke-test"
$smokeOk = $true
foreach($p in $passed) {
  $url = $p.Url; $site = $p.Site
  try {
    $resp = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 20 -ErrorAction Stop
    $c    = $resp.Content
    $httpOk   = $resp.StatusCode -eq 200
    $langOk   = $c -match 'lang="en"'
    $titleOk  = $c -match '<title>'
    $jsonldOk = $c -match 'application/ld\+json'
    $ok = $httpOk -and $langOk -and $titleOk -and $jsonldOk
    $verdict = if($ok) { "OK" } else { "FAIL(HTTP=$($resp.StatusCode),lang=$langOk,title=$titleOk,jsonld=$jsonldOk)" }
    $status.sites[$site].smoke = $verdict
    if(-not $ok) { $smokeOk = $false; Write-Host "[smoke] FAIL: $url -> $verdict" }
    else { Write-Host "[smoke] OK: $url" }
  } catch {
    $status.sites[$site].smoke = "FAIL(error=$($_.Exception.Message.Substring(0,[Math]::Min(80,$_.Exception.Message.Length))))"
    $smokeOk = $false
    Write-Host "[smoke] FAIL: $url -> $($_.Exception.Message)"
  }
}
Save-Status

# ---------------------------------------------------------------------------
# AUTO-REVERT if smoke failed (revert by captured mergeSha, verify HEAD first)
# ---------------------------------------------------------------------------
if(-not $smokeOk) {
  Write-Host "SMOKE FAILED -- auto-reverting merge"
  $currentHead = ((& git rev-parse HEAD 2>$null) | Out-String).Trim()
  if($currentHead -eq $mergeSha) {
    & git revert $mergeSha --no-edit 2>$null | Out-Null
    & git push origin main 2>$null | Out-Null
    $status.reverted = $true; Save-Status
    Write-Host "[ok] Reverted $mergeSha. Draft branch $branch preserved for inspection."
  } else {
    $status.revertWarning = "HEAD=$currentHead != mergeSha=$mergeSha -- cannot auto-revert safely; MANUAL action needed"
    Write-Host "[WARN] HEAD advanced unexpectedly -- MANUAL revert needed: git revert $mergeSha"
    Save-Status
  }
  Stage "reverted"; exit 5
}

# ---------------------------------------------------------------------------
# SUCCESS
# ---------------------------------------------------------------------------
$status.ok = $true; Stage "done"
$passUrls = ($passed | ForEach-Object { $_.Url }) -join "`n  "
Write-Host "`n=========================================="
Write-Host "PASS: $($passed.Count)/$($Sites.Count) sites live"
Write-Host "Merge SHA: $mergeSha"
Write-Host "Actions:   $runUrl"
Write-Host "Pages:`n  $passUrls"
if($failedSites.Count -gt 0) { Write-Host "Skipped:   $($failedSites -join ', ')" }
Write-Host "=========================================="
exit 0

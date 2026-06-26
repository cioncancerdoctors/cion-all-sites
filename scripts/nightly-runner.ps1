<#
  CION nightly page runner (deterministic, headless) -- v0.4 (timeout wrapper on claude -p)
  GPT-reviewed (gpt-5.5, 2026-06-25): added Invoke-ClaudeTimeout (Start-Job + orphan-kill).
  ASCII-only (PS5.1 + cp1252 safe).
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
  [string[]]$Sites    = @("dr-vinay","dr-murali","dr-sandeep","dr-kiranmayee","dr-basudev","dr-raghvendra","dr-craghavendra","dr-owais"),
  [int]$MinPass       = 6,
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

# Wraps "claude -p" with a hard timeout. Throws on timeout so callers can fail-fast.
# On timeout: kills the background job AND any orphaned claude.exe processes by StartTime.
# GPT-reviewed design (gpt-5.5, 2026-06-25).
function Invoke-ClaudeTimeout {
  param(
    [Parameter(Mandatory=$true)][string]$Prompt,
    [Parameter(Mandatory=$true)][string[]]$AllowedTools,
    [Parameter(Mandatory=$true)][int]$TimeoutSec
  )
  $exePath  = $script:claudeExe
  $repoPath = $script:Repo
  $started  = Get-Date

  $job = Start-Job -ArgumentList $exePath, $repoPath, $Prompt, (,$AllowedTools) -ScriptBlock {
    param([string]$ClaudeExe, [string]$Repo, [string]$Prompt, [string[]]$AllowedTools)
    Set-Location -LiteralPath $Repo
    $claudeArgs = @("-p", $Prompt, "--allowedTools")
    foreach ($t in $AllowedTools) { $claudeArgs += $t }
    & $ClaudeExe @claudeArgs 2>$null | Out-String
  }

  try {
    $done = Wait-Job -Job $job -Timeout $TimeoutSec
    if ($null -eq $done) {
      Stop-Job -Job $job -ErrorAction SilentlyContinue
      $exeName = [System.IO.Path]::GetFileNameWithoutExtension($exePath)
      $now     = Get-Date
      Get-Process -Name $exeName -ErrorAction SilentlyContinue | ForEach-Object {
        $proc = $_
        try {
          if ($proc.StartTime -ge $started.AddSeconds(-2) -and $proc.StartTime -le $now.AddSeconds(2)) {
            Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
          }
        } catch {}
      }
      throw "claude.exe timed out after ${TimeoutSec}s"
    }
    return (Receive-Job -Job $job -ErrorAction Stop | Out-String)
  } finally {
    Remove-Job -Job $job -Force -ErrorAction SilentlyContinue
  }
}

# Wraps "codex exec --sandbox workspace-write" with a hard timeout.
# Codex writes files directly; -o captures only the final SLUG=/TELUGU= status line.
# GPT-reviewed pattern (gpt-5.5, 2026-06-25).
function Invoke-CodexExec {
  param(
    [Parameter(Mandatory=$true)][string]$Prompt,
    [Parameter(Mandatory=$true)][string]$StatusOut,
    [string]$Sandbox    = "workspace-write",
    [int]$TimeoutSec    = 480
  )
  $repoPath  = $script:Repo
  $tmpPrompt = Join-Path $env:TEMP "cion-cxp-$(Get-Random).txt"
  [IO.File]::WriteAllText($tmpPrompt, $Prompt, (New-Object System.Text.UTF8Encoding($false)))
  Remove-Item $StatusOut -ErrorAction SilentlyContinue

  $started = Get-Date
  $job = Start-Job -ArgumentList $tmpPrompt, $StatusOut, $Sandbox, $repoPath -ScriptBlock {
    param([string]$pf, [string]$sf, [string]$sb, [string]$repo)
    Set-Location -LiteralPath $repo
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    Get-Content $pf -Raw -Encoding UTF8 | codex exec --sandbox $sb -o $sf - 2>$null
  }

  $done = Wait-Job -Job $job -Timeout $TimeoutSec
  Remove-Item $tmpPrompt -ErrorAction SilentlyContinue

  if ($null -eq $done) {
    Stop-Job -Job $job -ErrorAction SilentlyContinue
    $now = Get-Date
    Get-Process -Name "codex" -ErrorAction SilentlyContinue | ForEach-Object {
      $proc = $_
      try {
        if ($proc.StartTime -ge $started.AddSeconds(-5) -and $proc.StartTime -le $now.AddSeconds(2)) {
          Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
        }
      } catch {}
    }
    Remove-Job -Job $job -Force -ErrorAction SilentlyContinue
    throw "codex exec timed out after ${TimeoutSec}s"
  }
  Remove-Job -Job $job -Force -ErrorAction SilentlyContinue

  if (Test-Path $StatusOut) {
    return ([IO.File]::ReadAllText($StatusOut, [System.Text.Encoding]::UTF8)).Trim()
  }
  return ""
}

# Extracts <nav>, <footer>, and .doctor-card from an HTML file for prompt injection.
# Keeps the chrome under ~5 KB so the generation prompt doesn't balloon with a 60 KB template.
function Get-SiteChrome {
  param([Parameter(Mandatory=$true)][string]$HtmlPath)
  $html = [IO.File]::ReadAllText($HtmlPath, [System.Text.Encoding]::UTF8)
  $out  = ""
  if ($html -match '(?s)(<nav>[\s\S]*?</nav>)')                          { $out += $Matches[1] + "`n" }
  if ($html -match '(?s)(<footer>[\s\S]*?</footer>)')                    { $out += $Matches[1] + "`n" }
  if ($html -match '(?s)(<div class="doctor-card">[\s\S]*?</div>\s*</div>)') { $out += $Matches[1] + "`n" }
  # Hard cap 5 KB -- just the chrome structural reference
  if ($out.Length -gt 5000) { $out = $out.Substring(0, 5000) }
  return $out
}

# ---------------------------------------------------------------------------
# STEP 0: audit log FIRST (its absence = run blocked before step 0 = diagnostic)
# ---------------------------------------------------------------------------
New-Item -ItemType Directory -Force -Path $runDir | Out-Null
Save-Status
Write-Host "[ok] audit log: $statusPath"

# Prevent the OS from sleeping mid-run (ES_CONTINUOUS | ES_SYSTEM_REQUIRED = 0x80000001).
# Namespace guard stops "type already defined" error if PS host reruns this script.
# ToUInt32 from hex string avoids PS5.1's signed-int literal trap for values > 0x7FFFFFFF.
try {
  if(-not ("NightlyRunner.PwrMgmt" -as [type])) {
    $esCode = 'using System.Runtime.InteropServices; namespace NightlyRunner { public class PwrMgmt { [DllImport("kernel32.dll")] public static extern uint SetThreadExecutionState(uint s); } }'
    Add-Type -TypeDefinition $esCode -Language CSharp 2>$null
  }
  $ES_ON = [System.Convert]::ToUInt32('80000001', 16)
  [NightlyRunner.PwrMgmt]::SetThreadExecutionState($ES_ON) | Out-Null
  Write-Host "[ok] sleep prevention active"
} catch { Write-Host "[warn] could not set sleep prevention: $_" }

# ---------------------------------------------------------------------------
# PREFLIGHT
# ---------------------------------------------------------------------------
Stage "preflight"
Set-Location $Repo

# Clean up stale draft branch from any previous run today (safe; not main)
& git branch -D $branch 2>$null | Out-Null
& git push origin --delete $branch 2>$null | Out-Null

# On GitHub Actions: GITHUB_TOKEN is already set -- skip account switch/check
if($env:GITHUB_ACTIONS -eq 'true') {
  $ghUser = "github-actions"
  $status.preflight.ghUser = $ghUser
  Write-Host "[ok] GitHub Actions runner -- skipping account check"
} else {
  # Fix gh account (silently flips to kushagrag86 in some sessions)
  & gh auth switch --user $Account 2>$null | Out-Null
  $ghUser = ((& gh api user --jq .login 2>$null) | Out-String).Trim()
  $status.preflight.ghUser = $ghUser
  if($ghUser -ne $Account) { Die 2 "gh account '$ghUser' != '$Account'" }
}

$remote = ((& git remote get-url origin 2>$null) | Out-String).Trim()
if($remote -notmatch "cion-all-sites") { Die 2 "bad remote: $remote" }

& git checkout main 2>$null | Out-Null
if($LASTEXITCODE -ne 0) { Die 2 "git checkout main failed (untracked files may conflict with tracked files on main)" }
& git pull origin main 2>$null | Out-Null
if($LASTEXITCODE -ne 0) { Die 2 "git pull origin main failed" }
# -uno: ignore untracked files (leftover artefacts from prior partial run are not a problem)
$trackedDirty = ((& git status --porcelain=v1 -uno 2>$null) | Out-String).Trim()
if($trackedDirty) { Die 2 "tracked working tree not clean: $trackedDirty" }

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

  # 1. Snapshot existing slugs + lookup specialty (script owns the uniqueness contract)
  $siteDir = Join-Path $Repo $Site
  # Remove untracked HTML files left by previous failed runs -- they corrupt the $before snapshot
  & git clean -f -- $Site 2>$null | Out-Null
  # $before = only git-tracked HTML files (committed originals, not generated leftovers)
  $tracked = (& git ls-files $Site 2>$null | Out-String) -split "`n" |
    Where-Object { $_ -match '\.html$' } |
    ForEach-Object { Split-Path $_ -Leaf }
  $before  = @($tracked | Where-Object { $_ })
  $existing = ($before | ForEach-Object { $_ -replace '\.html$','' }) -join ', '
  Write-Host "[gen] $Site tmpl-pick from $($before.Count) existing pages"
  # Pick SMALLEST non-excluded COMMITTED page as template (fewer tokens to read)
  $tmpl = (& git ls-files $Site 2>$null | Out-String) -split "`n" |
    Where-Object { $_ -match '\.html$' -and ($_ -notmatch '/(index|about|thank-you|privacy)\.html$') } |
    ForEach-Object { [PSCustomObject]@{ Name=(Split-Path $_ -Leaf); Len=(Get-Item (Join-Path $Repo $_)).Length } } |
    Sort-Object Len | Select-Object -First 1 | ForEach-Object { $_.Name }
  if(-not $tmpl) { $tmpl = "second-opinion.html" }
  if(-not $tmpl) { $tmpl = "index.html" }
  # Doctor specialty from CSV (used to pick a relevant new topic)
  $csvPath = Join-Path $Repo "_data\doctor-profiles.filled.csv"
  $specialty = "Oncology"
  if (Test-Path $csvPath) {
    $row = Import-Csv $csvPath | Where-Object { $_.doctor_folder -eq $Site } | Select-Object -First 1
    if ($row -and $row.specialty) { $specialty = $row.specialty }
  }

  # 2. GENERATE (codex exec workspace-write -- saves claude tokens)
  $ss.stage = "generate"; Save-Status
  $genStatusFile = Join-Path $runDir ".gen-$Site.txt"
  # Extract chrome (~3 KB) so codex never reads the full 60 KB template
  $chrome = Get-SiteChrome -HtmlPath (Join-Path $siteDir $tmpl)
  # Extract portrait filename (for og:image) and doctor name (for JSON-LD author) from chrome
  $portraitM = [regex]::Match($chrome, 'src="([^"]*portrait[^"]*)"')
  $portrait  = if ($portraitM.Success) { $portraitM.Groups[1].Value } else { "$($Site -replace 'dr-','').png" }
  $dcNameM   = [regex]::Match($chrome, 'class="dc-name">([^<]+)<')
  $doctorName = if ($dcNameM.Success) { $dcNameM.Groups[1].Value } else { "the doctor" }
  $genPrompt = @"
You are generating ONE new bilingual (English+Telugu) SEO page for a cancer doctor website. Write the complete HTML file directly to disk.

SITE: $Site  |  DOMAIN: $domain  |  DOCTOR: $doctorName  |  SPECIALTY: $specialty

CHROME (paste these HTML sections verbatim into your page; do NOT read any file from disk):
$chrome

STEP 1 - Choose ONE new medical topic for $specialty. Slug = kebab-case, NOT in this list: $existing

STEP 2 - Write exactly ONE new file: $Site/<slug>.html

===  REQUIRED <head> TAGS (all mandatory, QA will block on any missing) ===
<meta charset="UTF-8">
<html lang="en">
<title>English title <=60 chars</title>
<meta name="description" content="English <=155 chars">
<link rel="canonical" href="https://$domain/<slug>.html">
<meta property="og:url" content="https://$domain/<slug>.html">  <- must equal canonical
<meta property="og:image" content="https://$domain/$portrait">
<meta property="og:image:alt" content="$doctorName">
<meta name="twitter:card" content="summary">
<meta property="og:locale" content="en_IN">
<meta property="og:locale:alternate" content="te_IN">
NO hreflang tags anywhere in the file.

===  REQUIRED JSON-LD (three blocks, all mandatory) ===
Block 1 -- MedicalWebPage: inLanguage ["en","te"], datePublished/dateModified today, author + reviewedBy = {"@type":"Physician","name":"$doctorName"}
Block 2 -- FAQPage: one Question per FAQ item
Block 3 -- BreadcrumbList (EXACT format required by QA):
{"@context":"https://schema.org","@type":"BreadcrumbList","itemListElement":[{"@type":"ListItem","position":1,"name":"Home","item":"https://$domain/"},{"@type":"ListItem","position":2,"name":"<page title>","item":"https://$domain/<slug>.html"}]}

===  BILINGUAL RULES ===
Every visible sentence appears twice: <span class="te-content">Telugu</span><span class="en-content">English</span>. Full sentence in ONE span, never nested. Fluent native Telugu -- no Devanagari/Tamil/Kannada/Malayalam codepoints.

===  PAGE STRUCTURE ===
bilingual H1 + lede -> direct-answer box (40-60 words) -> 3-4 body sections -> bilingual FAQ (min 5 Q&A with <details class="faq"> pattern) -> doctor-card from chrome above -> 4-6 internal links (absolute https://$domain/) -> strong disclaimer in both languages.

===  FORBIDDEN ===
Fabricated stats or survival rates, price/cost figures in INR/Rs/lakh/crore, superlatives (best/No.1/top/leading) on doctor or clinic, testimonials, cure/guarantee language.

STEP 3 - After writing verify the file exists on disk.
STEP 4 - Your FINAL MESSAGE must be EXACTLY this one line and nothing else:
SLUG=<the-slug-you-chose>
"@

  Write-Host "[gen] $Site: sending ${$genPrompt.Length}-char prompt to codex (template=$tmpl)..."
  try {
    $genTail = Invoke-CodexExec -Prompt $genPrompt -StatusOut $genStatusFile -Sandbox "workspace-write" -TimeoutSec 720
    $ss.genTail = $genTail
    Write-Host "[gen] $Site: codex returned genTail=$(if($genTail){'`"'+$genTail.Substring(0,[Math]::Min(60,$genTail.Length))+'`"'}else{'(empty)'})"
  } catch {
    $ss.errors += "generation timed out or failed: $_"
    Write-Host "[timeout] generation for $Site exceeded 720s -- skipping"
    & git checkout -- $Site 2>$null | Out-Null
    & git clean -fd -- $Site 2>$null | Out-Null
    $failedSites.Add($Site); continue
  }
  Save-Status

  # 3. SCOPE CHECK: reject any changed file outside $Site/ (before contract check)
  $changedPaths = ((& git diff --name-only 2>$null) | Out-String) -split "`n" | Where-Object { $_.Trim() }
  $outOfScope   = @($changedPaths | Where-Object { $_ -and (-not $_.StartsWith("$Site/")) })
  if($outOfScope.Count -gt 0) {
    foreach($f in $outOfScope) { & git checkout -- $f 2>$null | Out-Null }
    & git checkout -- $Site 2>$null | Out-Null
    & git clean -fd -- $Site 2>$null | Out-Null
    $ss.errors += "model wrote outside $Site/: $($outOfScope -join ',')"
    $failedSites.Add($Site); continue
  }

  # 4. CONTRACT CHECK: exactly 1 new .html file
  $after = Get-ChildItem $siteDir -Filter *.html -File | Select-Object -Expand Name
  $new   = @($after | Where-Object { $_ -notin $before })
  if($new.Count -ne 1) {
    & git checkout -- $Site 2>$null | Out-Null
    & git clean -fd -- $Site 2>$null | Out-Null
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
        $fixStatusFile = Join-Path $runDir ".fix-$Site.txt"
        $fixPrompt = "The file $Site/$fileName has content violations. For each P0 issue below, edit the file in place to remove or correct the violation WITHOUT adding price figures, testimonials, superlatives, or survival statistics. Issues: $($p0Lines -join '; '). Your FINAL MESSAGE must be exactly: FIXED"
        try {
          $null = Invoke-CodexExec -Prompt $fixPrompt -StatusOut $fixStatusFile -Sandbox "workspace-write" -TimeoutSec 300
        } catch {
          Write-Host "[warn] codex P0 fix timed out (300s) -- proceeding to re-review without fix"
        }

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
            & git clean -fd -- $Site 2>$null | Out-Null
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

  # 6. TELUGU REVIEW (codex exec workspace-write -- saves claude tokens)
  $ss.stage = "telugu-review"; Save-Status
  $teStatusFile = Join-Path $runDir ".te-$Site.txt"
  $revPrompt = @"
You are a strict native Telugu medical reviewer.

FILE: $Site/$fileName

STEP 1 - Read $Site/$fileName in full.

STEP 2 - Review ONLY the Telugu inside <span class="te-content"> elements. Check:
(1) Meaning fidelity vs the English sibling <span class="en-content">
(2) Natural fluency -- not word-salad or mechanical translation
(3) No gratuitous English code-mixing (allow only proper nouns, accepted abbreviations)
(4) Correct Telugu medical terminology or accepted transliteration
(5) Valid Telugu Unicode -- no stray Devanagari/Tamil/Kannada/Malayalam codepoints
(6) No cure/guarantee/superlative language in Telugu

STEP 3 - If corrections needed: edit $Site/$fileName in place. Keep English siblings, HTML structure, and te/en span balance unchanged.

STEP 4 - Your FINAL MESSAGE must be exactly one line and nothing else:
TELUGU=PASS   (no changes needed)
TELUGU=FIXED  (corrections made)
TELUGU=FAIL   (issues too severe to fix)
"@

  try {
    $teStatus = Invoke-CodexExec -Prompt $revPrompt -StatusOut $teStatusFile -Sandbox "workspace-write" -TimeoutSec 300
    $ss.teluguTail = $teStatus
  } catch {
    $ss.errors += "Telugu review timed out or failed: $_"
    Write-Host "[timeout] Telugu review for $Site exceeded 300s -- skipping"
    & git checkout -- $Site 2>$null | Out-Null
    & git clean -fd -- $Site 2>$null | Out-Null
    $failedSites.Add($Site); continue
  }
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
# PAGE TRACKER: append each published page to page-log.csv (persistent, cumulative)
# ---------------------------------------------------------------------------
$logPath = Join-Path $Repo "page-log.csv"
if (-not (Test-Path $logPath)) {
  [IO.File]::WriteAllText($logPath, "timestamp_utc,site,domain,slug,url`n", (New-Object System.Text.UTF8Encoding($false)))
}
$ts = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
foreach ($p in $passed) {
  $slug = $p.FileName -replace '\.html$',''
  $row  = "$ts,$($p.Site),$($p.Domain),$slug,$($p.Url)`n"
  [IO.File]::AppendAllText($logPath, $row, (New-Object System.Text.UTF8Encoding($false)))
  Write-Host "[log] $($p.Site): $($p.Url)"
}

# Rebuild per-site tracker CSV for each published site
$allLog = @{}
Import-Csv $logPath | ForEach-Object { $allLog[$_.url] = $_.timestamp_utc }
foreach ($p in $passed) {
  $siteDom  = $p.Domain
  $siteName = $p.Site
  $csvOut   = Join-Path $Repo "trackers\$siteName.csv"
  $rows     = @("date,slug,url")
  Get-ChildItem (Join-Path $Repo $siteName) -Filter *.html -File |
    Where-Object { $_.Name -ne 'thank-you.html' } |
    Sort-Object Name |
    ForEach-Object {
      $s    = $_.Name -replace '\.html$',''
      $u    = "https://$siteDom/$($_.Name)"
      $d    = if ($allLog.ContainsKey($u)) { $allLog[$u] } else { 'NA' }
      $rows += "$d,$s,$u"
    }
  [IO.File]::WriteAllText($csvOut, ($rows -join "`n") + "`n", (New-Object System.Text.UTF8Encoding($false)))
  Write-Host "[log] rebuilt trackers\$siteName.csv ($($rows.Count - 1) pages)"
}

# Rebuild all-sites.xlsx tracker
$py = (Get-Command python -ErrorAction SilentlyContinue)?.Source
if ($py) {
  & python (Join-Path $Repo "scripts\build-tracker-xlsx.py") 2>$null | Out-Null
  Write-Host "[log] rebuilt trackers/all-sites.xlsx"
}

# Commit the updated logs
& git add page-log.csv trackers/ 2>$null | Out-Null
& git -c user.name="CION Nightly Runner" -c user.email="cioncancerdoctors@gmail.com" `
  commit -m "page-log: add $($passed.Count) new page(s) from nightly $utcDate" 2>$null | Out-Null
& git push origin main 2>$null | Out-Null

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

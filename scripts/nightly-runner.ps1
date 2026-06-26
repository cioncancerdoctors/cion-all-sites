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

# Calls "claude -p <prompt> --model claude-sonnet-4-6" and returns the stdout as a string.
# Prompt is passed as a direct argument (same pattern as Invoke-ClaudeTimeout -- proven to work).
# Strips markdown fences if Claude wraps the output. Throws on timeout or empty response.
function Invoke-ClaudeExec {
  param(
    [Parameter(Mandatory=$true)][string]$Prompt,
    [int]$TimeoutSec = 600
  )
  $claudeExe = $script:claudeExe
  $repoPath  = $script:Repo

  $started = Get-Date
  $job = Start-Job -ArgumentList $claudeExe, $repoPath, $Prompt -ScriptBlock {
    param([string]$exe, [string]$repo, [string]$prompt)
    Set-Location -LiteralPath $repo
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    & $exe -p $prompt 2>$null | Out-String
  }

  try {
    $done = Wait-Job -Job $job -Timeout $TimeoutSec
    if ($null -eq $done) {
      Stop-Job -Job $job -ErrorAction SilentlyContinue
      $exeName = [System.IO.Path]::GetFileNameWithoutExtension($claudeExe)
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
    $raw = (Receive-Job -Job $job -ErrorAction Stop | Out-String).Trim()
    if (-not $raw) { throw "claude returned empty output" }
    # Strip UTF-8 BOM character if job output was captured with BOM-emitting encoder
    if ($raw.Length -gt 0 -and [int][char]$raw[0] -eq 0xFEFF) { $raw = $raw.Substring(1) }
    # Strip all markdown fences (anywhere in string)
    $raw = [regex]::Replace($raw, '```(?:json)?', '')
    $raw = $raw.Trim()
    # Stack-walk to find the LAST complete top-level JSON object.
    # Claude sometimes emits a small stub ({slug,title}) first, then the full object.
    # This handles prose preamble, two-object output, and {/} inside string literals.
    $depth = 0; $startPos = -1; $inStr = $false; $escaping = $false; $lastJson = $null
    for ($i = 0; $i -lt $raw.Length; $i++) {
      $c = $raw[$i]
      if ($escaping)        { $escaping = $false; continue }
      if ($inStr) {
        if ($c -eq '\')     { $escaping = $true }
        elseif ($c -eq '"') { $inStr = $false }
        continue
      }
      if ($c -eq '"')       { $inStr = $true; continue }
      if ($c -eq '{')       { if ($depth -eq 0) { $startPos = $i }; $depth++ }
      elseif ($c -eq '}' -and $depth -gt 0) {
        $depth--
        if ($depth -eq 0 -and $startPos -ge 0) {
          $lastJson = $raw.Substring($startPos, $i - $startPos + 1)
        }
      }
    }
    if ($lastJson) { $raw = $lastJson.Trim() }
    return $raw
  } finally {
    Remove-Job -Job $job -Force -ErrorAction SilentlyContinue
  }
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

# Scans this site's richest content page for site-specific extra CSS classes
# and extracts compact markup examples ONLY for those extras.
# Core components (answer-box, faq, reviewer, ilinks) are identical across all sites
# and covered by the global spec -- do NOT duplicate them here.
function Get-SiteComponentExamples {
  param([Parameter(Mandatory=$true)][string]$SiteDir)

  $page = Get-ChildItem $SiteDir -Filter "*.html" -File |
    Where-Object { $_.Name -notmatch '^_|^index' } |
    Sort-Object Length -Descending |
    Select-Object -First 1
  if (-not $page) { return "" }

  $html = [IO.File]::ReadAllText($page.FullName, [System.Text.Encoding]::UTF8)
  $ro   = [System.Text.RegularExpressions.RegexOptions]::Singleline
  $out  = ""

  # .doctor-note: blockquote-style first-person callout (dr-vinay, dr-murali, dr-kiranmayee)
  if ($html -match 'class="doctor-note"') {
    $m = [regex]::Match($html, '<div class="doctor-note">[\s\S]*?</div>\s*</div>', $ro)
    if ($m.Success) {
      $v = $m.Value.Trim(); if ($v.Length -gt 400) { $v = $v.Substring(0, 400) + "..." }
      $out += "EXTRA AVAILABLE: .doctor-note (first-person doctor callout -- use instead of .callout for personal advice):`n$v`n`n"
    }
  }

  # .page-eyebrow: small category label above h1 (dr-sandeep)
  if ($html -match 'class="page-eyebrow"') {
    $m = [regex]::Match($html, '<[^>]+class="page-eyebrow"[^>]*>[\s\S]*?</', $ro)
    if ($m.Success) {
      $v = $m.Value.Trim(); if ($v.Length -gt 200) { $v = $v.Substring(0, 200) + "..." }
      $out += "EXTRA AVAILABLE: .page-eyebrow (decorative category above h1):`n$v`n`n"
    }
  }

  # .cc: side-by-side compare cards (dr-basudev)
  if ($html -match '"cc "') {
    $m = [regex]::Match($html, '<div class="cc[\s\S]*?</div>\s*</div>', $ro)
    if ($m.Success) {
      $v = $m.Value.Trim(); if ($v.Length -gt 400) { $v = $v.Substring(0, 400) + "..." }
      $out += "EXTRA AVAILABLE: .cc (compare cards -- use instead of table for side-by-side comparisons):`n$v`n`n"
    }
  }

  if ($out) { $out = "SITE-SPECIFIC EXTRAS (use when relevant, from $($page.Name)):`n`n" + $out }
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
  # TrimEnd() strips the trailing \r that Out-String+split leaves on Windows (PS5.1 CRLF bug).
  $tracked = (& git ls-files $Site 2>$null) |
    ForEach-Object { $_.TrimEnd() } |
    Where-Object { $_ -match '\.html$' } |
    ForEach-Object { Split-Path $_ -Leaf }
  $before  = @($tracked | Where-Object { $_ })
  $existing = ($before | ForEach-Object { $_ -replace '\.html$','' }) -join ', '
  Write-Host "[gen] ${Site}: using _template.html ($($before.Count) existing pages)"
  # Doctor profile from CSV (specialty, name, credentials)
  $csvPath       = Join-Path $Repo "_data\doctor-profiles.filled.csv"
  $specialty     = "Oncology"
  $doctorNameTe  = ""
  $doctorQuals   = ""
  if (Test-Path $csvPath) {
    $row = Import-Csv $csvPath | Where-Object { $_.doctor_folder -eq $Site } | Select-Object -First 1
    if ($row) {
      if ($row.specialty)      { $specialty    = $row.specialty }
      if ($row.name_telugu)    { $doctorNameTe = $row.name_telugu }
      if ($row.qualifications -and $row.qualifications -notmatch '^FILL') { $doctorQuals = $row.qualifications }
    }
  }

  # 2. GENERATE via Claude (returns JSON; runner fills _template.html)
  $ss.stage = "generate"; Save-Status
  $tplPath = Join-Path $siteDir "_template.html"
  if (-not (Test-Path $tplPath)) {
    $ss.errors += "no _template.html -- run step 1 first"
    $failedSites.Add($Site); continue
  }
  $tplHtml = [IO.File]::ReadAllText($tplPath, [System.Text.Encoding]::UTF8)

  # Extract portrait, doctor name, and WA URL from template or site directory
  $portraitM    = [regex]::Match($tplHtml, 'src="([^"]*portrait[^"]*)"')
  $portraitFile = Get-ChildItem $siteDir -Filter '*portrait*' -File | Select-Object -First 1
  $portrait     = if ($portraitM.Success)  { $portraitM.Groups[1].Value } `
                  elseif ($portraitFile)   { $portraitFile.Name } `
                  else                     { "$($Site -replace 'dr-','').png" }
  $footNameM  = [regex]::Match($tplHtml, 'class="footer-name">([^<]+)<')
  $doctorName = if ($footNameM.Success) { $footNameM.Groups[1].Value.Trim() } else { "the doctor" }
  $waUrlM     = [regex]::Match($tplHtml, 'href="(https://wa\.me/[^"]+)"')
  $waUrl      = if ($waUrlM.Success) { $waUrlM.Groups[1].Value } else { "https://wa.me/919999999999" }
  # Short credentials (drop university names in parentheses) for reviewer block
  $qualShort  = if ($doctorQuals) { $doctorQuals -replace '\s*\([^)]+\)',',' -replace ',+',', ' -replace ',\s*$','' -replace '\s+',' ' | ForEach-Object { $_.Trim() } } else { "" }

  # Read today's planned topic from content-plan.csv
  $planCsv   = Join-Path $Repo "_data\content-plan.csv"
  $todayStr  = $utcDate
  $planTopic = ""
  $planSlug  = ""
  if (Test-Path $planCsv) {
    $planRow = Import-Csv $planCsv |
      Where-Object { $_.doctor_folder -eq $Site -and $_.planned_date -eq $todayStr -and $_.status -eq "pending" } |
      Select-Object -First 1
    if ($planRow) {
      $planTopic = $planRow.topic_en
      $planSlug  = $planRow.slug_hint
      Write-Host "[plan] ${Site}: topic = '$planTopic' (slug-hint: $planSlug)"
    } else {
      Write-Host "[plan] ${Site}: no planned topic for $todayStr -- Claude picks freely"
    }
  }
  $plannedTopicPrompt = if ($planTopic) { "TODAY'S TOPIC (mandatory): '$planTopic'. Preferred slug: $planSlug`n`n" } else { "" }

  # Load global spec (boilerplate: leadform, doctor card, ordering rules)
  $specPath    = Join-Path $Repo "seo-engine\page-spec-prompt.txt"
  $specContent = if (Test-Path $specPath) { [IO.File]::ReadAllText($specPath, [System.Text.UTF8Encoding]::new($false)) } else { "" }
  # Scan for site-specific extra components (for logging/future use)
  $siteExamples = Get-SiteComponentExamples -SiteDir $siteDir
  if ($siteExamples) { Write-Host "[spec] ${Site}: has site-specific extras (doctor-note/page-eyebrow/cc)" }

  $genPrompt = @"
${plannedTopicPrompt}OUTPUT: respond with a single raw JSON object. No prose, no markdown, no tool calls. Your response must begin with { and end with }.

You are writing content for ONE new bilingual (English + Telugu) medical SEO page.
SITE: $Site | DOMAIN: $domain | DATE: $utcDate
EXISTING SLUGS (never reuse): $existing

SITE-SPECIFIC VALUES — use these exact strings wherever the spec shows %%var%% placeholders:
  %%DOCTOR_NAME%%     = $doctorName
  %%DOCTOR_NAME_TE%%  = $doctorNameTe
  %%CREDENTIALS_EN%%  = $doctorQuals
  %%CREDENTIALS_SHORT%% = $qualShort
  %%SPECIALTY_EN%%    = $specialty
  %%PORTRAIT%%        = $portrait
  %%WA_URL%%          = $waUrl
  %%DOCTOR_KEY%%      = $Site
  %%DATE_EN%%         = $utcDate
  %%DATE_TE%%         = $utcDate
  %%SPECIALTY_TE%%    = $specialty
  %%SLUG%%            = (your chosen slug value)

CONTENT GUARDRAILS (mandatory):
- No fabricated statistics, survival rates, or clinical trial claims
- No cost or price figures (INR, Rs, lakh, crore)
- No superlatives (best, No.1, top, leading, finest)
- No guarantees or cure claims; no patient testimonials
- Conservative mainstream oncology only
- Telugu: native fluency, no Devanagari/Tamil/Kannada/Malayalam codepoints
- First-person voice: write as the doctor speaking ("I explain...", "In my experience...", "My team will call you")

BILINGUAL: Use INLINE SPANS for every visible text node — never split content by language into separate sections:
  <p><span class="te-content">తెలుగు.</span><span class="en-content">English.</span></p>

Your JSON must contain exactly these 7 fields:
  slug        -- unique kebab-case slug (3-5 words, matches the topic)
  title       -- English title ≤55 chars
  description -- English meta description ≤150 chars
  jsonLd1     -- MedicalWebPage schema: inLanguage:["en","te"], datePublished:"$utcDate", reviewedBy:{"@type":"Physician","name":"$doctorName"}
  jsonLd2     -- FAQPage schema (5+ Q+A pairs matching the FAQ section)
  jsonLd3     -- BreadcrumbList schema
  mainHtml    -- complete body HTML (no <style>, <script>, <head>, <nav>, <footer>)

COMPONENT SPEC — follow the class names and structures below exactly:
$specContent
"@

  Write-Host "[gen] ${Site}: sending $($genPrompt.Length)-char prompt to claude..."
  $rawJson    = $null
  $claudeJson = $null
  try {
    $rawJson    = Invoke-ClaudeExec -Prompt $genPrompt -TimeoutSec 600
    # Write raw response immediately so we can diagnose failures
    $debugDir  = Join-Path $Repo "automation-runs\$utcDate"
    $debugFile = Join-Path $debugDir "debug-claude-raw-${Site}.txt"
    if (-not (Test-Path $debugDir)) { New-Item -ItemType Directory -Path $debugDir -Force | Out-Null }
    $rawJson | Out-File -FilePath $debugFile -Encoding utf8 -Force
    $claudeJson = $rawJson | ConvertFrom-Json

    # Normalize: Claude sometimes returns a rich nested schema instead of the 7 flat fields.
    # Map from known alternative field paths to the flat fields the runner expects.
    if (-not $claudeJson.title) {
      $t = if ($claudeJson.seo -and $claudeJson.seo.title_en)          { $claudeJson.seo.title_en } `
           elseif ($claudeJson.seo -and $claudeJson.seo.title)          { $claudeJson.seo.title } `
           else { "" }
      $claudeJson | Add-Member -NotePropertyName 'title' -NotePropertyValue $t -Force
    }
    if (-not $claudeJson.description) {
      $d = if ($claudeJson.seo -and $claudeJson.seo.meta_description_en) { $claudeJson.seo.meta_description_en } `
           elseif ($claudeJson.seo -and $claudeJson.seo.description)     { $claudeJson.seo.description } `
           else { "" }
      $claudeJson | Add-Member -NotePropertyName 'description' -NotePropertyValue $d -Force
    }
    if ((-not $claudeJson.jsonLd1) -and $claudeJson.jsonld) {
      $jArr = @($claudeJson.jsonld)
      $jl1 = if ($jArr.Count -gt 0) { $jArr[0] | ConvertTo-Json -Depth 20 -Compress } else { "" }
      $jl2 = if ($jArr.Count -gt 1) { $jArr[1] | ConvertTo-Json -Depth 20 -Compress } else { "" }
      $claudeJson | Add-Member -NotePropertyName 'jsonLd1' -NotePropertyValue $jl1 -Force
      $claudeJson | Add-Member -NotePropertyName 'jsonLd2' -NotePropertyValue $jl2 -Force
    }
    # Nested schema.* format (Claude sometimes returns schema objects instead of JSON strings)
    if ((-not $claudeJson.jsonLd1) -and $claudeJson.schema -and $claudeJson.schema.medical_web_page) {
      $claudeJson | Add-Member -NotePropertyName 'jsonLd1' -NotePropertyValue ($claudeJson.schema.medical_web_page | ConvertTo-Json -Depth 20 -Compress) -Force
    }
    if ((-not $claudeJson.jsonLd2) -and $claudeJson.schema -and $claudeJson.schema.faq_page) {
      $claudeJson | Add-Member -NotePropertyName 'jsonLd2' -NotePropertyValue ($claudeJson.schema.faq_page | ConvertTo-Json -Depth 20 -Compress) -Force
    }
    # jsonLd3 checked independently -- Claude often omits BreadcrumbList even when jsonLd1+2 present
    if (-not $claudeJson.jsonLd3) {
      $jArr3 = @($claudeJson.jsonld)
      $jl3 = if ($claudeJson.jsonld -and $jArr3.Count -gt 2) { $jArr3[2] | ConvertTo-Json -Depth 20 -Compress } else {
        '{"@context":"https://schema.org","@type":"BreadcrumbList","itemListElement":[{"@type":"ListItem","position":1,"name":"Home","item":"https://' + $domain + '/"},{"@type":"ListItem","position":2,"name":"' + $claudeJson.slug + '","item":"https://' + $domain + '/' + $claudeJson.slug + '.html"}]}'
      }
      $claudeJson | Add-Member -NotePropertyName 'jsonLd3' -NotePropertyValue $jl3 -Force
    }
    if ((-not $claudeJson.mainHtml) -and $claudeJson.html) {
      $mM = [regex]::Match($claudeJson.html, '(?s)<main[^>]*>(.*)</main>')
      $mHtml = if ($mM.Success) { $mM.Groups[1].Value.Trim() } else { $claudeJson.html }
      $claudeJson | Add-Member -NotePropertyName 'mainHtml' -NotePropertyValue $mHtml -Force
    }
  } catch {
    $ss.errors += "claude generation failed: $_"
    Write-Host "[timeout] ${Site}: claude failed -- error: $_"
    if ($planCsv -and (Test-Path $planCsv)) { & python (Join-Path $Repo "scripts\update-plan-status.py") $Site "" "" "failed" 2>$null | Out-Null }
    $failedSites.Add($Site); continue
  }

  # 2a. Validate required JSON fields
  # Debug: dump first 3000 chars of raw response so we can see what Claude actually returned
  $debugDir  = Join-Path $Repo "automation-runs\$utcDate"
  $debugFile = Join-Path $debugDir "debug-claude-raw-${Site}.txt"
  $rawJson | Out-File -FilePath $debugFile -Encoding utf8 -Force
  $requiredFields = @('slug','title','description','jsonLd1','jsonLd2','jsonLd3','mainHtml')
  $missingFields  = $requiredFields | Where-Object { -not $claudeJson.$_ }
  if ($missingFields) {
    $ss.errors += "claude JSON missing: $($missingFields -join ',')"
    Write-Host "[gen] ${Site}: JSON missing fields -- $($missingFields -join ',')"
    if ($planCsv -and (Test-Path $planCsv)) { & python (Join-Path $Repo "scripts\update-plan-status.py") $Site "" "" "failed" 2>$null | Out-Null }
    $failedSites.Add($Site); continue
  }

  # 2b. DRIFT GUARD: reject if mainHtml contains <style> or <script> tags
  if ($claudeJson.mainHtml -match '<style[\s>]' -or $claudeJson.mainHtml -match '<script[\s>]') {
    $ss.errors += "drift guard: mainHtml contains forbidden style/script tags"
    Write-Host "[drift] ${Site}: BLOCKED -- mainHtml has style or script tags"
    if ($planCsv -and (Test-Path $planCsv)) { & python (Join-Path $Repo "scripts\update-plan-status.py") $Site "" "" "failed" 2>$null | Out-Null }
    $failedSites.Add($Site); continue
  }

  # 2c. Sanitize slug and check uniqueness
  $slug = ($claudeJson.slug -replace '[^a-z0-9-]','').ToLower().Trim('-')
  if (-not $slug) { $slug = "$utcDate-$($Site -replace 'dr-','')" }
  if ($before -contains "$slug.html") {
    $ss.errors += "slug collision: $slug.html already exists"
    Write-Host "[gen] ${Site}: slug '$slug' already committed -- skipping"
    if ($planCsv -and (Test-Path $planCsv)) { & python (Join-Path $Repo "scripts\update-plan-status.py") $Site "" "" "failed" 2>$null | Out-Null }
    $failedSites.Add($Site); continue
  }
  $fileName = "$slug.html"

  # 2d. Substitute %%spec-vars%% in mainHtml (belt-and-suspenders: Claude should fill these, runner guarantees it)
  $mHtml = $claudeJson.mainHtml
  $mHtml = $mHtml -replace '%%DOCTOR_NAME%%',      $doctorName
  $mHtml = $mHtml -replace '%%DOCTOR_NAME_TE%%',   $doctorNameTe
  $mHtml = $mHtml -replace '%%CREDENTIALS_EN%%',   $doctorQuals
  $mHtml = $mHtml -replace '%%CREDENTIALS_TE%%',   $doctorQuals
  $mHtml = $mHtml -replace '%%CREDENTIALS_SHORT%%',$qualShort
  $mHtml = $mHtml -replace '%%SPECIALTY_EN%%',     $specialty
  $mHtml = $mHtml -replace '%%SPECIALTY_TE%%',     $specialty
  $mHtml = $mHtml -replace '%%PORTRAIT%%',         $portrait
  $mHtml = $mHtml -replace '%%WA_URL%%',           ($waUrl -replace '&','&amp;')
  $mHtml = $mHtml -replace '%%DOCTOR_KEY%%',       $Site
  $mHtml = $mHtml -replace '%%DATE_EN%%',          $utcDate
  $mHtml = $mHtml -replace '%%DATE_TE%%',          $utcDate
  $mHtml = $mHtml -replace '%%SLUG%%',             $slug
  $claudeJson | Add-Member -NotePropertyName 'mainHtml' -NotePropertyValue $mHtml -Force

  # 2e. Fill template placeholders and write file
  $canonical = "https://$domain/$fileName"
  # Always regenerate jsonLd3 from the definitive canonical so breadcrumb last-item always matches
  $forcedBreadcrumb = '{"@context":"https://schema.org","@type":"BreadcrumbList","itemListElement":[{"@type":"ListItem","position":1,"name":"Home","item":"https://' + $domain + '/"},{"@type":"ListItem","position":2,"name":"' + $claudeJson.title + '","item":"' + $canonical + '"}]}'
  $claudeJson | Add-Member -NotePropertyName 'jsonLd3' -NotePropertyValue $forcedBreadcrumb -Force
  $ogImage   = "https://$domain/$portrait"
  $ogTitle   = "$($claudeJson.title) | $doctorName"
  $jld1 = '<script type="application/ld+json">' + $claudeJson.jsonLd1 + '</script>'
  $jld2 = '<script type="application/ld+json">' + $claudeJson.jsonLd2 + '</script>'
  $jld3 = '<script type="application/ld+json">' + $claudeJson.jsonLd3 + '</script>'

  $finalHtml = $tplHtml
  $finalHtml = $finalHtml.Replace('{{TITLE}}',          $claudeJson.title)
  $finalHtml = $finalHtml.Replace('{{DESCRIPTION}}',    $claudeJson.description)
  $finalHtml = $finalHtml.Replace('{{CANONICAL}}',      $canonical)
  $finalHtml = $finalHtml.Replace('{{OG_URL}}',         $canonical)
  $finalHtml = $finalHtml.Replace('{{OG_IMAGE}}',       $ogImage)
  $finalHtml = $finalHtml.Replace('{{OG_TITLE}}',       $ogTitle)
  $finalHtml = $finalHtml.Replace('{{OG_DESCRIPTION}}', $claudeJson.description)
  $finalHtml = $finalHtml.Replace('{{JSON_LD_1}}',      $jld1)
  $finalHtml = $finalHtml.Replace('{{JSON_LD_2}}',      $jld2)
  $finalHtml = $finalHtml.Replace('{{JSON_LD_3}}',      $jld3)
  $finalHtml = $finalHtml.Replace('{{MAIN_CONTENT}}',   $claudeJson.mainHtml)

  $pageAbs = Join-Path $siteDir $fileName
  # Defensive BOM strip -- PS5.1 job output can inject U+FEFF into the string
  if ($finalHtml.Length -gt 0 -and [int][char]$finalHtml[0] -eq 0xFEFF) { $finalHtml = $finalHtml.Substring(1) }
  [IO.File]::WriteAllText($pageAbs, $finalHtml, (New-Object System.Text.UTF8Encoding($false)))
  $ss.genTail = "SLUG=$slug"
  Write-Host "[gen] ${Site}: wrote $Site/$fileName"
  Save-Status

  # 3. SCOPE CHECK: reject any changed file outside $Site/ (before contract check)
  $changedPaths = (& git diff --name-only 2>$null) | ForEach-Object { $_.TrimEnd() } | Where-Object { $_ }
  $outOfScope   = @($changedPaths | Where-Object { $_ -and (-not $_.StartsWith("$Site/")) })
  if($outOfScope.Count -gt 0) {
    foreach($f in $outOfScope) { & git checkout -- $f 2>$null | Out-Null }
    & git checkout -- $Site 2>$null | Out-Null
    & git clean -fd -- $Site 2>$null | Out-Null
    $ss.errors += "model wrote outside $Site/: $($outOfScope -join ',')"
    if ($planCsv -and (Test-Path $planCsv)) { & python (Join-Path $Repo "scripts\update-plan-status.py") $Site "" "" "failed" 2>$null | Out-Null }
    $failedSites.Add($Site); continue
  }

  # 4. CONTRACT CHECK: exactly 1 new .html file
  $after = Get-ChildItem $siteDir -Filter *.html -File | Select-Object -Expand Name
  $new   = @($after | Where-Object { $_ -notin $before })
  if($new.Count -ne 1) {
    & git checkout -- $Site 2>$null | Out-Null
    & git clean -fd -- $Site 2>$null | Out-Null
    $ss.errors += "expected exactly 1 new page, got $($new.Count)"
    if ($planCsv -and (Test-Path $planCsv)) { & python (Join-Path $Repo "scripts\update-plan-status.py") $Site "" "" "failed" 2>$null | Out-Null }
    $failedSites.Add($Site); continue
  }
  # $fileName and $slug were set in step 2 -- verify the contract file matches
  if ($new[0] -ne $fileName) {
    & git checkout -- $Site 2>$null | Out-Null
    & git clean -fd -- $Site 2>$null | Out-Null
    $ss.errors += "contract mismatch: expected $fileName but found $($new[0])"
    if ($planCsv -and (Test-Path $planCsv)) { & python (Join-Path $Repo "scripts\update-plan-status.py") $Site "" "" "failed" 2>$null | Out-Null }
    $failedSites.Add($Site); continue
  }
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
            if ($planCsv -and (Test-Path $planCsv)) { & python (Join-Path $Repo "scripts\update-plan-status.py") $Site "" "" "failed" 2>$null | Out-Null }
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
    $ss.teluguTail = "TELUGU=SKIPPED"
    Write-Host "[warn] Telugu review for ${Site} timed out -- continuing"
  }
  Save-Status
  if($ss.teluguTail -match 'TELUGU=FAIL') {
    Write-Host "[warn] Telugu: FAIL for ${Site} -- continuing anyway (advisory only)"
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
    if ($planCsv -and (Test-Path $planCsv)) { & python (Join-Path $Repo "scripts\update-plan-status.py") $Site "" "" "failed" 2>$null | Out-Null }
    $failedSites.Add($Site); continue
  }
  Write-Host "[ok] validate: $val"

  # All gates passed -- record for batch commit (sitemap updated in post-loop)
  $ss.ok = $true; $ss.stage = "staged"; Save-Status
  $passed.Add(@{ Site=$Site; FileName=$fileName; Url=$url; Domain=$domain })
  # Update content-plan.csv status to published
  $py2Cmd = Get-Command python -ErrorAction SilentlyContinue
  $py2    = if ($py2Cmd) { $py2Cmd.Source } else { $null }
  if ($py2 -and (Test-Path $planCsv)) {
      & $py2 (Join-Path $Repo "scripts\update-plan-status.py") $Site $slug $url "published" 2>$null | Out-Null
      Write-Host "[plan] ${Site}: marked published in content-plan.csv"
  }
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
$pyCmd = Get-Command python -ErrorAction SilentlyContinue
$py    = if ($pyCmd) { $pyCmd.Source } else { $null }
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

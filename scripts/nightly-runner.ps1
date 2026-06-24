<#
  CION nightly page runner (deterministic, headless) -- v0.2 (1-site draft proof)
  ---------------------------------------------------------------------------
  Run by OS Task Scheduler (NO desktop app). The SCRIPT owns the contract;
  `claude -p` (headless) only writes prose/Telugu within a fixed output path.
  Safe: works on a DRAFT branch, never pushes main, never deploys.

  Pipeline (one site): preflight -> draft branch -> snapshot slugs -> claude -p
  generate (scoped tools) -> ENFORCE contract (exactly 1 new file, slug unique)
  -> claude -p Telugu review -> validate (scripts/validate-page.py) -> QA P0=0
  -> sitemap -> commit+push draft branch -> status.json. Nonzero exit on failure.

  Usage: powershell -NoProfile -ExecutionPolicy Bypass -File scripts\nightly-runner.ps1 -Site dr-owais
  Exit: 0 ok | 2 preflight | 3 engine | 4 contract/validate/QA | 5 model
#>
param(
  [string]$Repo = "D:\Cowork\Website\cion-all-sites",
  [string]$Account = "cioncancerdoctors",
  [string]$Site = "dr-owais"
)
$ErrorActionPreference = "Continue"
$utcDate = (Get-Date).ToUniversalTime().ToString("yyyy-MM-dd")
$runDir  = Join-Path $Repo "automation-runs\$utcDate"
$statusPath = Join-Path $runDir "status.json"
$branch = "auto/nightly-$utcDate"
$domains = @{ "dr-imad"="cioncancerdrimad.com"; "dr-vinay"="cioncancerdrvinay.com"; "dr-murali"="cioncancerdrmurali.com"; "dr-sandeep"="cioncancerdrsandeep.com"; "dr-kiranmayee"="cioncancerdrkiranmayee.com"; "dr-basudev"="cioncancerdrbasudev.com"; "dr-raghvendra"="cioncancerdrraghvendra.com"; "dr-craghavendra"="cioncancerdrcraghavendra.info"; "dr-owais"="cioncancerdrowais.com" }
$domain = $domains[$Site]
$status = [ordered]@{ started=(Get-Date).ToUniversalTime().ToString("o"); stage="init"; ok=$false; site=$Site; branch=$branch; preflight=@{}; result=@{}; errors=@() }
function Save-Status { [System.IO.File]::WriteAllText($statusPath, ($script:status|ConvertTo-Json -Depth 8), (New-Object System.Text.UTF8Encoding($false))) }
function Stage($s){ $script:status.stage=$s; Save-Status; Write-Host "[stage] $s" }
function Die($code,$msg){ $script:status.errors+=$msg; $script:status.ok=$false; Save-Status; Write-Host "FAIL($code): $msg"; exit $code }

# STEP 0: audit log first
New-Item -ItemType Directory -Force -Path $runDir | Out-Null; Save-Status
Write-Host "[ok] audit log: $statusPath"

# PREFLIGHT
Stage "preflight"; Set-Location $Repo
& gh auth switch --user $Account 2>$null | Out-Null
$ghUser = ((& gh api user --jq .login 2>$null)|Out-String).Trim(); $status.preflight.ghUser=$ghUser
if($ghUser -ne $Account){ Die 2 "gh account '$ghUser' != '$Account'" }
$remote = ((& git remote get-url origin 2>$null)|Out-String).Trim()
if($remote -notmatch "cion-all-sites"){ Die 2 "bad remote $remote" }
& git checkout main 2>$null | Out-Null; & git pull origin main 2>$null | Out-Null
if(((& git status --porcelain 2>$null)|Out-String).Trim()){ Die 2 "tree not clean" }
if(-not $domain){ Die 2 "unknown site $Site" }
$status.preflight.clean=$true; Save-Status; Write-Host "[ok] preflight (account=$ghUser)"

# ENGINE
Stage "engine"; if(-not (Get-Command claude -ErrorAction SilentlyContinue)){ Die 3 "no claude CLI" }

# DRAFT BRANCH (never main)
Stage "branch"; & git checkout -B $branch main 2>$null | Out-Null

# SNAPSHOT existing slugs (script owns the contract)
$before = Get-ChildItem (Join-Path $Repo $Site) -Filter *.html -File | Select-Object -Expand Name
$existing = ($before | ForEach-Object { $_ -replace '\.html$','' }) -join ', '
$tmpl = (Get-ChildItem (Join-Path $Repo $Site) -Filter *.html -File | Where-Object { $_.Name -notin @('index.html','about.html','thank-you.html','privacy.html') } | Select-Object -First 1).Name

# GENERATE (model writes prose within a fixed path; scoped tools)
Stage "generate"
$genPrompt = @"
Generate ONE new bilingual (English+Telugu) SEO page for $Site (domain $domain) in the CION network; working dir is the repo root.
Pick the next high-value, lane-appropriate topic for this doctor that is NOT already covered. Existing slugs (DO NOT duplicate): $existing.
READ and obey: seo-engine/content-engine/config/02-content-rules.md, 03-voice-and-safety.md, 05-patient-question-framework.md, 07-technical-seo-and-entity.md. Match the chrome of the template $Site/$tmpl exactly.
ENGLISH-PRIMARY: <html lang="en">, English <title> <=60, English meta description <=155, og:locale en_IN + og:locale:alternate te_IN, self-canonical, NO hreflang, JSON-LD MedicalWebPage+FAQPage+BreadcrumbList with inLanguage ["en","te"]. Paired <span class="te-content">..</span><span class="en-content">..</span>; for in-context links keep the whole Telugu sentence in ONE te-content span and the whole English in ONE en-content span. Include a direct-answer box, bilingual FAQ, doctor card + CTA, 4-6 internal links, disclaimer. Conservative: no fabricated stats/survival/prices (cost = drivers + estimate CTA), no superlatives/testimonials/cure. Clean native Telugu only. UTF-8 no BOM.
Write the page to EXACTLY one new file $Site/<slug>.html (slug = kebab-case of the topic) and write ONLY that file. Then reply: SLUG=<slug>
"@
$genOut = ( & claude -p $genPrompt --allowedTools "Read" "Write" "WebSearch" "Glob" "Grep" 2>$null | Out-String )
$status.result.genTail = (($genOut.Trim() -split "`n") | Select-Object -Last 1); Save-Status

# ENFORCE CONTRACT
$after = Get-ChildItem (Join-Path $Repo $Site) -Filter *.html -File | Select-Object -Expand Name
$new = @($after | Where-Object { $_ -notin $before })
if($new.Count -ne 1){ Die 4 ("expected exactly 1 new page, got "+$new.Count) }
$fileName = $new[0]; $slug = $fileName -replace '\.html$',''
$status.result.page = "$Site/$fileName"; $status.result.slug = $slug; Save-Status
Write-Host "[ok] generated $Site/$fileName"

# TELUGU REVIEW (independent, scoped tools)
Stage "telugu-review"
$revPrompt = "STRICT native Telugu medical reviewer. Review ONLY the Telugu in $Site/$fileName (paired te-content/en-content spans). Check meaning fidelity, natural fluency, no gratuitous code-mixing, terminology, encoding (no stray Devanagari/Tamil/Malayalam/Kannada), medico-legal (no cure/guarantee/superlative via Telugu). FIX in place with Edit/Write; keep English siblings, structure, and te/en span balance unchanged. Reply: TELUGU=PASS or TELUGU=FIXED."
$revOut = ( & claude -p $revPrompt --allowedTools "Read" "Edit" "Write" 2>$null | Out-String )
$status.result.teluguTail = (($revOut.Trim() -split "`n") | Select-Object -Last 1); Save-Status

# VALIDATE (script owns; external py keeps this script ASCII-only)
Stage "validate"
$url = "https://$domain/$fileName"
$val = ( & python (Join-Path $Repo "scripts\validate-page.py") (Join-Path $Repo "$Site\$fileName") 2>&1 | Out-String ).Trim()
$status.result.validate = $val; Save-Status
if($val -notmatch 'VALIDATE:OK'){ Die 4 "validation failed: $val" }

# QA gate
Stage "qa"
$qa = ( & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $Repo "qa\Check-Network.ps1") 2>&1 | Out-String )
$p0 = [regex]::Match($qa,'P0 \(blocking\):\s*(\d+)').Groups[1].Value
$status.result.qaP0 = $p0; Save-Status
if($p0 -ne '0'){ Die 4 "QA P0=$p0" }

# SITEMAP + COMMIT to draft branch (never main)
Stage "commit"
$sm = "$Repo\$Site\sitemap.xml"; $smc = Get-Content $sm -Raw
if($smc -notmatch [regex]::Escape($url)){
  $entry = if($smc -match '<priority>'){ "  <url><loc>$url</loc><changefreq>monthly</changefreq><priority>0.7</priority></url>`n" } else { "  <url><loc>$url</loc><lastmod>$utcDate</lastmod></url>`n" }
  $smc = $smc -replace '</urlset>', ($entry + '</urlset>')
  [System.IO.File]::WriteAllText($sm, $smc, (New-Object System.Text.UTF8Encoding($false)))
}
& git add "$Site/$fileName" $sm 2>$null | Out-Null
& git -c user.name="CION Nightly Runner" -c user.email="cioncancerdoctors@gmail.com" commit -q -m "nightly draft: $Site/$slug (auto-generated, gated, NOT live)" 2>$null | Out-Null
& git push -u origin $branch 2>$null | Out-Null
$status.result.commit = ((& git rev-parse HEAD 2>$null)|Out-String).Trim()
$status.result.url = $url; $status.ok = $true; Stage "done"
Write-Host "[DONE] $Site/$fileName committed to $branch. Draft only, not live."
exit 0

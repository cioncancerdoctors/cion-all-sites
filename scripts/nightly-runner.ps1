<#
  CION nightly page runner (deterministic, headless) — THIN PROOF v0.1
  ------------------------------------------------------------------------
  Purpose: replace the fragile Claude-desktop scheduled task with a script the
  OS Task Scheduler runs directly (no desktop app), per GPT's recommendation.
  The SCRIPT owns: audit log, preflight, validation, QA, commit, exit codes.
  The MODEL is called only for the bounded generate + review steps.

  This v0.1 proves the non-interactive machinery end-to-end (audit log ->
  preflight -> [model gen stage] -> validate -> draft-branch commit). The model
  step is pluggable; the headless model ENGINE is not yet configured on this box
  (no `claude` CLI, no ANTHROPIC_API_KEY) so it stops cleanly at that gate and
  records the exact blocker. Safe by default: commits to a DRAFT branch, never
  pushes to main, never deploys.

  Usage:  powershell -NoProfile -ExecutionPolicy Bypass -File scripts\nightly-runner.ps1
  Exit codes: 0 ok | 2 preflight fail | 3 model-engine missing | 4 validate/QA fail
#>
param(
  [string]$Repo = "D:\Cowork\Website\cion-all-sites",
  [string]$Account = "cioncancerdoctors",
  [switch]$Publish = $false   # default OFF: commit to a draft branch, never main
)

# Native CLIs (gh/git) write benign messages to stderr; with -Stop that aborts.
# Use Continue and rely on explicit value/exit-code checks below.
$ErrorActionPreference = "Continue"
$utcDate = (Get-Date).ToUniversalTime().ToString("yyyy-MM-dd")
$runDir  = Join-Path $Repo "automation-runs\$utcDate"
$statusPath = Join-Path $runDir "status.json"
$status = [ordered]@{ started = (Get-Date).ToUniversalTime().ToString("o"); stage = "init"; ok = $false; preflight = @{}; sites = @{}; errors = @() }

function Save-Status {
  $json = $script:status | ConvertTo-Json -Depth 8
  [System.IO.File]::WriteAllText($statusPath, $json, (New-Object System.Text.UTF8Encoding($false)))
}
function Set-Stage([string]$s) { $script:status.stage = $s; Save-Status; Write-Host "[stage] $s" }
function Fail([int]$code, [string]$msg) { $script:status.errors += $msg; $script:status.ok = $false; Save-Status; Write-Host "FAIL($code): $msg"; exit $code }

# --- STEP 0: AUDIT LOG FIRST (the diagnostic canary) ---
New-Item -ItemType Directory -Force -Path $runDir | Out-Null
Save-Status
Write-Host "[ok] audit log written: $statusPath"

# --- PREFLIGHT ---
Set-Stage "preflight"
Set-Location $Repo
$status.preflight.cwd = (Get-Location).Path

# gh account (it silently flips; force the right one). Discard stderr only.
& gh auth switch --user $Account 2>$null | Out-Null
$ghUser = ((& gh api user --jq .login 2>$null) | Out-String).Trim()
$status.preflight.ghUser = "$ghUser"
if ("$ghUser" -ne $Account) { Fail 2 "gh active account is '$ghUser', expected '$Account'" }

$branch = ((& git rev-parse --abbrev-ref HEAD 2>$null) | Out-String).Trim()
$status.preflight.branch = $branch
$remote = ((& git remote get-url origin 2>$null) | Out-String).Trim()
$status.preflight.remote = $remote
if ($remote -notmatch "cion-all-sites") { Fail 2 "unexpected remote: $remote" }

& git pull origin main 2>$null | Out-Null
$dirty = ((& git status --porcelain 2>$null) | Out-String).Trim()
if ($dirty) { Fail 2 "working tree not clean before run" }
$status.preflight.clean = $true
Save-Status
Write-Host "[ok] preflight passed (account=$ghUser branch=$branch)"

# --- MODEL ENGINE DETECTION (the one missing piece) ---
Set-Stage "model-engine-check"
$engine = $null
if (Get-Command claude -ErrorAction SilentlyContinue) { $engine = "claude-cli" }
elseif ($env:ANTHROPIC_API_KEY)                        { $engine = "anthropic-api" }
$status.preflight.modelEngine = if ($engine) { $engine } else { "NONE" }
Save-Status
if (-not $engine) {
  Fail 3 "No headless Claude engine on this box (no 'claude' CLI, no ANTHROPIC_API_KEY). Machinery OK up to here; configure an engine to enable generation."
}

# --- (FUTURE) per-site: model generate -> Telugu review -> validate -> QA -> draft-branch commit ---
# Intentionally not implemented until the engine choice is made.
Set-Stage "generate"
Fail 3 "generation step not yet wired (pending model-engine decision)"

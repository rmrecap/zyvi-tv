<#
.SYNOPSIS
  Zyvi TV — Admin Dashboard Deployment Script (PowerShell)
.DESCRIPTION
  Deploys admin/ to Firebase Hosting (zyvi-tv project)
  Usage:  .\deploy_steps.ps1
#>

Write-Host "==============================" -ForegroundColor Magenta
Write-Host " Zyvi TV — Admin Deploy" -ForegroundColor Magenta
Write-Host "==============================" -ForegroundColor Magenta

# ── 1. Ensure firebase-tools is installed ──────────────────
$haveFirebase = Get-Command firebase -ErrorAction SilentlyContinue
if (-not $haveFirebase) {
  Write-Host "[1/5] Installing firebase-tools..." -ForegroundColor Yellow
  npm install -g firebase-tools
} else {
  Write-Host "[1/5] firebase-tools already installed." -ForegroundColor Green
}

# ── 2. Authenticate ───────────────────────────────────────
Write-Host "[2/5] Logging into Firebase..." -ForegroundColor Yellow
firebase login --no-localhost

# ── 3. Navigate to admin directory ────────────────────────
Write-Host "[3/5] Preparing admin/ directory..." -ForegroundColor Yellow
Push-Location (Join-Path $PSScriptRoot "admin")

if (-not (Test-Path "firebase.json")) {
  Write-Host "Initializing Firebase Hosting..." -ForegroundColor Yellow
  "y", ".", "N", "" | firebase init hosting --project zyvi-tv
}

# ── 4. Deploy only hosting ────────────────────────────────
Write-Host "[4/5] Deploying admin panel to Firebase Hosting..." -ForegroundColor Yellow
firebase deploy --only hosting

Pop-Location

# ── 5. Print the live URL ─────────────────────────────────
Write-Host ""
Write-Host "==============================" -ForegroundColor Green
Write-Host " Deployment complete!" -ForegroundColor Green
Write-Host "" -ForegroundColor Green
Write-Host " Live URL:" -ForegroundColor Cyan
Write-Host "   https://zyvi-tv.web.app" -ForegroundColor White
Write-Host "   https://zyvi-tv.firebaseapp.com" -ForegroundColor White
Write-Host "==============================" -ForegroundColor Green

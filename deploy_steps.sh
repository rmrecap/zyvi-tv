#!/usr/bin/env bash
# ============================================================
#  Zyvi TV — Admin Dashboard Deployment Script
#  Deploys admin/ to Firebase Hosting (zyvi-tv project)
#  Usage:  bash deploy_steps.sh
# ============================================================

set -euo pipefail

echo "=============================="
echo " Zyvi TV — Admin Deploy"
echo "=============================="

# ── 1. Ensure firebase-tools is installed ──────────────────
if ! command -v firebase &>/dev/null; then
  echo "[1/5] Installing firebase-tools..."
  npm install -g firebase-tools
else
  echo "[1/5] firebase-tools already installed."
fi

# ── 2. Authenticate ───────────────────────────────────────
echo "[2/5] Logging into Firebase..."
firebase login --no-localhost

# ── 3. Navigate to admin directory & init hosting ─────────
echo "[3/5] Initializing Firebase Hosting in admin/..."
cd "$(dirname "$0")/admin"

# firebase.json and .firebaserc are already provided,
# but if they are missing, regenerate them:
if [ ! -f "firebase.json" ]; then
  firebase init hosting --project zyvi-tv <<< $'.\nN\n'
fi

# ── 4. Deploy only hosting ────────────────────────────────
echo "[4/5] Deploying admin panel to Firebase Hosting..."
firebase deploy --only hosting

# ── 5. Print the live URL ─────────────────────────────────
echo ""
echo "=============================="
echo " Deployment complete!"
echo ""
echo " Live URL:"
echo "   https://zyvi-tv.web.app"
echo "   https://zyvi-tv.firebaseapp.com"
echo "=============================="

#!/usr/bin/env bash
# Sync latest source from /mnt/c into the Linux working copy, then build the
# frontend and compile the Rust backend to verify everything.
set -euo pipefail

SRC=/mnt/c/sources/doom-forge
DST=~/doom-forge
DST_EVAL=$(eval echo "$DST")

echo ">>> Syncing source -> $DST_EVAL…"
rsync -a --delete \
  --exclude node_modules \
  --exclude target \
  --exclude dist \
  --exclude .git \
  --exclude src-tauri/icons \
  --exclude src-tauri/gen \
  "$SRC"/ "$DST_EVAL"/
cd "$DST_EVAL"

echo ">>> Ensuring deps are installed…"
npm install --no-audit --no-fund

if [ ! -f src-tauri/icons/32x32.png ]; then
  echo ">>> Generating Tauri icons…"
  npx --yes @tauri-apps/cli icon app-icon.png
fi

echo ">>> Building frontend (tsc + vite)…"
npm run build

echo ">>> Compiling Rust backend (cargo build)…"
cd src-tauri
cargo build --color never 2>&1
echo ">>> BUILD OK"

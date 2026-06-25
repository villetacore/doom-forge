#!/usr/bin/env bash
# Prepare the project to build/run under WSL by mirroring it into the Linux
# filesystem (~/doom-forge). Building on /mnt/c (9p) is slow and corrupts
# native npm packages, so we work in ext4 and treat /mnt/c as the source.
set -euo pipefail

SRC=/mnt/c/sources/doom-forge
DST=~/doom-forge
DST_EVAL=$(eval echo "$DST")

echo ">>> Mirroring source -> $DST_EVAL (excluding build artifacts)…"
mkdir -p "$DST_EVAL"
rsync -a --delete \
  --exclude node_modules \
  --exclude target \
  --exclude dist \
  --exclude .git \
  "$SRC"/ "$DST_EVAL"/

cd "$DST_EVAL"

echo ">>> Installing dependencies (Linux)…"
npm install

echo ">>> Generating Tauri icons from app-icon.png…"
npx --yes @tauri-apps/cli icon app-icon.png

echo ">>> Done. Project ready at $DST_EVAL"
ls -1 src-tauri/icons

#!/usr/bin/env bash
# Launch DoomForge in dev mode under WSLg (GUI window on the Windows desktop).
# Syncs the latest source from /mnt/c into the Linux working copy first.
set -euo pipefail

SRC=/mnt/c/sources/doom-forge
DST=~/doom-forge
DST_EVAL=$(eval echo "$DST")
rsync -a --delete \
  --exclude node_modules --exclude target --exclude dist --exclude .git \
  --exclude src-tauri/icons --exclude src-tauri/gen \
  "$SRC"/ "$DST_EVAL"/
cd "$DST_EVAL"

# WebKitGTK renders a blank window under WSLg/VMs without this.
export WEBKIT_DISABLE_DMABUF_RENDERER=1
export WEBKIT_DISABLE_COMPOSITING_MODE=1

exec npm run app:dev

#!/usr/bin/env bash
set -u
UA="DoomForge/0.1"

echo "=== idgames API (search 'eviternity') ==="
curl -s -A "$UA" "https://www.doomworld.com/idgames/api/api.php?out=json&action=search&type=title&query=eviternity" \
  | head -c 600
echo; echo

echo "=== Freedoom latest assets ==="
curl -s -A "$UA" -H "Accept: application/vnd.github+json" \
  "https://api.github.com/repos/freedoom/freedoom/releases/latest" \
  | grep -oE '"name": *"[^"]*\.zip"' | head
echo

echo "=== GZDoom latest assets ==="
curl -s -A "$UA" -H "Accept: application/vnd.github+json" \
  "https://api.github.com/repos/ZDoom/gzdoom/releases/latest" \
  | grep -oE '"name": *"[^"]*"' | head -20

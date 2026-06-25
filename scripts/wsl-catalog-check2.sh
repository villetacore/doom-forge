#!/usr/bin/env bash
UA="DoomForge/0.1"
for repo in \
  "mmaulwurff/target-spy" \
  "mmaulwurff/gearbox" \
  "mmaulwurff/precise-crosshair" \
  "AL-97/Combined_Arms" \
  "Sumwunn/GMOTA" \
  "MFG38/Babel" \
  "Marisa-the-Magician/Cutman" \
  "jjxtra/..." ; do
  echo "=== $repo ==="
  curl -s -A "$UA" -H "Accept: application/vnd.github+json" \
    "https://api.github.com/repos/$repo/releases/latest" \
    | grep -oE '"name": *"[^"]*"' | grep -iE '\.(pk3|wad|zip|pk7)"' | head -3
done

#!/usr/bin/env bash
UA="DoomForge/0.1"
for repo in \
  "jekyllgrim/Beautiful-Doom" \
  "Realm667/WolfenDoom-Blade-of-Agony" \
  "Talon1024/QuakeStyleConsole" \
  "mc776/SmoothDoom" \
  "biospud/Doomsday-Engine" \
  "freedoom/freedoom" ; do
  echo "=== $repo ==="
  curl -s -A "$UA" -H "Accept: application/vnd.github+json" \
    "https://api.github.com/repos/$repo/releases/latest" \
    | grep -oE '"name": *"[^"]*"' | grep -iE '\.(pk3|wad|zip|pk7)"' | head -4
done

#!/usr/bin/env bash
set -u
for b in gzdoom lzdoom zandronum vkdoom; do
  p="$(command -v "$b" 2>/dev/null)"
  if [ -n "$p" ]; then echo "$b: $p"; else echo "$b: not found"; fi
done
echo "--- apt candidate for gzdoom ---"
apt-cache policy gzdoom 2>/dev/null | sed -n '1,4p'
echo "--- flatpak ---"
if command -v flatpak >/dev/null 2>&1; then echo "flatpak: yes"; else echo "flatpak: no"; fi

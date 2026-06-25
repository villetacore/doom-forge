#!/usr/bin/env bash
set -u

echo "=== sudo ==="
if sudo -n true 2>/dev/null; then
  echo "sudo: passwordless OK"
else
  echo "sudo: NEEDS PASSWORD"
fi

echo "=== webkit2gtk-4.1 ==="
if pkg-config --exists webkit2gtk-4.1 2>/dev/null; then
  echo "webkit2gtk-4.1: present"
else
  echo "webkit2gtk-4.1: MISSING"
fi

echo "=== other tauri deps ==="
for p in libgtk-3-dev librsvg2-dev libssl-dev libayatana-appindicator3-dev; do
  if dpkg -s "$p" >/dev/null 2>&1; then echo "$p: present"; else echo "$p: MISSING"; fi
done

echo "=== ImageMagick (for icon) ==="
command -v convert || echo "convert: none"

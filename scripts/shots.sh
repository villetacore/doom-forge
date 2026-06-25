#!/usr/bin/env bash
# Capture README screenshots from the running Vite dev server using headless Edge.
# Usage: bash scripts/shots.sh   (dev server must be running on :1420)
set -u

EDGE="/c/Program Files (x86)/Microsoft/Edge/Application/msedge.exe"
OUT_WIN="C:/sources/doom-forge/docs/img"
PROFILE="C:/Users/alex_pyslar/AppData/Local/Temp/df-edge"
BASE="http://localhost:1420"
mkdir -p docs/img

# Write a throwaway seed page (served by Vite from public/) that persists the
# requested theme/palette/lang, then remove it again on exit so it never ships.
SEED="public/seed.html"
cat > "$SEED" <<'HTML'
<!doctype html><meta charset="utf-8"><body><script>
const p = new URLSearchParams(location.search);
const cur = JSON.parse(localStorage.getItem("doomforge.settings") || "{}");
localStorage.setItem("doomforge.settings", JSON.stringify({
  ...cur, themeMode: p.get("theme")||"dark", palette: p.get("palette")||"ember", lang: p.get("lang")||"en",
}));
document.body.textContent = "seeded";
</script></body>
HTML
trap 'rm -f "$SEED"' EXIT
sleep 1

shot() {
  local section="$1" theme="$2" palette="$3" file="$4"
  rm -rf "$PROFILE"
  # 1) seed persisted settings (theme/palette/lang) into this Edge profile
  "$EDGE" --headless=new --disable-gpu --no-first-run --no-default-browser-check \
    --user-data-dir="$PROFILE" --virtual-time-budget=4000 \
    --screenshot="C:/Users/alex_pyslar/AppData/Local/Temp/df-seed.png" \
    "$BASE/seed.html?theme=$theme&palette=$palette&lang=en" >/dev/null 2>&1
  # 2) screenshot the requested view (deep-linked via the hash)
  "$EDGE" --headless=new --disable-gpu --no-first-run --no-default-browser-check \
    --hide-scrollbars --force-device-scale-factor=1.5 --window-size=1280,800 \
    --run-all-compositor-stages-before-draw --virtual-time-budget=9000 \
    --user-data-dir="$PROFILE" \
    --screenshot="$OUT_WIN/$file" \
    "$BASE/#$section" >/dev/null 2>&1
  echo "  $file -> $(ls -la docs/img/$file 2>/dev/null | awk '{print $5}') bytes"
}

echo "Capturing screenshots..."
shot build    dark  ember  build.png
shot library  dark  blood  library.png
shot settings dark  ember  settings.png
shot settings light toxic  settings-light.png
shot crash    amoled plasma crash.png
echo "Done."

# Launch DoomForge in dev mode natively on Windows (Tauri dev window).
$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

$env:Path = "$env:USERPROFILE\.cargo\bin;$env:Path"

if (-not (Test-Path "$root\node_modules")) { npm install }
if (-not (Test-Path "$root\src-tauri\icons\32x32.png")) {
  npx --yes @tauri-apps/cli icon app-icon.png
}

npm run app:dev

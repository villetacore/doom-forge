# Build DoomForge natively on Windows (frontend + Rust backend).
# Requires: Node.js, Rust (rustup, msvc), VS C++ build tools, WebView2 runtime.
$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

# Ensure cargo is on PATH even in a fresh shell.
$env:Path = "$env:USERPROFILE\.cargo\bin;$env:Path"

if (-not (Test-Path "$root\node_modules")) {
  Write-Host ">>> npm install"
  npm install
}

if (-not (Test-Path "$root\src-tauri\icons\32x32.png")) {
  Write-Host ">>> generating icons"
  npx --yes @tauri-apps/cli icon app-icon.png
}

Write-Host ">>> building frontend"
npm run build

Write-Host ">>> cargo build (backend)"
Set-Location "$root\src-tauri"
cargo build
Write-Host ">>> BUILD OK"

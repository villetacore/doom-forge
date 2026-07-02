# DoomForge

A modern desktop **launcher and mod manager for GZDoom** — built with
**Flutter** (UI) and **Rust** (core logic), bridged by
[flutter_rust_bridge](https://github.com/fzyzcjy/flutter_rust_bridge).

- Assemble mod loadouts, order them, and launch GZDoom.
- Scan a mods folder, detect engines & IWADs, resolve conflicts, diagnose crashes.
- 3 themes × 10 accent palettes, 11 UI languages, no emoji — original Doom-style art.

## Project layout

```
doom-forge/
├── lib/                 Flutter app (Dart)
│   ├── main.dart          entry: inits the Rust bridge + app data dir
│   ├── app.dart           MaterialApp + theme wiring
│   ├── app_state.dart     state (provider) + settings persistence
│   ├── shell.dart         sidebar / topbar / status bar
│   ├── theme/             3 modes × 10 palettes
│   ├── i18n/              11 language dictionaries
│   ├── widgets/           Doom art (skull/hero painters) + reusable controls
│   ├── views/             build · library · browse · compare · crash · status · settings
│   └── src/rust/          generated FRB bindings (do not edit by hand)
├── rust/                 Rust core (the launcher's brains)
│   ├── src/domain/         scan, engine, iwad, load order, profiles, launch, conflicts …
│   ├── src/services/       downloads (Freedoom/GZDoom/idgames) + Claude AI
│   └── src/api/            the flutter_rust_bridge API surface
├── rust_builder/         cargokit glue that builds `rust/` for each platform
├── windows/ linux/ macos/  Flutter desktop runners
└── pubspec.yaml
```

Nothing else — no Node, no web/mobile targets, no Tauri.

## Prerequisites

- **[Flutter SDK](https://docs.flutter.dev/get-started/install)** (stable, 3.4+) — includes Dart.
- **[Rust](https://rustup.rs)** (stable toolchain).
- **Windows:** Visual Studio 2022+ with the **“Desktop development with C++”** workload,
  and **Developer Mode enabled** (Settings → *For developers*, or run `start ms-settings:developers`).
  Developer Mode is required so Flutter can create the plugin symlinks.
- **Linux:** `clang cmake ninja-build pkg-config libgtk-3-dev liblzma-dev` (+ `unzip`).

## Run it

```powershell
# 1. (Windows, one time) enable Developer Mode
start ms-settings:developers      # toggle "Developer Mode" ON

# 2. fetch Dart packages
flutter pub get

# 3. run the desktop app (debug)
flutter run -d windows            # or: -d linux / -d macos
```

That’s it — `flutter run` compiles the Rust crate automatically (via cargokit) and
launches the app.

### Build a release

```powershell
flutter build windows             # or: linux / macos
# output: build/windows/x64/runner/Release/
```

### Regenerating the Rust↔Dart bridge

Only needed if you change the Rust API in `rust/src/api/`:

```powershell
cargo install flutter_rust_bridge_codegen   # once
flutter_rust_bridge_codegen generate
```

## License

[MIT](LICENSE) © DoomForge contributors.

<sub>Unofficial fan-made tool, not affiliated with id Software or ZeniMax. All artwork is original.</sub>

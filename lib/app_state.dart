import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'theme/theme.dart';
import 'src/rust/domain/models.dart';
import 'src/rust/api/doomforge.dart' as rust;

const _kSettings = 'doomforge.settings';

/// Global app state: persisted settings plus the live data loaded from Rust.
class AppState extends ChangeNotifier {
  // ---- settings (persisted) ----
  String modsDir = '';
  String engineDir = '';
  List<String> iwadDirs = [];
  String registry = '';
  String aiKey = '';
  String aiModel = 'claude-opus-4-8';
  String lang = 'en';
  DfMode mode = DfMode.dark;
  String palette = 'ember';

  // ---- live data ----
  List<ModFile> mods = [];
  List<Engine> engines = [];
  List<Iwad> iwads = [];
  List<Profile> profiles = [];
  String? activeProfileId;

  String? toast;

  DfColors get colors => DfColors.resolve(mode, palette);
  Profile? get activeProfile {
    for (final p in profiles) {
      if (p.id == activeProfileId) return p;
    }
    return null;
  }

  int get iwadsPresent => iwads.where((i) => i.present).length;
  bool get ready => engines.isNotEmpty && iwadsPresent > 0;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kSettings);
    if (raw != null) {
      try {
        final m = jsonDecode(raw) as Map<String, dynamic>;
        modsDir = m['modsDir'] ?? modsDir;
        engineDir = m['engineDir'] ?? engineDir;
        iwadDirs = (m['iwadDirs'] as List?)?.cast<String>() ?? iwadDirs;
        registry = m['registry'] ?? registry;
        aiKey = m['aiKey'] ?? aiKey;
        aiModel = m['aiModel'] ?? aiModel;
        lang = m['lang'] ?? lang;
        mode = DfMode.values.firstWhere((e) => e.name == m['mode'],
            orElse: () => DfMode.dark);
        palette = m['palette'] ?? palette;
      } catch (_) {/* ignore corrupt settings */}
    }
    // Initial probe of configured folders + saved builds.
    await refreshProfiles();
    await refreshEnginesAndIwads();
    if (modsDir.isNotEmpty) await rescanMods();
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _kSettings,
      jsonEncode({
        'modsDir': modsDir,
        'engineDir': engineDir,
        'iwadDirs': iwadDirs,
        'registry': registry,
        'aiKey': aiKey,
        'aiModel': aiModel,
        'lang': lang,
        'mode': mode.name,
        'palette': palette,
      }),
    );
  }

  void updateSettings(VoidCallback apply) {
    apply();
    _persist();
    notifyListeners();
  }

  void showToast(String msg) {
    toast = msg;
    notifyListeners();
    Future.delayed(const Duration(seconds: 4), () {
      toast = null;
      notifyListeners();
    });
  }

  // ---- data refreshers ----
  Future<void> refreshProfiles() async {
    try {
      profiles = await rust.listProfiles();
    } catch (_) {}
  }

  Future<void> refreshEnginesAndIwads() async {
    try {
      if (engineDir.isNotEmpty) engines = await rust.scanEngines(dir: engineDir);
    } catch (_) {}
    try {
      final dirs = iwadDirs.where((d) => d.isNotEmpty).toList();
      if (dirs.isNotEmpty) iwads = await rust.checkIwads(dirs: dirs);
    } catch (_) {}
  }

  Future<void> rescanMods() async {
    if (modsDir.isEmpty) return;
    try {
      mods = await rust.scanMods(dir: modsDir, withHashes: true);
    } catch (e) {
      showToast('$e');
    }
  }

  Future<void> rescanAll() async {
    await rescanMods();
    await refreshEnginesAndIwads();
    notifyListeners();
    showToast('OK');
  }

  void setEngines(List<Engine> e) {
    engines = e;
    notifyListeners();
  }

  void setIwads(List<Iwad> i) {
    iwads = i;
    notifyListeners();
  }

  void setMods(List<ModFile> m) {
    mods = m;
    notifyListeners();
  }

  void setProfiles(List<Profile> p) {
    profiles = p;
    notifyListeners();
  }

  void setActive(String? id) {
    activeProfileId = id;
    notifyListeners();
  }

  /// Replace one profile in the list (after an edit/save).
  void upsertProfile(Profile p) {
    final idx = profiles.indexWhere((x) => x.id == p.id);
    if (idx >= 0) {
      profiles[idx] = p;
    } else {
      profiles.insert(0, p);
    }
    notifyListeners();
  }
}

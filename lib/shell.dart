import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'app_state.dart';
import 'i18n/i18n.dart';
import 'theme/theme.dart';
import 'widgets/art.dart';
import 'widgets/common.dart';
import 'src/rust/api/doomforge.dart' as rust;
import 'src/rust/domain/models.dart';
import 'views/build_view.dart';
import 'views/library_view.dart';
import 'views/browse_view.dart';
import 'views/compare_view.dart';
import 'views/crash_view.dart';
import 'views/status_view.dart';
import 'views/settings_view.dart';

const _nav = <(Section, IconData)>[
  (Section.build, Icons.handyman_outlined),
  (Section.library, Icons.grid_view_outlined),
  (Section.browse, Icons.download_outlined),
  (Section.compare, Icons.compare_arrows_outlined),
  (Section.crash, Icons.monitor_heart_outlined),
  (Section.status, Icons.dns_outlined),
  (Section.settings, Icons.settings_outlined),
];

const _subKeys = {
  Section.build: 'sub.build',
  Section.library: 'sub.library',
  Section.browse: 'sub.browse',
  Section.compare: 'sub.compare',
  Section.crash: 'sub.crash',
  Section.status: 'sub.status',
  Section.settings: 'sub.settings',
};

class Shell extends StatefulWidget {
  const Shell({super.key});
  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  Section _section = Section.build;
  void go(Section s) => setState(() => _section = s);

  Widget _view() {
    switch (_section) {
      case Section.build:
        return const BuildView();
      case Section.library:
        return const LibraryView();
      case Section.browse:
        return const BrowseView();
      case Section.compare:
        return const CompareView();
      case Section.crash:
        return const CrashView();
      case Section.status:
        return const StatusView();
      case Section.settings:
        return const SettingsView();
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final c = s.colors;
    return Scaffold(
      backgroundColor: c.bg,
      body: Stack(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Sidebar(section: _section, onGo: go),
              Expanded(
                child: Column(
                  children: [
                    _TopBar(section: _section),
                    Expanded(
                      child: Container(
                        color: c.bg,
                        padding: const EdgeInsets.all(22),
                        child: _view(),
                      ),
                    ),
                    _StatusBar(),
                  ],
                ),
              ),
            ],
          ),
          if (s.toast != null)
            Positioned(
              bottom: 44,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                  decoration: BoxDecoration(
                    color: c.surface2,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: c.accentLine),
                    boxShadow: [BoxShadow(color: c.shadow, blurRadius: 28, offset: const Offset(0, 8))],
                  ),
                  child: Text(s.toast!, style: TextStyle(color: c.fg, fontSize: 13)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final Section section;
  const _TopBar({required this.section});
  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final c = s.colors;
    final icon = _nav.firstWhere((e) => e.$1 == section).$2;
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 14, 22, 14),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.line))),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: c.accentSoft,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: c.accentLine),
            ),
            child: Icon(icon, size: 22, color: c.accent2),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(tr(s.lang, 'nav.${section.name}'),
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: c.fg)),
              Text(tr(s.lang, _subKeys[section]!), style: TextStyle(fontSize: 12, color: c.muted)),
            ],
          ),
          const Spacer(),
          _stat(c, s.mods.length, tr(s.lang, 'sidebar.mods')),
          const SizedBox(width: 8),
          _stat(c, s.engines.length, tr(s.lang, 'sidebar.engines')),
          const SizedBox(width: 8),
          _stat(c, s.iwadsPresent, tr(s.lang, 'sidebar.iwads')),
        ],
      ),
    );
  }

  Widget _stat(DfColors c, int n, String label) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        constraints: const BoxConstraints(minWidth: 58),
        decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(6), border: Border.all(color: c.line)),
        child: Column(
          children: [
            Text('$n', style: TextStyle(fontSize: 15, fontFamily: 'monospace', color: n == 0 ? c.muted : c.accent2, height: 1)),
            Text(label.toUpperCase(), style: TextStyle(fontSize: 9, letterSpacing: 0.8, color: c.muted)),
          ],
        ),
      );
}

class _StatusBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final c = s.colors;
    Widget dot(bool ok, {bool off = false}) => Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.only(right: 6),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: ok ? c.ok : (off ? c.err : c.muted),
            boxShadow: ok ? [BoxShadow(color: c.ok.withValues(alpha: 0.6), blurRadius: 7)] : null,
          ),
        );
    Widget item(Widget d, String text) => Padding(
          padding: const EdgeInsets.only(right: 18),
          child: Row(mainAxisSize: MainAxisSize.min, children: [d, Text(text, style: TextStyle(fontSize: 11.5, color: c.muted))]),
        );
    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(color: c.bg2, border: Border(top: BorderSide(color: c.line))),
      child: Row(
        children: [
          item(dot(s.engines.isNotEmpty, off: s.engines.isEmpty), '${s.engines.length} ${tr(s.lang, 'sidebar.engines')}'),
          item(dot(s.iwadsPresent > 0, off: s.iwadsPresent == 0), '${s.iwadsPresent} ${tr(s.lang, 'sidebar.iwads')}'),
          item(dot(s.mods.isNotEmpty), '${s.mods.length} ${tr(s.lang, 'sidebar.mods')}'),
          item(dot(s.ready, off: !s.ready), tr(s.lang, s.ready ? 'status.ready' : 'status.notReady')),
          const Spacer(),
          Text('DoomForge v0.1.0', style: TextStyle(fontSize: 11, fontFamily: 'monospace', color: c.muted, letterSpacing: 0.5)),
        ],
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  final Section section;
  final void Function(Section) onGo;
  const _Sidebar({required this.section, required this.onGo});

  Future<void> _pickDir(BuildContext context, void Function(String) set) async {
    final dir = await FilePicker.platform.getDirectoryPath();
    if (dir != null) set(dir);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final c = s.colors;
    return Container(
      width: 270,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [c.bg2, c.bg], begin: Alignment.topCenter, end: Alignment.bottomCenter),
        border: Border(right: BorderSide(color: c.line)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // brand
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
              child: Row(
                children: [
                  BrandMark(size: 36, accent: c.accent, accent2: c.accent2, bg: c.bg),
                  const SizedBox(width: 11),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Text('DOOM', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700, letterSpacing: 3, color: c.fg)),
                        Text('FORGE', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700, letterSpacing: 3, color: c.accent2)),
                      ]),
                      const SizedBox(height: 4),
                      Text(tr(s.lang, 'brand.tagline'),
                          style: TextStyle(fontSize: 9.5, letterSpacing: 2.5, color: c.muted)),
                    ],
                  ),
                ],
              ),
            ),
            // nav
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Column(
                children: [
                  for (final (sec, icon) in _nav)
                    _NavItem(icon: icon, label: tr(s.lang, 'nav.${sec.name}'), active: sec == section, onTap: () => onGo(sec)),
                ],
              ),
            ),
            const SizedBox(height: 8),
            _buildsSection(context, s, c),
            _foldersSection(context, s, c),
          ],
        ),
      ),
    );
  }

  Widget _buildsSection(BuildContext context, AppState s, DfColors c) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(border: Border(top: BorderSide(color: c.line))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(tr(s.lang, 'sidebar.profiles').toUpperCase(),
                  style: TextStyle(fontSize: 11, letterSpacing: 1.2, color: c.muted)),
              const Spacer(),
              IconButton(
                icon: Icon(Icons.add, size: 16, color: c.muted),
                visualDensity: VisualDensity.compact,
                onPressed: () => _createBuild(context, s),
              ),
            ],
          ),
          if (s.profiles.isEmpty)
            Text(tr(s.lang, 'sidebar.noBuilds'), style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: c.muted)),
          for (final p in s.profiles)
            InkWell(
              onTap: () {
                s.setActive(p.id);
                onGo(Section.build);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                margin: const EdgeInsets.only(top: 3),
                decoration: BoxDecoration(
                  color: p.id == s.activeProfileId ? c.surface2 : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: p.id == s.activeProfileId ? c.accentLine : Colors.transparent),
                ),
                child: Row(
                  children: [
                    Expanded(child: Text(p.name, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, color: p.id == s.activeProfileId ? c.accent2 : c.fgDim))),
                    Text('${p.loadOrder.length}', style: TextStyle(fontSize: 11, fontFamily: 'monospace', color: c.muted)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _foldersSection(BuildContext context, AppState s, DfColors c) {
    Widget row(String label, String value, VoidCallback onPick) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Text(label, style: TextStyle(fontSize: 13, color: c.fg)),
              const Spacer(),
              TextButton(onPressed: onPick, child: Text(tr(s.lang, 'common.browse'), style: TextStyle(fontSize: 12, color: c.muted))),
            ]),
            Text(value.isEmpty ? tr(s.lang, 'common.notSet') : value,
                style: TextStyle(fontSize: 11, color: c.muted), maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
          ],
        );
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(border: Border(top: BorderSide(color: c.line))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(tr(s.lang, 'sidebar.paths').toUpperCase(), style: TextStyle(fontSize: 11, letterSpacing: 1.2, color: c.muted)),
          const SizedBox(height: 8),
          row(tr(s.lang, 'sidebar.mods'), s.modsDir, () => _pickDir(context, (d) => s.updateSettings(() => s.modsDir = d))),
          row(tr(s.lang, 'sidebar.engines'), s.engineDir, () => _pickDir(context, (d) {
                s.updateSettings(() => s.engineDir = d);
                s.refreshEnginesAndIwads();
              })),
          Row(children: [
            Text(tr(s.lang, 'sidebar.iwads'), style: TextStyle(fontSize: 13, color: c.fg)),
            const Spacer(),
            TextButton(
              onPressed: () => _pickDir(context, (d) {
                s.updateSettings(() => s.iwadDirs = [...s.iwadDirs, d]);
                s.refreshEnginesAndIwads();
              }),
              child: Text(tr(s.lang, 'sidebar.addDir'), style: TextStyle(fontSize: 12, color: c.muted)),
            ),
          ]),
          for (final d in s.iwadDirs)
            Text(d, style: TextStyle(fontSize: 11, color: c.muted), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 10),
          Row(children: [
            GhostButton(icon: Icons.refresh, label: tr(s.lang, 'sidebar.rescan'), onPressed: () => s.rescanAll()),
            const SizedBox(width: 8),
            GhostButton(icon: Icons.auto_awesome, label: tr(s.lang, 'sidebar.forge'), onPressed: () => _forge(context, s)),
          ]),
        ],
      ),
    );
  }

  Future<void> _createBuild(BuildContext context, AppState s) async {
    final now = DateTime.now().toUtc().toIso8601String();
    final p = Profile(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: tr(s.lang, 'sidebar.newBuild'),
      description: '',
      loadOrder: [],
      extraArgs: [],
      createdAt: now,
      updatedAt: now,
    );
    try {
      final saved = await rust.saveProfile(profile: p);
      s.upsertProfile(saved);
      s.setActive(saved.id);
      onGo(Section.build);
    } catch (e) {
      s.showToast('$e');
    }
  }

  Future<void> _forge(BuildContext context, AppState s) async {
    if (s.mods.isEmpty) return s.showToast(tr(s.lang, 'library.empty'));
    Iwad? iw;
    for (final i in s.iwads) {
      if (i.present) {
        iw = i;
        break;
      }
    }
    try {
      final p = await rust.forgeBuild(library_: s.mods, iwad: iw?.path ?? iw?.fileName);
      s.upsertProfile(p);
      s.setActive(p.id);
      onGo(Section.build);
    } catch (e) {
      s.showToast('$e');
    }
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _NavItem({required this.icon, required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.watch<AppState>().colors;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          gradient: active ? LinearGradient(colors: [c.accentSoft, Colors.transparent]) : null,
          border: Border(left: BorderSide(color: active ? c.accent : Colors.transparent, width: 2)),
          borderRadius: const BorderRadius.horizontal(right: Radius.circular(6)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: active ? c.accent2 : c.fgDim),
            const SizedBox(width: 11),
            Text(label, style: TextStyle(fontSize: 13.5, color: active ? c.accent2 : c.fgDim, fontWeight: active ? FontWeight.w600 : FontWeight.normal)),
          ],
        ),
      ),
    );
  }
}

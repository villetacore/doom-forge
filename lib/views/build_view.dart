import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../i18n/i18n.dart';
import '../rust_ext.dart';
import '../theme/theme.dart';
import '../widgets/common.dart';
import '../src/rust/api/doomforge.dart' as rust;
import '../src/rust/domain/models.dart';

const _modExts = ['pk3', 'pk7', 'wad', 'zip', 'pke', 'ipk3', 'deh', 'bex'];

Color groupColor(ModGroup g, DfColors c) {
  switch (g) {
    case ModGroup.maps:
      return const Color(0xFF6FB1FF);
    case ModGroup.gameplay:
      return c.accent2;
    case ModGroup.audio:
      return const Color(0xFFC08FFF);
    case ModGroup.visuals:
      return const Color(0xFF5FD0C0);
    case ModGroup.patch:
      return c.err;
    case ModGroup.other:
      return c.muted;
  }
}

class BuildView extends StatefulWidget {
  const BuildView({super.key});
  @override
  State<BuildView> createState() => _BuildViewState();
}

class _BuildViewState extends State<BuildView> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String? _boundId;
  String? _cmd;
  List<Recommendation>? _recs;

  void _bind(Profile p) {
    if (_boundId != p.id) {
      _boundId = p.id;
      _nameCtrl.text = p.name;
      _descCtrl.text = p.description;
    }
  }

  Future<void> _createBuild(AppState s) async {
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
    } catch (e) {
      s.showToast('$e');
    }
  }

  Future<void> _addFiles(AppState s, Profile p) async {
    final res = await FilePicker.platform.pickFiles(allowMultiple: true, type: FileType.custom, allowedExtensions: _modExts);
    if (res == null) return;
    final paths = res.paths.whereType<String>().toList();
    final described = await rust.describeFiles(paths: paths);
    final existing = p.loadOrder.map((e) => e.path).toSet();
    final added = [
      for (final m in described)
        if (!existing.contains(m.path)) LoadEntry(path: m.path, name: m.name, group: m.group, enabled: true),
    ];
    s.upsertProfile(p.copyWith(loadOrder: [...p.loadOrder, ...added]));
    s.showToast('+${added.length}');
  }

  Future<void> _launch(AppState s, Profile p, bool safe) async {
    final engine = p.enginePath ?? (s.engines.isNotEmpty ? s.engines.first.path : null);
    if (engine == null) return s.showToast(tr(s.lang, 'status.noEngines'));
    try {
      await rust.saveProfile(profile: p);
      final cmd = await rust.launchProfile(engine: engine, profile: p, safeMode: safe);
      setState(() => _cmd = cmd);
    } catch (e) {
      s.showToast('$e');
    }
  }

  Future<void> _autotest(AppState s, Profile p) async {
    final engine = p.enginePath ?? (s.engines.isNotEmpty ? s.engines.first.path : null);
    if (engine == null) return s.showToast(tr(s.lang, 'status.noEngines'));
    try {
      setState(() => _cmd = null);
      final cmd = await rust.dryRunProfile(engine: engine, profile: p);
      setState(() => _cmd = cmd);
      s.showToast('OK');
    } catch (e) {
      s.showToast('$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final c = s.colors;
    String t(String k) => tr(s.lang, k);
    final p = s.activeProfile;

    if (p == null) {
      return EmptyHero(
        art: 'helmet',
        title: t('build.emptyTitle'),
        hint: t('build.empty'),
        action: PrimaryButton(icon: Icons.add, label: t('build.emptyCta'), large: true, onPressed: () => _createBuild(s)),
      );
    }
    _bind(p);
    final engines = s.engines;
    final presentIwads = s.iwads.where((i) => i.present).toList();

    return ListView(
      children: [
        // header
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _nameCtrl,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: c.fg),
                decoration: const InputDecoration(border: InputBorder.none, isDense: true),
                onChanged: (v) => s.upsertProfile(p.copyWith(name: v)),
              ),
            ),
            GhostButton(icon: Icons.save, label: t('common.save'), onPressed: () async {
              await rust.saveProfile(profile: p);
              s.showToast('OK');
            }),
            const SizedBox(width: 8),
            GhostButton(icon: Icons.delete_outline, label: t('common.delete'), danger: true, onPressed: () async {
              await rust.deleteProfile(id: p.id);
              s.setProfiles(s.profiles.where((x) => x.id != p.id).toList());
              s.setActive(null);
            }),
          ],
        ),
        const SizedBox(height: 12),
        DfField(hint: t('build.description'), controller: _descCtrl, maxLines: 3, onChanged: (v) => s.upsertProfile(p.copyWith(description: v))),
        const SizedBox(height: 14),
        // engine + iwad
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: _labeledDropdown(c, t('build.engine'), p.enginePath ?? '', {
                '': '${t('build.auto')} (${engines.isNotEmpty ? engines.first.name : t('common.none')})',
                for (final e in engines) e.path: e.name + (e.version != null ? ' (${e.version})' : ''),
              }, (v) => s.upsertProfile(p.copyWith(enginePath: v.isEmpty ? null : v))),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _labeledDropdown(c, t('build.iwad'), p.iwad ?? '', {
                '': t('build.selectIwad'),
                for (final i in presentIwads) (i.path ?? i.fileName): i.title,
                if (p.iwad != null && !presentIwads.any((i) => (i.path ?? i.fileName) == p.iwad)) p.iwad!: p.iwad!,
              }, (v) => s.upsertProfile(p.copyWith(iwad: v.isEmpty ? null : v))),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _CompatBar(profile: p),
        const SizedBox(height: 16),
        // load order header
        Row(
          children: [
            Text('${t('build.loadOrder')}  ', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: c.fg)),
            Text('(${p.enabledCount}/${p.loadOrder.length} ${t('build.enabled')})', style: TextStyle(fontSize: 13, color: c.muted)),
            const Spacer(),
            GhostButton(icon: Icons.add, label: t('build.addFiles'), onPressed: () => _addFiles(s, p)),
            const SizedBox(width: 6),
            GhostButton(icon: Icons.sort, label: t('build.autosort'), onPressed: () async {
              final ordered = await rust.autoOrder(entries: p.loadOrder);
              s.upsertProfile(p.copyWith(loadOrder: ordered));
            }),
            const SizedBox(width: 6),
            GhostButton(icon: Icons.auto_awesome, label: t('build.recommend'), onPressed: () async {
              final r = await rust.recommendMods(library_: s.mods, profile: p, limit: 8);
              setState(() => _recs = r);
            }),
          ],
        ),
        const SizedBox(height: 8),
        if (_recs != null)
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              for (final r in _recs!)
                GhostButton(icon: Icons.add, label: r.name, onPressed: () {
                  if (p.loadOrder.any((e) => e.path == r.path)) return;
                  s.upsertProfile(p.copyWith(loadOrder: [...p.loadOrder, LoadEntry(path: r.path, name: r.name, group: r.group, enabled: true)]));
                  setState(() => _recs = _recs!.where((x) => x.path != r.path).toList());
                }),
            ],
          ),
        const SizedBox(height: 8),
        if (p.loadOrder.isEmpty)
          Text(t('build.loadOrderEmpty'), style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: c.muted))
        else
          ReorderableListView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            onReorder: (oldI, newI) {
              final list = [...p.loadOrder];
              if (newI > oldI) newI -= 1;
              final item = list.removeAt(oldI);
              list.insert(newI, item);
              s.upsertProfile(p.copyWith(loadOrder: list));
            },
            children: [
              for (int idx = 0; idx < p.loadOrder.length; idx++)
                _loRow(context, s, c, p, idx),
            ],
          ),
        const SizedBox(height: 14),
        // launch bar
        DfPanel(
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              PrimaryButton(icon: Icons.play_arrow, label: t('build.launch'), large: true, onPressed: () => _launch(s, p, false)),
              GhostButton(icon: Icons.shield_outlined, label: t('build.safeMode'), onPressed: () => _launch(s, p, true)),
              GhostButton(icon: Icons.check, label: t('build.autotest'), onPressed: () => _autotest(s, p)),
              GhostButton(icon: Icons.thumb_up_outlined, label: t('build.ranFine'), onPressed: () async {
                final st = await rust.recordOutcome(profileId: p.id, crashed: false);
                s.showToast('${st.rating}%');
              }),
              GhostButton(icon: Icons.warning_amber, label: t('build.crashed'), onPressed: () async {
                final st = await rust.recordOutcome(profileId: p.id, crashed: true);
                s.showToast('${st.rating}%');
              }),
            ],
          ),
        ),
        if (_cmd != null) ...[
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => setState(() => _cmd = null),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFF060504), borderRadius: BorderRadius.circular(6), border: Border.all(color: c.line)),
              child: SelectableText('\$ $_cmd', style: const TextStyle(fontFamily: 'monospace', fontSize: 12, color: Color(0xFF8FE39A))),
            ),
          ),
        ],
      ],
    );
  }

  Widget _loRow(BuildContext context, AppState s, DfColors c, Profile p, int idx) {
    final e = p.loadOrder[idx];
    return Container(
      key: ValueKey(e.path),
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(6), border: Border.all(color: c.line)),
      child: Opacity(
        opacity: e.enabled ? 1 : 0.45,
        child: Row(
          children: [
            ReorderableDragStartListener(index: idx, child: Icon(Icons.drag_indicator, size: 18, color: c.muted)),
            const SizedBox(width: 8),
            SizedBox(width: 22, child: Text('${idx + 1}', textAlign: TextAlign.right, style: TextStyle(fontSize: 12, fontFamily: 'monospace', color: c.muted))),
            const SizedBox(width: 10),
            Expanded(child: Text(e.name, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, color: c.fg))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(color: c.bg2, borderRadius: BorderRadius.circular(4), border: Border.all(color: c.line)),
              child: Text(e.group.label, style: TextStyle(fontSize: 10, letterSpacing: 0.5, color: groupColor(e.group, c))),
            ),
            const SizedBox(width: 6),
            SizedBox(
              width: 34,
              height: 20,
              child: Switch(
                value: e.enabled,
                activeColor: c.accent,
                onChanged: (v) {
                  final list = [...p.loadOrder];
                  list[idx] = e.copyWith(enabled: v);
                  s.upsertProfile(p.copyWith(loadOrder: list));
                },
              ),
            ),
            IconButton(
              icon: Icon(Icons.close, size: 14, color: c.muted),
              visualDensity: VisualDensity.compact,
              onPressed: () {
                final list = [...p.loadOrder]..removeAt(idx);
                s.upsertProfile(p.copyWith(loadOrder: list));
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _labeledDropdown(DfColors c, String label, String value, Map<String, String> items, ValueChanged<String> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: c.muted)),
        const SizedBox(height: 5),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(color: c.bg2, borderRadius: BorderRadius.circular(6), border: Border.all(color: c.line)),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: items.containsKey(value) ? value : '',
              dropdownColor: c.surface,
              style: TextStyle(fontSize: 13, color: c.fg),
              items: [for (final entry in items.entries) DropdownMenuItem(value: entry.key, child: Text(entry.value, overflow: TextOverflow.ellipsis))],
              onChanged: (v) => onChanged(v ?? ''),
            ),
          ),
        ),
      ],
    );
  }
}

class _CompatBar extends StatefulWidget {
  final Profile profile;
  const _CompatBar({required this.profile});
  @override
  State<_CompatBar> createState() => _CompatBarState();
}

class _CompatBarState extends State<_CompatBar> {
  CompatReport? _report;
  String? _forId;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final c = s.colors;
    // Recompute when the profile identity/size changes.
    final key = '${widget.profile.id}:${widget.profile.loadOrder.length}:${widget.profile.iwad}';
    if (_forId != key) {
      _forId = key;
      rust.evaluateCompat(profile: widget.profile).then((r) {
        if (mounted) setState(() => _report = r);
      });
    }
    final r = _report;
    if (r == null) return const SizedBox.shrink();
    final score = r.score;
    final barColor = score >= 80 ? c.ok : (score >= 50 ? c.accent2 : c.err);
    return DfPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text(tr(s.lang, 'compat.title'), style: TextStyle(fontSize: 13, color: c.fg)),
            const SizedBox(width: 8),
            Text('$score%', style: TextStyle(fontSize: 18, fontFamily: 'monospace', fontWeight: FontWeight.w700, color: barColor)),
          ]),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(value: score / 100, minHeight: 8, backgroundColor: c.bg2, color: barColor),
          ),
          for (final h in r.hits)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: h.severity == 'block' ? c.err : c.accent2, borderRadius: BorderRadius.circular(4)),
                  child: Text(h.severity.toUpperCase(), style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Color(0xFF1A1206))),
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(h.note, style: TextStyle(fontSize: 12, color: c.fgDim))),
              ]),
            ),
          for (final w in r.warnings)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text('• $w', style: TextStyle(fontSize: 12, color: c.muted)),
            ),
        ],
      ),
    );
  }
}

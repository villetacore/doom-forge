import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../i18n/i18n.dart';
import '../rust_ext.dart';
import '../theme/theme.dart';
import '../widgets/common.dart';
import 'build_view.dart' show groupColor;
import '../src/rust/api/doomforge.dart' as rust;
import '../src/rust/domain/models.dart';

const _groupOrder = [ModGroup.maps, ModGroup.gameplay, ModGroup.visuals, ModGroup.audio, ModGroup.patch, ModGroup.other];

String _fmtSize(BigInt b) {
  final n = b.toDouble();
  if (n > 1 << 20) return '${(n / (1 << 20)).toStringAsFixed(1)} MB';
  if (n > 1 << 10) return '${(n / (1 << 10)).toStringAsFixed(0)} KB';
  return '$b B';
}

class LibraryView extends StatefulWidget {
  const LibraryView({super.key});
  @override
  State<LibraryView> createState() => _LibraryViewState();
}

class _LibraryViewState extends State<LibraryView> {
  String _filter = '';
  List<DuplicateGroup>? _dupes;
  List<String>? _hits;
  final _searchCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final c = s.colors;
    String t(String k) => tr(s.lang, k);

    if (s.mods.isEmpty) {
      return EmptyHero(art: 'demon', title: t('library.emptyTitle'), hint: t('library.empty'));
    }

    final f = _filter.toLowerCase();
    final filtered = s.mods.where((m) => f.isEmpty || m.name.toLowerCase().contains(f) || m.tags.any((tg) => tg.toLowerCase().contains(f))).toList();

    return ListView(
      children: [
        Row(
          children: [
            Expanded(child: DfField(hint: t('library.filter'), onChanged: (v) => setState(() => _filter = v))),
            const SizedBox(width: 10),
            GhostButton(icon: Icons.search, label: t('library.findDupes'), onPressed: () async {
              final d = await rust.findDuplicates(files: s.mods);
              setState(() => _dupes = d);
            }),
            const SizedBox(width: 10),
            Expanded(
              child: DfField(
                hint: t('library.searchInside'),
                controller: _searchCtrl,
                onSubmitted: (v) async {
                  if (v.trim().isEmpty) return;
                  final h = await rust.searchModContents(files: s.mods, query: v.trim());
                  setState(() => _hits = h);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_dupes != null) _findings(c, '${t('library.duplicates')}${_dupes!.isEmpty ? ' — ${t('library.noDuplicates')}' : ''}', [
          for (final d in _dupes!) ...[
            Text(d.reason, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: c.fg)),
            for (final file in d.files) Text(file, style: TextStyle(fontSize: 11, color: c.muted)),
          ],
        ], () => setState(() => _dupes = null)),
        if (_hits != null) _findings(c, '"${_searchCtrl.text}" — ${_hits!.length}', [
          for (final h in _hits!) Text(h, style: TextStyle(fontSize: 11, color: c.muted)),
        ], () => setState(() => _hits = null)),
        for (final g in _groupOrder)
          if (filtered.any((m) => m.group == g)) _group(context, s, c, g, filtered.where((m) => m.group == g).toList()),
      ],
    );
  }

  Widget _group(BuildContext context, AppState s, DfColors c, ModGroup g, List<ModFile> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 9),
          child: Container(
            padding: const EdgeInsets.only(bottom: 6),
            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.line))),
            child: Row(children: [
              Text(g.label, style: TextStyle(fontSize: 13, letterSpacing: 0.5, color: groupColor(g, c))),
              Text('  (${items.length})', style: TextStyle(fontSize: 13, color: c.muted)),
            ]),
          ),
        ),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final m in items)
              SizedBox(width: 240, child: _card(context, s, c, m)),
          ],
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _card(BuildContext context, AppState s, DfColors c, ModFile m) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: c.line)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(m.name, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: c.fg)),
          const SizedBox(height: 7),
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: c.bg2, borderRadius: BorderRadius.circular(4), border: Border.all(color: c.line)),
              child: Text(m.extension_.toUpperCase(), style: TextStyle(fontSize: 10, color: c.muted)),
            ),
            const SizedBox(width: 8),
            Text(_fmtSize(m.size), style: TextStyle(fontSize: 11, color: c.muted)),
          ]),
          const SizedBox(height: 9),
          GhostButton(icon: Icons.add, label: tr(s.lang, 'library.addToBuild'), onPressed: () {
            final p = s.activeProfile;
            if (p == null) return s.showToast(tr(s.lang, 'build.empty'));
            if (p.loadOrder.any((e) => e.path == m.path)) return;
            s.upsertProfile(p.copyWith(loadOrder: [...p.loadOrder, LoadEntry(path: m.path, name: m.name, group: m.group, enabled: true)]));
            s.showToast('OK');
          }),
        ],
      ),
    );
  }

  Widget _findings(DfColors c, String title, List<Widget> body, VoidCallback onDismiss) => Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: c.line)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: c.fg)),
            const SizedBox(height: 6),
            ...body,
            const SizedBox(height: 6),
            GhostButton(label: tr(context.read<AppState>().lang, 'common.dismiss'), onPressed: onDismiss),
          ],
        ),
      );
}

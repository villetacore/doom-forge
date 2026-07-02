import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../i18n/i18n.dart';
import '../theme/theme.dart';
import '../widgets/common.dart';
import '../src/rust/api/doomforge.dart' as rust;
import '../src/rust/services/net.dart';

class BrowseView extends StatefulWidget {
  const BrowseView({super.key});
  @override
  State<BrowseView> createState() => _BrowseViewState();
}

class _BrowseViewState extends State<BrowseView> {
  bool _busy = false;
  List<PackageEntry> _cat = [];
  List<PackageEntry>? _idRes;
  final _urlCtrl = TextEditingController();
  final _idCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    rust.catalog().then((v) => mounted ? setState(() => _cat = v) : null).catchError((_) {});
  }

  Future<void> _rescan(AppState s) async => s.rescanMods();

  Future<void> _installCat(AppState s, PackageEntry p) async {
    if (s.modsDir.isEmpty) return s.showToast(tr(s.lang, 'library.empty'));
    setState(() => _busy = true);
    try {
      s.showToast(await rust.installCatalog(url: p.url, modsDir: s.modsDir));
      await _rescan(s);
    } catch (e) {
      s.showToast('$e');
    } finally {
      setState(() => _busy = false);
    }
  }

  Future<void> _importUrl(AppState s) async {
    if (s.modsDir.isEmpty) return s.showToast(tr(s.lang, 'library.empty'));
    final url = _urlCtrl.text.trim();
    if (url.isEmpty) return;
    setState(() => _busy = true);
    try {
      s.showToast(await rust.importByUrl(url: url, destDir: s.modsDir));
      await _rescan(s);
      _urlCtrl.clear();
    } catch (e) {
      s.showToast('$e');
    } finally {
      setState(() => _busy = false);
    }
  }

  Future<void> _idSearch(AppState s) async {
    final q = _idCtrl.text.trim();
    if (q.isEmpty) return;
    setState(() => _busy = true);
    try {
      final r = await rust.idgamesSearch(query: q);
      setState(() => _idRes = r);
    } catch (e) {
      s.showToast('$e');
    } finally {
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final c = s.colors;
    String t(String k) => tr(s.lang, k);

    return ListView(
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 940),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SectionTitle(t('browse.catalog'), hint: t('browse.catalogHint')),
              Wrap(
                spacing: 11,
                runSpacing: 11,
                children: [
                  for (final p in _cat)
                    SizedBox(width: 250, child: _pkgCard(c, p, t('common.install'), _busy ? null : () => _installCat(s, p), primary: true)),
                ],
              ),
              const SizedBox(height: 22),
              DfPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SectionTitle(t('browse.importUrl'), hint: t('browse.importHint')),
                    Row(children: [
                      Expanded(child: DfField(hint: 'https://…/mod.pk3', controller: _urlCtrl, onSubmitted: (_) => _importUrl(s))),
                      const SizedBox(width: 8),
                      PrimaryButton(icon: Icons.download, label: t('common.download'), onPressed: _busy ? null : () => _importUrl(s)),
                    ]),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              SectionTitle(t('browse.idgames'), hint: t('browse.idgamesHint')),
              Row(children: [
                Expanded(child: DfField(hint: t('common.search'), controller: _idCtrl, onSubmitted: (_) => _idSearch(s))),
                const SizedBox(width: 8),
                GhostButton(icon: Icons.search, label: t('common.search'), onPressed: _busy ? null : () => _idSearch(s)),
              ]),
              const SizedBox(height: 12),
              if (_idRes != null)
                Wrap(
                  spacing: 11,
                  runSpacing: 11,
                  children: [
                    for (final p in _idRes!)
                      SizedBox(width: 250, child: _pkgCard(c, p, t('common.download'), _busy ? null : () async {
                        if (s.modsDir.isEmpty) return s.showToast(tr(s.lang, 'library.empty'));
                        setState(() => _busy = true);
                        try {
                          s.showToast(await rust.importByUrl(url: p.url, destDir: s.modsDir));
                          await _rescan(s);
                        } catch (e) {
                          s.showToast('$e');
                        } finally {
                          setState(() => _busy = false);
                        }
                      })),
                  ],
                ),
              const SizedBox(height: 22),
              DfPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [SectionTitle(t('browse.moddb'), hint: t('browse.moddbHint'))],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _pkgCard(DfColors c, PackageEntry p, String action, VoidCallback? onTap, {bool primary = false}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: c.line)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(p.name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: c.fg)),
          const SizedBox(height: 8),
          Text(p.description, style: TextStyle(fontSize: 12, color: c.muted, height: 1.5)),
          const SizedBox(height: 8),
          if (p.tags.isNotEmpty)
            Wrap(spacing: 4, runSpacing: 4, children: [
              for (final tg in p.tags)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: c.bg2, borderRadius: BorderRadius.circular(4), border: Border.all(color: c.line)),
                  child: Text(tg, style: TextStyle(fontSize: 10, color: c.muted)),
                ),
            ]),
          const SizedBox(height: 10),
          primary
              ? PrimaryButton(icon: Icons.download, label: action, onPressed: onTap)
              : GhostButton(icon: Icons.download, label: action, onPressed: onTap),
        ],
      ),
    );
  }
}

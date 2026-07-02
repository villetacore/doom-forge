import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../i18n/i18n.dart';
import '../theme/theme.dart';
import '../widgets/common.dart';
import '../src/rust/api/doomforge.dart' as rust;

class StatusView extends StatefulWidget {
  const StatusView({super.key});
  @override
  State<StatusView> createState() => _StatusViewState();
}

class _StatusViewState extends State<StatusView> {
  String? busy;

  Future<void> _detect(AppState s) async {
    setState(() => busy = 'detect');
    try {
      final found = await rust.detectEngines();
      final merged = [...s.engines];
      for (final e in found) {
        if (!merged.any((m) => m.path == e.path)) merged.add(e);
      }
      s.setEngines(merged);
      s.showToast('${found.length}');
    } catch (e) {
      s.showToast('$e');
    } finally {
      setState(() => busy = null);
    }
  }

  Future<void> _getGz(AppState s) async {
    if (s.engineDir.isEmpty) return s.showToast(tr(s.lang, 'sidebar.engines'));
    setState(() => busy = 'gz');
    try {
      s.showToast(await rust.installGzdoom(destDir: s.engineDir));
      s.setEngines(await rust.scanEngines(dir: s.engineDir));
    } catch (e) {
      s.showToast('$e');
    } finally {
      setState(() => busy = null);
    }
  }

  Future<void> _getFd(AppState s) async {
    if (s.iwadDirs.isEmpty) return s.showToast(tr(s.lang, 'sidebar.iwads'));
    setState(() => busy = 'fd');
    try {
      final w = await rust.installFreedoom(iwadDir: s.iwadDirs.first);
      s.setIwads(await rust.checkIwads(dirs: s.iwadDirs.where((d) => d.isNotEmpty).toList()));
      s.showToast('${w.length}');
    } catch (e) {
      s.showToast('$e');
    } finally {
      setState(() => busy = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final c = s.colors;
    String t(String k) => tr(s.lang, k);

    return ListView(
      children: [
        _head(c, t('status.engines'), '${s.engines.length} ${t('status.detected')}', [
          GhostButton(icon: Icons.search, label: t('status.detect'), onPressed: busy == null ? () => _detect(s) : null),
          const SizedBox(width: 8),
          GhostButton(icon: Icons.download, label: t('status.getGzdoom'), onPressed: busy == null ? () => _getGz(s) : null),
        ]),
        if (s.engines.isEmpty)
          Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text(t('status.noEngines'), style: TextStyle(fontSize: 13, color: c.muted)))
        else
          DfPanel(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (final e in s.engines)
                  _row(c, [
                    Expanded(flex: 3, child: Text(e.name, style: TextStyle(fontSize: 13, color: c.fg))),
                    Expanded(flex: 2, child: Text(e.version ?? '?', style: TextStyle(fontSize: 13, fontFamily: 'monospace', color: c.accent2))),
                    Expanded(flex: 5, child: Text(e.path, style: TextStyle(fontSize: 11, color: c.muted), overflow: TextOverflow.ellipsis)),
                  ]),
              ],
            ),
          ),
        const SizedBox(height: 26),
        _head(c, t('status.iwads'), '${s.iwadsPresent}/${s.iwads.length} ${t('status.found')}', [
          GhostButton(icon: Icons.download, label: t('status.getFreedoom'), onPressed: busy == null ? () => _getFd(s) : null),
        ]),
        DfPanel(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (final i in s.iwads)
                _row(c, [
                  SizedBox(width: 26, child: i.present ? Icon(Icons.check, size: 15, color: c.ok) : Text('—', style: TextStyle(color: c.err))),
                  Expanded(flex: 4, child: Text(i.title, style: TextStyle(fontSize: 13, color: i.present ? c.fg : c.muted))),
                  Expanded(flex: 3, child: Text(i.fileName, style: TextStyle(fontSize: 12, fontFamily: 'monospace', color: c.accent2))),
                  Expanded(flex: 4, child: Text(i.path ?? '—', style: TextStyle(fontSize: 11, color: c.muted), overflow: TextOverflow.ellipsis)),
                ]),
            ],
          ),
        ),
      ],
    );
  }

  Widget _head(DfColors c, String title, String meta, List<Widget> actions) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: c.fg)),
            const SizedBox(width: 12),
            Text(meta, style: TextStyle(fontSize: 13, color: c.muted)),
            const Spacer(),
            ...actions,
          ],
        ),
      );

  Widget _row(DfColors c, List<Widget> cells) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.line))),
        child: Row(children: cells),
      );
}

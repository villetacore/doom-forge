import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../i18n/i18n.dart';
import '../widgets/common.dart';
import '../src/rust/api/doomforge.dart' as rust;
import '../src/rust/domain/models.dart';

class CrashView extends StatefulWidget {
  const CrashView({super.key});
  @override
  State<CrashView> createState() => _CrashViewState();
}

class _CrashViewState extends State<CrashView> {
  final _ctrl = TextEditingController();
  LogAnalysis? _result;
  String? _ai;
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final c = s.colors;
    String t(String k) => tr(s.lang, k);
    final p = s.activeProfile;

    return ListView(
      children: [
        Text(t('crash.hint'), style: TextStyle(fontSize: 12, color: c.muted)),
        const SizedBox(height: 12),
        Row(children: [
          GhostButton(icon: Icons.search, label: t('crash.analyze'), onPressed: (_ctrl.text.trim().isEmpty || p == null)
              ? null
              : () async {
                  final r = await rust.analyzeLogText(text: _ctrl.text, profile: p);
                  setState(() => _result = r);
                }),
          const SizedBox(width: 8),
          GhostButton(icon: Icons.auto_awesome, label: t('crash.ai'), onPressed: (_ctrl.text.trim().isEmpty || _busy)
              ? null
              : () async {
                  if (s.aiKey.isEmpty) return s.showToast(tr(s.lang, 'settings.aiKey'));
                  if (p == null) return;
                  setState(() => _busy = true);
                  try {
                    final r = await rust.aiAnalyzeLog(apiKey: s.aiKey, model: s.aiModel, log: _ctrl.text, loadOrder: p.loadOrder.where((e) => e.enabled).map((e) => e.name).toList());
                    setState(() => _ai = r);
                  } catch (e) {
                    s.showToast('$e');
                  } finally {
                    setState(() => _busy = false);
                  }
                }),
        ]),
        const SizedBox(height: 12),
        TextField(
          controller: _ctrl,
          maxLines: 10,
          onChanged: (_) => setState(() {}),
          style: TextStyle(fontSize: 12, fontFamily: 'monospace', color: c.fg),
          decoration: InputDecoration(
            hintText: t('crash.paste'),
            hintStyle: TextStyle(color: c.muted),
            filled: true,
            fillColor: c.bg2,
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: c.line)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: c.accent)),
          ),
        ),
        if (_result != null) ...[
          const SizedBox(height: 12),
          DfPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_result!.summary, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: c.fg)),
                if (_result!.suspectMods.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text('${t('crash.suspects')}:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: c.fgDim)),
                  for (final m in _result!.suspectMods) Text('• $m', style: TextStyle(fontSize: 12, color: c.muted)),
                ],
                if (_result!.signals.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text('${t('crash.signals')}:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: c.fgDim)),
                  for (final sig in _result!.signals) Text('• $sig', style: TextStyle(fontSize: 12, color: c.muted)),
                ],
              ],
            ),
          ),
        ],
        if (_ai != null) ...[
          const SizedBox(height: 12),
          DfPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t('crash.ai'), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: c.accent2)),
                const SizedBox(height: 8),
                Text(_ai!, style: TextStyle(fontSize: 13, color: c.fgDim, height: 1.5)),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

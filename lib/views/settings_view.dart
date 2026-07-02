import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../i18n/i18n.dart';
import '../theme/theme.dart';
import '../widgets/common.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final c = s.colors;
    String t(String k) => tr(s.lang, k);

    return ListView(
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 660),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DfPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SectionTitle(t('settings.appearance')),
                    const SizedBox(height: 8),
                    _opt(c, t('settings.theme'), _ModeSeg()),
                    _opt(c, t('settings.palette'), const _Swatches()),
                    _opt(
                      c,
                      t('settings.language'),
                      DropdownButton<String>(
                        value: s.lang,
                        dropdownColor: c.surface,
                        underline: const SizedBox.shrink(),
                        items: [for (final l in kLanguages) DropdownMenuItem(value: l.id, child: Text(l.label, style: TextStyle(color: c.fg)))],
                        onChanged: (v) => s.updateSettings(() => s.lang = v ?? s.lang),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              DfPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SectionTitle(t('settings.integrations')),
                    const SizedBox(height: 8),
                    DfField(label: t('settings.registry'), hint: 'https://…/registry.json', controller: TextEditingController(text: s.registry), onChanged: (v) => s.updateSettings(() => s.registry = v)),
                    const SizedBox(height: 12),
                    DfField(label: t('settings.aiKey'), hint: 'sk-ant-…', obscure: true, controller: TextEditingController(text: s.aiKey), onChanged: (v) => s.updateSettings(() => s.aiKey = v)),
                    const SizedBox(height: 12),
                    DfField(label: t('settings.aiModel'), controller: TextEditingController(text: s.aiModel), onChanged: (v) => s.updateSettings(() => s.aiModel = v)),
                    const SizedBox(height: 10),
                    Text(t('settings.aiHint'), style: TextStyle(fontSize: 12, color: c.muted)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _opt(DfColors c, String label, Widget control) => Container(
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.line))),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [Text(label, style: TextStyle(fontSize: 13.5, color: c.fg)), control],
        ),
      );
}

class _ModeSeg extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final c = s.colors;
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(color: c.bg2, borderRadius: BorderRadius.circular(6), border: Border.all(color: c.line)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final m in DfMode.values)
            GestureDetector(
              onTap: () => s.updateSettings(() => s.mode = m),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 5),
                decoration: BoxDecoration(
                  gradient: s.mode == m ? LinearGradient(colors: [c.accent2, c.accent]) : null,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(tr(s.lang, 'settings.${m.name}'),
                    style: TextStyle(fontSize: 12.5, color: s.mode == m ? const Color(0xFF1A1206) : c.muted, fontWeight: s.mode == m ? FontWeight.w600 : FontWeight.normal)),
              ),
            ),
        ],
      ),
    );
  }
}

class _Swatches extends StatelessWidget {
  const _Swatches();
  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final c = s.colors;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 360),
      child: Wrap(
        alignment: WrapAlignment.end,
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final p in kPalettes)
            GestureDetector(
              onTap: () => s.updateSettings(() => s.palette = p.id),
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: [p.accent, p.accent2], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  border: Border.all(color: s.palette == p.id ? c.fg : Colors.transparent, width: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

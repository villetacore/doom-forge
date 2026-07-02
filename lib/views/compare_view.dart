import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../i18n/i18n.dart';
import '../theme/theme.dart';
import '../widgets/common.dart';
import '../src/rust/api/doomforge.dart' as rust;
import '../src/rust/domain/models.dart';

class CompareView extends StatefulWidget {
  const CompareView({super.key});
  @override
  State<CompareView> createState() => _CompareViewState();
}

class _CompareViewState extends State<CompareView> {
  String? _aId;
  String? _bId;
  ProfileDiff? _diff;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final c = s.colors;
    String t(String k) => tr(s.lang, k);

    Widget picker(String? value, ValueChanged<String?> onChanged, String hint) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(color: c.bg2, borderRadius: BorderRadius.circular(6), border: Border.all(color: c.line)),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              hint: Text(hint, style: TextStyle(fontSize: 13, color: c.muted)),
              dropdownColor: c.surface,
              style: TextStyle(fontSize: 13, color: c.fg),
              items: [for (final p in s.profiles) DropdownMenuItem(value: p.id, child: Text(p.name))],
              onChanged: onChanged,
            ),
          ),
        );

    return ListView(
      children: [
        Row(
          children: [
            SizedBox(width: 200, child: picker(_aId, (v) => setState(() => _aId = v), 'A — ${t('compare.pick')}')),
            const SizedBox(width: 10),
            Text('vs', style: TextStyle(color: c.muted)),
            const SizedBox(width: 10),
            SizedBox(width: 200, child: picker(_bId, (v) => setState(() => _bId = v), 'B — ${t('compare.pick')}')),
            const SizedBox(width: 10),
            PrimaryButton(icon: Icons.compare_arrows, label: t('nav.compare'), onPressed: (_aId != null && _bId != null)
                ? () async {
                    final a = s.profiles.firstWhere((p) => p.id == _aId);
                    final b = s.profiles.firstWhere((p) => p.id == _bId);
                    final d = await rust.compareProfiles(a: a, b: b);
                    setState(() => _diff = d);
                  }
                : null),
          ],
        ),
        const SizedBox(height: 18),
        if (_diff != null)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _col(c, '${t('compare.onlyA')} (${_diff!.onlyInA.length})', _diff!.onlyInA, c.err)),
              const SizedBox(width: 16),
              Expanded(child: _col(c, '${t('compare.common')} (${_diff!.common.length})${_diff!.reordered ? ' · ${t('compare.reordered')}' : ''}', _diff!.common, c.muted)),
              const SizedBox(width: 16),
              Expanded(child: _col(c, '${t('compare.onlyB')} (${_diff!.onlyInB.length})', _diff!.onlyInB, c.ok)),
            ],
          ),
      ],
    );
  }

  Widget _col(DfColors c, String title, List<String> items, Color color) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: color)),
          const SizedBox(height: 8),
          for (final i in items) Padding(padding: const EdgeInsets.only(bottom: 3), child: Text(i, style: TextStyle(fontSize: 13, color: c.fgDim))),
        ],
      );
}

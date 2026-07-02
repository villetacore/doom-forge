import 'package:flutter/material.dart';

/// Base neutral modes (like the React app's dark/light/amoled).
enum DfMode { dark, light, amoled }

/// A swappable accent palette ("color scheme").
class DfPalette {
  final String id;
  final String label;
  final Color accent;
  final Color accent2;
  const DfPalette(this.id, this.label, this.accent, this.accent2);
}

const List<DfPalette> kPalettes = [
  DfPalette('ember', 'Ember', Color(0xFFE2603A), Color(0xFFF0A23A)),
  DfPalette('plasma', 'Plasma', Color(0xFF9B6CFF), Color(0xFFC08BFF)),
  DfPalette('toxic', 'Toxic', Color(0xFF4CAF50), Color(0xFF9AE66E)),
  DfPalette('abyss', 'Abyss', Color(0xFF3A8EE2), Color(0xFF4CC7E0)),
  DfPalette('blood', 'Blood', Color(0xFFD23F3F), Color(0xFFF0653A)),
  DfPalette('gold', 'Gold', Color(0xFFD9A227), Color(0xFFF2D24B)),
  DfPalette('cobalt', 'Cobalt', Color(0xFF4666E0), Color(0xFF6F9BFF)),
  DfPalette('viridian', 'Viridian', Color(0xFF1FAE8E), Color(0xFF54E0C0)),
  DfPalette('magenta', 'Magenta', Color(0xFFD6359B), Color(0xFFFF6FC7)),
  DfPalette('slate', 'Slate', Color(0xFF6C7A92), Color(0xFF9FB0C8)),
];

DfPalette paletteById(String id) =>
    kPalettes.firstWhere((p) => p.id == id, orElse: () => kPalettes.first);

/// The full resolved token set for a (mode, palette) pair — the Dart analogue
/// of the CSS custom properties the web app wrote onto <html>.
class DfColors {
  final Color bg, bg2, surface, surface2, line, fg, fgDim, muted, ok, err, shadow;
  final Color accent, accent2, accentSoft, accentLine;
  final DfMode mode;
  final String paletteId;

  const DfColors({
    required this.mode,
    required this.paletteId,
    required this.bg,
    required this.bg2,
    required this.surface,
    required this.surface2,
    required this.line,
    required this.fg,
    required this.fgDim,
    required this.muted,
    required this.ok,
    required this.err,
    required this.shadow,
    required this.accent,
    required this.accent2,
    required this.accentSoft,
    required this.accentLine,
  });

  bool get isDark => mode != DfMode.light;

  factory DfColors.resolve(DfMode mode, String paletteId) {
    final p = paletteById(paletteId);
    final n = _neutrals[mode]!;
    return DfColors(
      mode: mode,
      paletteId: paletteId,
      bg: n['bg']!,
      bg2: n['bg2']!,
      surface: n['surface']!,
      surface2: n['surface2']!,
      line: n['line']!,
      fg: n['fg']!,
      fgDim: n['fgDim']!,
      muted: n['muted']!,
      ok: n['ok']!,
      err: n['err']!,
      shadow: n['shadow']!,
      accent: p.accent,
      accent2: p.accent2,
      accentSoft: p.accent.withValues(alpha: 0.16),
      accentLine: p.accent.withValues(alpha: 0.40),
    );
  }

  ThemeData toThemeData() {
    final base = isDark ? ThemeData.dark() : ThemeData.light();
    return base.copyWith(
      scaffoldBackgroundColor: bg,
      canvasColor: bg,
      colorScheme: base.colorScheme.copyWith(
        primary: accent,
        secondary: accent2,
        surface: surface,
        error: err,
      ),
      dividerColor: line,
      textTheme: base.textTheme.apply(bodyColor: fg, displayColor: fg),
    );
  }
}

const Map<DfMode, Map<String, Color>> _neutrals = {
  DfMode.dark: {
    'bg': Color(0xFF0E0D0C),
    'bg2': Color(0xFF16140F),
    'surface': Color(0xFF1B1814),
    'surface2': Color(0xFF231F19),
    'line': Color(0xFF322A20),
    'fg': Color(0xFFECE4D8),
    'fgDim': Color(0xFFB6AA99),
    'muted': Color(0xFF897C6A),
    'ok': Color(0xFF5FBF6A),
    'err': Color(0xFFE2564F),
    'shadow': Color(0x73000000),
  },
  DfMode.light: {
    'bg': Color(0xFFF2EFE9),
    'bg2': Color(0xFFE9E4DA),
    'surface': Color(0xFFFFFFFF),
    'surface2': Color(0xFFF4F0E8),
    'line': Color(0xFFD8CFBF),
    'fg': Color(0xFF241F18),
    'fgDim': Color(0xFF4A4234),
    'muted': Color(0xFF7C715F),
    'ok': Color(0xFF3F9D4A),
    'err': Color(0xFFC63B35),
    'shadow': Color(0x263C2D19),
  },
  DfMode.amoled: {
    'bg': Color(0xFF000000),
    'bg2': Color(0xFF080807),
    'surface': Color(0xFF0F0E0C),
    'surface2': Color(0xFF161513),
    'line': Color(0xFF26221C),
    'fg': Color(0xFFF2ECE2),
    'fgDim': Color(0xFFBCB1A0),
    'muted': Color(0xFF7E7361),
    'ok': Color(0xFF5FBF6A),
    'err': Color(0xFFE2564F),
    'shadow': Color(0xB3000000),
  },
};

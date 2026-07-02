import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app_state.dart';
import 'i18n/i18n.dart';
import 'shell.dart';

/// Sections, mirroring the React app's nav.
enum Section { build, library, browse, compare, crash, status, settings }

class DoomForgeApp extends StatelessWidget {
  const DoomForgeApp({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final base = state.colors.toThemeData();
    return MaterialApp(
      title: 'DoomForge — GZDoom Launcher',
      debugShowCheckedModeBanner: false,
      theme: base.copyWith(
        scrollbarTheme: ScrollbarThemeData(
          thumbColor: WidgetStatePropertyAll(state.colors.line),
          thickness: const WidgetStatePropertyAll(8),
          radius: const Radius.circular(6),
        ),
      ),
      home: const Shell(),
    );
  }
}

/// Small helpers to cut boilerplate in views.
extension L10n on BuildContext {
  String t(String key) => tr(read<AppState>().lang, key);
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import 'art.dart';

/// A surface card with the signature top accent line.
class DfPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  const DfPanel({super.key, required this.child, this.padding = const EdgeInsets.fromLTRB(16, 16, 16, 16)});

  @override
  Widget build(BuildContext context) {
    final c = context.watch<AppState>().colors;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: c.line),
      ),
      child: child,
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String title;
  final String? hint;
  const SectionTitle(this.title, {super.key, this.hint});

  @override
  Widget build(BuildContext context) {
    final c = context.watch<AppState>().colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: c.fg)),
        if (hint != null)
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 8),
            child: Text(hint!, style: TextStyle(fontSize: 12, color: c.muted, height: 1.5)),
          ),
      ],
    );
  }
}

/// A centered illustrated empty state.
class EmptyHero extends StatelessWidget {
  final String art;
  final String title;
  final String hint;
  final Widget? action;
  const EmptyHero({super.key, required this.art, required this.title, required this.hint, this.action});

  @override
  Widget build(BuildContext context) {
    final c = context.watch<AppState>().colors;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            HeroArt(name: art, accent: c.accent, accent2: c.accent2, bg: c.bg),
            const SizedBox(height: 12),
            Text(title, style: TextStyle(fontSize: 21, fontWeight: FontWeight.w700, color: c.fg)),
            const SizedBox(height: 6),
            Text(hint, textAlign: TextAlign.center, style: TextStyle(fontSize: 13.5, color: c.muted, height: 1.6)),
            if (action != null) ...[const SizedBox(height: 14), action!],
          ],
        ),
      ),
    );
  }
}

/// A primary "ember" gradient button.
class PrimaryButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool large;
  const PrimaryButton({super.key, required this.icon, required this.label, this.onPressed, this.large = false});

  @override
  Widget build(BuildContext context) {
    final c = context.watch<AppState>().colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [c.accent2, c.accent], begin: Alignment.topCenter, end: Alignment.bottomCenter),
        borderRadius: BorderRadius.circular(6),
        boxShadow: [BoxShadow(color: c.accent.withValues(alpha: 0.5), blurRadius: 14, offset: const Offset(0, 3))],
      ),
      child: TextButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: large ? 20 : 16, color: const Color(0xFF1A1206)),
        label: Text(label,
            style: TextStyle(
              color: const Color(0xFF1A1206),
              fontWeight: FontWeight.w700,
              letterSpacing: large ? 0.4 : 0,
              fontSize: large ? 15 : 13,
            )),
        style: TextButton.styleFrom(
          padding: EdgeInsets.symmetric(horizontal: large ? 24 : 14, vertical: large ? 14 : 9),
        ),
      ),
    );
  }
}

/// A neutral outlined button.
class GhostButton extends StatelessWidget {
  final IconData? icon;
  final String label;
  final VoidCallback? onPressed;
  final bool danger;
  const GhostButton({super.key, this.icon, required this.label, this.onPressed, this.danger = false});

  @override
  Widget build(BuildContext context) {
    final c = context.watch<AppState>().colors;
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: icon == null ? const SizedBox.shrink() : Icon(icon, size: 15),
      label: Text(label, style: const TextStyle(fontSize: 13)),
      style: OutlinedButton.styleFrom(
        foregroundColor: danger ? c.err : c.fg,
        backgroundColor: c.surface2,
        side: BorderSide(color: c.line),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
    );
  }
}

/// A themed text field.
class DfField extends StatelessWidget {
  final String? label;
  final String? hint;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool obscure;
  final int? maxLines;
  const DfField({super.key, this.label, this.hint, this.controller, this.onChanged, this.onSubmitted, this.obscure = false, this.maxLines = 1});

  @override
  Widget build(BuildContext context) {
    final c = context.watch<AppState>().colors;
    final field = TextField(
      controller: controller,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      obscureText: obscure,
      maxLines: obscure ? 1 : maxLines,
      style: TextStyle(fontSize: 13, color: c.fg),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: c.muted),
        isDense: true,
        filled: true,
        fillColor: c.bg2,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: c.line)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: c.accent, width: 1.4)),
      ),
    );
    if (label == null) return field;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label!, style: TextStyle(fontSize: 12, color: c.muted)),
        const SizedBox(height: 5),
        field,
      ],
    );
  }
}

import 'package:flutter/material.dart';

/// The DoomForge demon-skull brand mark, painted in the current accent colours.
class BrandMark extends StatelessWidget {
  final double size;
  final Color accent;
  final Color accent2;
  final Color bg;
  const BrandMark({
    super.key,
    this.size = 36,
    required this.accent,
    required this.accent2,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
        width: size,
        height: size,
        child: CustomPaint(painter: _SkullPainter(accent, accent2, bg, badge: true)),
      );
}

/// Large decorative art for empty states.
class HeroArt extends StatelessWidget {
  final String name; // helmet | demon | skull
  final double size;
  final Color accent;
  final Color accent2;
  final Color bg;
  const HeroArt({
    super.key,
    required this.name,
    this.size = 132,
    required this.accent,
    required this.accent2,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
        width: size,
        height: size,
        child: CustomPaint(painter: _HeroPainter(name, accent, accent2, bg)),
      );
}

class _SkullPainter extends CustomPainter {
  final Color accent, accent2, bg;
  final bool badge;
  _SkullPainter(this.accent, this.accent2, this.bg, {this.badge = false});

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 64.0;
    Offset p(double x, double y) => Offset(x * s, y * s);
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4 * s
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = accent;
    final stroke2 = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6 * s
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = accent2;
    final fillBg = Paint()..color = bg;
    final eye = Paint()..color = accent2;

    if (badge) {
      final hex = Path()
        ..moveTo(32 * s, 2 * s)
        ..lineTo(56 * s, 16 * s)
        ..lineTo(56 * s, 48 * s)
        ..lineTo(32 * s, 62 * s)
        ..lineTo(8 * s, 48 * s)
        ..lineTo(8 * s, 16 * s)
        ..close();
      canvas.drawPath(hex, Paint()..color = accent.withValues(alpha: 0.14));
      canvas.drawPath(hex, stroke..strokeWidth = 2.2 * s);
    }

    // horns
    final horns = Path()
      ..moveTo(21 * s, 22 * s)
      ..cubicTo(16 * s, 20 * s, 12 * s, 16 * s, 11 * s, 10 * s)
      ..moveTo(11 * s, 10 * s)
      ..cubicTo(16 * s, 11 * s, 20 * s, 13 * s, 23 * s, 17 * s)
      ..moveTo(43 * s, 22 * s)
      ..cubicTo(48 * s, 20 * s, 52 * s, 16 * s, 53 * s, 10 * s)
      ..moveTo(53 * s, 10 * s)
      ..cubicTo(48 * s, 11 * s, 44 * s, 13 * s, 41 * s, 17 * s);
    canvas.drawPath(horns, stroke2);

    // cranium + jaw
    final skull = Path()
      ..moveTo(32 * s, 14 * s)
      ..cubicTo(23 * s, 14 * s, 17 * s, 20 * s, 17 * s, 29 * s)
      ..cubicTo(17 * s, 34 * s, 19 * s, 37 * s, 22 * s, 40 * s)
      ..lineTo(23 * s, 47 * s)
      ..lineTo(27 * s, 45 * s)
      ..lineTo(32 * s, 47 * s)
      ..lineTo(37 * s, 45 * s)
      ..lineTo(41 * s, 47 * s)
      ..lineTo(42 * s, 40 * s)
      ..cubicTo(45 * s, 37 * s, 47 * s, 34 * s, 47 * s, 29 * s)
      ..cubicTo(47 * s, 20 * s, 41 * s, 14 * s, 32 * s, 14 * s)
      ..close();
    canvas.drawPath(skull, fillBg);
    canvas.drawPath(skull, stroke..color = accent2..strokeWidth = 2.2 * s);

    // eyes
    canvas.drawPath(
        Path()
          ..moveTo(22 * s, 30 * s)
          ..lineTo(30 * s, 33 * s)
          ..lineTo(28 * s, 38 * s)
          ..lineTo(21 * s, 35 * s)
          ..close(),
        eye);
    canvas.drawPath(
        Path()
          ..moveTo(42 * s, 30 * s)
          ..lineTo(34 * s, 33 * s)
          ..lineTo(36 * s, 38 * s)
          ..lineTo(43 * s, 35 * s)
          ..close(),
        eye);

    // snout + teeth
    final teeth = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8 * s
      ..strokeCap = StrokeCap.round
      ..color = accent2;
    canvas.drawLine(p(29, 44), p(29, 49), teeth);
    canvas.drawLine(p(32, 45), p(32, 50), teeth);
    canvas.drawLine(p(35, 44), p(35, 49), teeth);
  }

  @override
  bool shouldRepaint(covariant _SkullPainter old) =>
      old.accent != accent || old.accent2 != accent2 || old.bg != bg;
}

class _HeroPainter extends CustomPainter {
  final String name;
  final Color accent, accent2, bg;
  _HeroPainter(this.name, this.accent, this.accent2, this.bg);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    // soft glow
    canvas.drawCircle(
      Offset(w * 0.5, w * 0.47),
      w * 0.46,
      Paint()..color = accent.withValues(alpha: 0.16),
    );
    final s = w / 120.0;
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6 * s
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = accent2;
    final soft = Paint()..color = accent.withValues(alpha: 0.18);

    if (name == 'demon') {
      canvas.drawCircle(Offset(60 * s, 58 * s), 34 * s, soft);
      canvas.drawCircle(Offset(60 * s, 58 * s), 34 * s, stroke);
      // horns
      final horns = Path()
        ..moveTo(42 * s, 32 * s)
        ..cubicTo(39 * s, 24 * s, 40 * s, 18 * s, 44 * s, 15 * s)
        ..moveTo(78 * s, 32 * s)
        ..cubicTo(81 * s, 24 * s, 80 * s, 18 * s, 76 * s, 15 * s);
      canvas.drawPath(horns, stroke);
      // eye
      canvas.drawCircle(Offset(60 * s, 52 * s), 11 * s, Paint()..color = bg);
      canvas.drawCircle(Offset(60 * s, 52 * s), 4.5 * s, Paint()..color = accent2);
      // grin
      final grin = Path()
        ..moveTo(42 * s, 70 * s)
        ..quadraticBezierTo(60 * s, 82 * s, 78 * s, 70 * s);
      canvas.drawPath(grin, stroke);
    } else {
      // helmet
      final helmet = Path()
        ..moveTo(30 * s, 56 * s)
        ..cubicTo(30 * s, 36 * s, 43 * s, 24 * s, 60 * s, 24 * s)
        ..cubicTo(77 * s, 24 * s, 90 * s, 36 * s, 90 * s, 56 * s)
        ..cubicTo(90 * s, 66 * s, 86 * s, 74 * s, 80 * s, 80 * s)
        ..lineTo(77 * s, 92 * s)
        ..lineTo(69 * s, 88 * s)
        ..cubicTo(63 * s, 90 * s, 57 * s, 90 * s, 51 * s, 88 * s)
        ..lineTo(43 * s, 92 * s)
        ..lineTo(40 * s, 80 * s)
        ..cubicTo(34 * s, 74 * s, 30 * s, 66 * s, 30 * s, 56 * s)
        ..close();
      canvas.drawPath(helmet, stroke);
      // visor
      final visor = Path()
        ..moveTo(40 * s, 52 * s)
        ..cubicTo(46 * s, 47 * s, 53 * s, 45 * s, 60 * s, 45 * s)
        ..cubicTo(67 * s, 45 * s, 74 * s, 47 * s, 80 * s, 52 * s)
        ..lineTo(77 * s, 66 * s)
        ..cubicTo(72 * s, 70 * s, 66 * s, 72 * s, 60 * s, 72 * s)
        ..cubicTo(54 * s, 72 * s, 48 * s, 70 * s, 43 * s, 66 * s)
        ..close();
      canvas.drawPath(visor, soft);
      canvas.drawPath(visor, stroke);
      canvas.drawLine(Offset(60 * s, 24 * s), Offset(60 * s, 33 * s), stroke);
    }
  }

  @override
  bool shouldRepaint(covariant _HeroPainter old) =>
      old.name != name || old.accent != accent || old.accent2 != accent2;
}

import 'package:flutter/material.dart';

/// La marque EventHub, tracée trait après trait.
///
/// Un **billet** avec sa perforation, et trois étincelles qui jaillissent
/// au-dessus. Le sujet devait dire « événement » en un coup d’œil et tenir à
/// 30 px : une silhouette de billet y parvient, un calendrier non (il se lit
/// « agenda »), et une note de musique exclurait les conférences et le sport.
///
/// L’apparition est un véritable tracé de chemin — `PathMetric.extractPath`
/// sur une fraction animée, l’équivalent Flutter du `stroke-dashoffset` de
/// SVG. Ce n’est pas décoratif : un écran de démarrage qui se dessine
/// lui-même dit à l’utilisateur que l’application travaille, là où un logo
/// statique a simplement l’air figé.
class EventMark extends StatelessWidget {
  const EventMark({
    required this.progress,
    required this.stroke,
    required this.accent,
    super.key,
    this.size = 150,
    this.strokeWidth = 5,
  });

  /// 0 → rien de tracé, 1 → entièrement tracé.
  final Animation<double> progress;
  final Color stroke;
  final Color accent;
  final double size;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: progress,
          builder: (context, _) => CustomPaint(
            painter: _EventMarkPainter(
              t: progress.value,
              stroke: stroke,
              accent: accent,
              strokeWidth: strokeWidth,
            ),
          ),
        ),
      ),
    );
  }
}

class _EventMarkPainter extends CustomPainter {
  _EventMarkPainter({
    required this.t,
    required this.stroke,
    required this.accent,
    required this.strokeWidth,
  });

  final double t;
  final Color stroke;
  final Color accent;
  final double strokeWidth;

  /// La marque est dessinée sur une grille de 200 × 200, puis mise à
  /// l’échelle du widget.
  static const _grid = 200.0;

  /// Chaque élément se trace dans sa propre tranche de la timeline, pour que
  /// la marque s’assemble dans un ordre lisible au lieu d’apparaître en fondu
  /// comme une seule tache.
  static const _ticketSpan = (0.0, 0.46);
  static const _perforationSpan = (0.44, 0.58);
  static const _sparkSpans = [(0.54, 0.76), (0.66, 0.86), (0.76, 0.94)];
  static const _dotSpan = (0.9, 1.0);

  static double _phase((double, double) span, double t) =>
      ((t - span.$1) / (span.$2 - span.$1)).clamp(0.0, 1.0);

  /// Un billet : un rectangle arrondi dans lequel on a mordu sur chacun de
  /// ses grands côtés.
  static Path _ticket() {
    final body = Path()
      ..addRRect(RRect.fromLTRBR(34, 80, 166, 158, const Radius.circular(12)));
    Path notch(double dx) =>
        Path()..addOval(Rect.fromCircle(center: Offset(dx, 119), radius: 9));

    return Path.combine(
      PathOperation.difference,
      Path.combine(PathOperation.difference, body, notch(34)),
      notch(166),
    );
  }

  static Path _perforation() => Path()
    ..moveTo(114, 92)
    ..lineTo(114, 146);

  /// Étoile à quatre branches — la forme vers laquelle convergent les
  /// confettis et les glyphes « sparkle ».
  static Path _spark(Offset c, double r) {
    final inner = r * 0.34;
    return Path()
      ..moveTo(c.dx, c.dy - r)
      ..quadraticBezierTo(c.dx + inner, c.dy - inner, c.dx + r, c.dy)
      ..quadraticBezierTo(c.dx + inner, c.dy + inner, c.dx, c.dy + r)
      ..quadraticBezierTo(c.dx - inner, c.dy + inner, c.dx - r, c.dy)
      ..quadraticBezierTo(c.dx - inner, c.dy - inner, c.dx, c.dy - r)
      ..close();
  }

  void _drawPartial(Canvas canvas, Path path, Paint paint, double phase) {
    if (phase <= 0) return;
    if (phase >= 1) {
      canvas.drawPath(path, paint);
      return;
    }
    for (final metric in path.computeMetrics()) {
      canvas.drawPath(metric.extractPath(0, metric.length * phase), paint);
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / _grid;
    canvas
      ..save()
      ..scale(scale);

    Paint pen(Color color) => Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth / scale
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    _drawPartial(canvas, _ticket(), pen(stroke), _phase(_ticketSpan, t));
    _drawPartial(
      canvas,
      _perforation(),
      pen(stroke),
      _phase(_perforationSpan, t),
    );

    const sparks = [
      (Offset(100, 46), 22.0),
      (Offset(148, 62), 13.0),
      (Offset(56, 64), 10.0),
    ];
    for (var i = 0; i < sparks.length; i++) {
      _drawPartial(
        canvas,
        _spark(sparks[i].$1, sparks[i].$2),
        pen(accent),
        _phase(_sparkSpans[i], t),
      );
    }

    // Le point final se pose avec un léger dépassement — l’unique fioriture.
    final dot = _phase(_dotSpan, t);
    if (dot > 0) {
      canvas.drawCircle(
        const Offset(166, 40),
        5.5 * Curves.easeOutBack.transform(dot),
        Paint()..color = accent,
      );
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(_EventMarkPainter old) =>
      old.t != t || old.stroke != stroke || old.accent != accent;
}

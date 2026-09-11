import 'package:flutter/material.dart';

/// The EventHub mark, drawn stroke by stroke.
///
/// A **ticket** with its perforation, and three sparks going off above it.
/// The subject had to say "événement" at a glance and survive at 30 px: a
/// ticket silhouette does that, a calendar does not (it reads "agenda"), and
/// a musical note would exclude conferences and sport.
///
/// The reveal is a genuine path trace — `PathMetric.extractPath` over an
/// animated fraction, the Flutter equivalent of SVG `stroke-dashoffset`. It
/// is not decoration: a boot screen that draws itself tells the user the app
/// is working, where a static logo just looks frozen.
class EventMark extends StatelessWidget {
  const EventMark({
    required this.progress,
    required this.stroke,
    required this.accent,
    super.key,
    this.size = 150,
    this.strokeWidth = 5,
  });

  /// 0 → nothing drawn, 1 → fully drawn.
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

  /// The mark is authored on a 200 × 200 grid and scaled to the widget.
  static const _grid = 200.0;

  /// Each element draws inside its own slice of the timeline, so the mark
  /// assembles in a readable order instead of fading in as one blob.
  static const _ticketSpan = (0.0, 0.46);
  static const _perforationSpan = (0.44, 0.58);
  static const _sparkSpans = [(0.54, 0.76), (0.66, 0.86), (0.76, 0.94)];
  static const _dotSpan = (0.9, 1.0);

  static double _phase((double, double) span, double t) =>
      ((t - span.$1) / (span.$2 - span.$1)).clamp(0.0, 1.0);

  /// A ticket: a rounded rectangle with a bite taken out of each long edge.
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

  /// Four-point star — the shape confetti and "sparkle" glyphs converge on.
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

    // The final dot lands with a small overshoot — the one flourish.
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

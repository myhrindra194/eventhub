import 'package:flutter/material.dart';

class ChevronBackground extends StatefulWidget {
  final Widget child;

  const ChevronBackground({super.key, required this.child});

  @override
  State<ChevronBackground> createState() => _ChevronBackgroundState();
}

class _ChevronBackgroundState extends State<ChevronBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _ChevronPainter(_controller),
      size: Size.infinite,
      child: widget.child,
    );
  }
}

class _ChevronPainter extends CustomPainter {
  _ChevronPainter(this.animation) : super(repaint: animation);

  final Animation<double> animation;
  static const _backgroundTop = Color(0xFF111318);
  static const _backgroundBottom = Color(0xFF0B0D10);
  static const _chevron = Color(0xFF241A3D);

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [_backgroundTop, _backgroundBottom],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, bgPaint);

    final chevronPaint = Paint()..color = _chevron.withValues(alpha: 0.82);

    final stripHeight = size.height / 3.4;
    final motion = Curves.easeInOut.transform(animation.value);
    final chevronDepth = size.width * (0.48 + motion * 0.08);
    final horizontalShift = size.width * (motion * 0.08);

    for (int i = -1; i < 4; i++) {
      final top = i * stripHeight - horizontalShift;
      final path = Path()
        ..moveTo(size.width, top)
        ..lineTo(chevronDepth, top + stripHeight / 2)
        ..lineTo(size.width, top + stripHeight)
        ..lineTo(size.width, top + stripHeight * 0.72)
        ..lineTo(chevronDepth + stripHeight * 0.22, top + stripHeight / 2)
        ..lineTo(size.width, top + stripHeight * 0.28)
        ..close();
      canvas.drawPath(path, chevronPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ChevronPainter oldDelegate) =>
      oldDelegate.animation.value != animation.value;
}
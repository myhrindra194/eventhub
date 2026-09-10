import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

enum BannerState { empty, error, success }

class DashedBanner extends StatelessWidget {
  final String title;
  final IconData icon;
  final BannerState state;
  final VoidCallback? onTap;

  const DashedBanner({
    super.key,
    required this.title,
    required this.icon,
    this.state = BannerState.empty,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isError = state == BannerState.error;
    final bool isSuccess = state == BannerState.success;

    // Select colors dynamically according to the state.
    final Color borderColor = isError
        ? AppColors.error
        : isSuccess
        ? AppColors.success
        : AppColors.darkSurfaceLight;

    final Color iconBg = isError
        ? AppColors.error.withValues(alpha: 0.15)
        : isSuccess
        ? AppColors.success.withValues(alpha: 0.15)
        : AppColors.darkSurfaceLight;

    final Color iconColor = isError
        ? AppColors.error
        : isSuccess
        ? AppColors.success
        : AppColors.darkTextSecondary;

    final Color textColor = isError
        ? AppColors.error
        : isSuccess
        ? AppColors.success
        : AppColors.darkTextSecondary;

    return GestureDetector(
      onTap: onTap,
      child: CustomPaint(
        painter: _DashedBorderPainter(
          color: borderColor,
          strokeWidth: 1.5,
          gap: 6,
        ),
        child: Container(
          width: double.infinity,
          height: 140,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.darkSurface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(height: 12),
              Text(
                title.toUpperCase(),
                style: TextStyle(
                  color: textColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;

  _DashedBorderPainter({
    required this.color,
    required this.strokeWidth,
    required this.gap,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final RRect rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(16),
    );

    final Path path = Path()..addRRect(rrect);
    final Path dashPath = Path();

    for (final PathMetric metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        dashPath.addPath(
          metric.extractPath(distance, distance + gap),
          Offset.zero,
        );
        distance += gap * 2;
      }
    }
    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.gap != gap;
  }
}

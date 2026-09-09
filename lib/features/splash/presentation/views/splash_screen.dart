import 'package:flutter/material.dart';
import 'dart:math' as math;

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  late final Animation<double> _cardScale;
  late final Animation<double> _whiteLogoOpacity;
  late final Animation<Offset> _textSlide;
  late final Animation<double> _textOpacity;

  // Durée volontairement plus longue et lisible
  static const _totalDuration = Duration(milliseconds: 3500);
  static const _purple = Color(0xFF7C4DFF);

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(vsync: this, duration: _totalDuration);

    _cardScale = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.25, curve: Curves.easeOutBack),
      ),
    );

    _whiteLogoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.48, 0.60, curve: Curves.easeIn),
      ),
    );

    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.68, 0.95, curve: Curves.easeOutCubic),
      ),
    );
    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.68, 0.95, curve: Curves.easeOut),
      ),
    );

    _controller.forward();

    Future.delayed(_totalDuration + const Duration(milliseconds: 400), () {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/welcome');
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _asset(String path, {double? width, double? height, BoxFit fit = BoxFit.contain}) {
    return Image.asset(
      path,
      width: width,
      height: height,
      fit: fit,
      // Si l'asset ne charge pas, on le voit tout de suite au lieu
      // d'un espace vide silencieux — retirez ce errorBuilder une
      // fois que tout s'affiche correctement.
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: width,
          height: height,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.red, width: 2),
          ),
          child: const Icon(Icons.broken_image, color: Colors.red),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111318),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;
          final logoSize = math.min(width * 0.48, 220.0);
          final brandFontSize = math.min(width * 0.085, 34.0);

          return AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Stack(
                fit: StackFit.expand,
                children: [
                  Center(
                    child: Transform.translate(
                      offset: Offset(0, height * 0.01),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          FadeTransition(
                            opacity: _whiteLogoOpacity,
                            child: ScaleTransition(
                              scale: _cardScale,
                              child: _asset(
                                'assets/images/logoblanc.png',
                                width: logoSize,
                                height: logoSize,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          FadeTransition(
                            opacity: _textOpacity,
                            child: SlideTransition(
                              position: _textSlide,
                              child: Text(
                                'EventHub',
                                style: TextStyle(
                                  fontSize: brandFontSize,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  height: 1,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          FadeTransition(
                            opacity: _textOpacity,
                            child: Container(
                              width: 36,
                              height: 3,
                              decoration: BoxDecoration(
                                color: _purple,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 40,
                    child: FadeTransition(
                      opacity: _textOpacity,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.circle_outlined, color: Colors.white38, size: 19),
                          const SizedBox(width: 10),
                          Text(
                            'PREMIUM EXPERIENCES',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.28),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 2.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
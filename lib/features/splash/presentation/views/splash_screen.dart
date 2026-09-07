import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../../../core/theme/app_colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  late final Animation<double> _cardAppear;
  late final Animation<double> _cardScale;
  late final Animation<double> _glowRadius;
  late final Animation<double> _glowOpacity;
  late final Animation<double> _floodScale;
  late final Animation<double> _cardFade;
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

    _cardAppear = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.20, curve: Curves.easeOut),
    );
    _cardScale = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.25, curve: Curves.easeOutBack),
      ),
    );

    _glowRadius = Tween<double>(begin: 0.0, end: 90.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.18, 0.45, curve: Curves.easeOut),
      ),
    );
    _glowOpacity = Tween<double>(begin: 0.0, end: 0.55).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.18, 0.38, curve: Curves.easeOut),
      ),
    );

    _floodScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.42, 0.68, curve: Curves.easeInCubic),
      ),
    );
    _cardFade = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.42, 0.55, curve: Curves.easeIn),
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
      backgroundColor: AppColors.lightBackground,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;
          final shortestSide = math.min(width, height);

          final logoBoxSize = math.min(shortestSide * 0.32, 170.0);
          final cardSize = logoBoxSize * 0.68;
          final glowSize = logoBoxSize * 0.75;
          final whiteLogoSize = logoBoxSize * 0.62;
          final brandFontSize = math.min(width * 0.085, 36.0);

          const baseDiameter = 40.0;
          final diagonal = math.sqrt(width * width + height * height);
          final maxScale = (diagonal / baseDiameter) * 1.3;

          return AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Stack(
                fit: StackFit.expand,
                alignment: Alignment.center,
                children: [
                  Transform.scale(
                    scale: 1 + (_floodScale.value * (maxScale - 1)),
                    child: Container(
                      width: baseDiameter,
                      height: baseDiameter,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF9C8CFF), _purple],
                        ),
                      ),
                    ),
                  ),
                  Center(
                    child: SizedBox(
                      width: logoBoxSize,
                      height: logoBoxSize,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Opacity(
                            opacity: _glowOpacity.value,
                            child: Container(
                              width: glowSize,
                              height: glowSize,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: _purple.withValues(alpha: 0.9),
                                    blurRadius: _glowRadius.value,
                                    spreadRadius: _glowRadius.value * 0.6,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Opacity(
                            opacity: _cardAppear.value * _cardFade.value,
                            child: Transform.scale(
                              scale: _cardScale.value,
                              child: Container(
                                width: cardSize,
                                height: cardSize,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(cardSize * 0.2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.08),
                                      blurRadius: 16,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                padding: EdgeInsets.all(cardSize * 0.16),
                                child: _asset('assets/images/logoev.png'),
                              ),
                            ),
                          ),
                          Opacity(
                            opacity: _whiteLogoOpacity.value,
                            child: _asset(
                              'assets/images/logoblanc.png',
                              width: whiteLogoSize,
                              height: whiteLogoSize,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.center,
                    child: Transform.translate(
                      offset: Offset(0, logoBoxSize * 0.62),
                      child: Opacity(
                        opacity: _textOpacity.value,
                        child: SlideTransition(
                          position: _textSlide,
                          child: Text(
                            'EventHub',
                            style: TextStyle(
                              fontSize: brandFontSize,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
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
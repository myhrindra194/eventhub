import 'package:eventhub/app/theme/theme.dart';
import 'package:eventhub/core/l10n/app_strings.dart';
import 'package:eventhub/core/widgets/design_system.dart';
import 'package:eventhub/features/auth/presentation/widgets/event_mark.dart';
import 'package:flutter/material.dart';

/// Boot screen.
///
/// Purely presentational: it is shown while the session stream and the
/// onboarding flag resolve, and the router's guard decides when to leave it.
///
/// The mark draws itself — ticket, perforation, then three sparks — while a
/// progress bar fills underneath. Both are honest about the same thing: the
/// app is starting. A static logo on a cold start reads as a freeze.
///
/// **No appearance toggle here.** A startup screen is not a settings surface:
/// it follows the system, and the override lives in Settings, where a user
/// actually goes looking for it.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  );

  late final Animation<double> _draw = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0, 0.82, curve: Curves.easeInOut),
  );

  late final Animation<double> _text = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.72, 1, curve: AppMotion.decelerate),
  );

  late final Animation<double> _bar = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.05, 1, curve: Curves.easeInOut),
  );

  @override
  void initState() {
    super.initState();
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;

    // Respect the OS "reduce motion" setting: show the finished mark rather
    // than tracing it.
    if (MediaQuery.disableAnimationsOf(context) && !_controller.isCompleted) {
      _controller.value = 1;
    }

    return AppScaffold(
      showBlooms: false,
      constrainWidth: false,
      body: SafeArea(
        child: ResponsiveColumn(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: context.gutter),
            child: Column(
              children: [
                const Spacer(flex: 3),
                EventMark(
                  progress: _draw,
                  stroke: t.textPrimary,
                  accent: t.accent,
                  size: context.responsive(
                    medium: 150,
                    small: 116,
                    expanded: 184,
                  ),
                  strokeWidth: context.responsive(medium: 5, small: 4),
                ),
                SizedBox(height: context.responsive(medium: 28, small: 20)),
                FadeTransition(
                  opacity: _text,
                  child: SlideTransition(
                    position: Tween(
                      begin: const Offset(0, 0.35),
                      end: Offset.zero,
                    ).animate(_text),
                    child: Column(
                      children: [
                        Text.rich(
                          TextSpan(
                            children: [
                              const TextSpan(text: 'Event'),
                              TextSpan(
                                text: 'Hub',
                                style: TextStyle(color: t.brand),
                              ),
                            ],
                          ),
                          style: text.displaySmall?.copyWith(
                            fontSize: context.responsive(
                              medium: 34,
                              small: 28,
                              expanded: 40,
                            ),
                            letterSpacing: -1,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          AppStrings.splashTagline,
                          textAlign: TextAlign.center,
                          style: text.bodyLarge?.copyWith(
                            color: t.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(flex: 4),
                _BootBar(progress: _bar),
                SizedBox(height: context.responsive(medium: 48, small: 32)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Thin determinate bar plus a caption. Determinate on purpose: a spinner
/// says "something is happening", a bar says "it is nearly done".
class _BootBar extends StatelessWidget {
  const _BootBar({required this.progress});

  final Animation<double> progress;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;

    return Column(
      children: [
        ClipRRect(
          borderRadius: AppRadius.brPill,
          child: AnimatedBuilder(
            animation: progress,
            builder: (context, _) => LinearProgressIndicator(
              // Never starts at zero and never claims to reach the end: the
              // real work is a network round-trip we cannot measure.
              value: 0.08 + progress.value * 0.7,
              minHeight: 4,
              backgroundColor: t.surfaceSunken,
              color: t.brand,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          AppStrings.splashLoading,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: t.textSecondary),
        ),
      ],
    );
  }
}

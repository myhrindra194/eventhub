import 'package:eventhub/app/theme/theme.dart';
import 'package:eventhub/core/config/app_config.dart';
import 'package:eventhub/routes/routes.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Application root.
///
/// Responsibilities, and nothing else: wire the router, hand both themes to
/// Material and let the user's preference (or the OS) pick between them,
/// declare the supported locales, and clamp text scaling.
class EventHubApp extends ConsumerWidget {
  const EventHubApp({super.key});

  /// Accessibility text scaling is honoured but bounded: past ~1.35 the
  /// dense cards of the feed break apart. Clamping is the honest trade-off
  /// — the alternative is ignoring the setting entirely.
  static const _minTextScale = 0.85;
  static const _maxTextScale = 1.35;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(appConfigProvider);
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeControllerProvider);

    return MaterialApp.router(
      title: config.appName,

      // The debug ribbon is off in every flavour: it sits exactly where the
      // top-right action of most screens is, and it makes screenshots and
      // demos look unfinished.
      debugShowCheckedModeBanner: false,

      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      themeAnimationDuration: AppTheme.themeSwitchDuration,
      themeAnimationCurve: AppMotion.standard,

      routerConfig: router,

      locale: const Locale('fr', 'FR'),
      supportedLocales: const [Locale('fr', 'FR'), Locale('en', 'US')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      scrollBehavior: const _AppScrollBehavior(),

      builder: (context, child) {
        final media = MediaQuery.of(context);
        return MediaQuery(
          data: media.copyWith(
            textScaler: media.textScaler.clamp(
              minScaleFactor: _minTextScale,
              maxScaleFactor: _maxTextScale,
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}

/// Lets the app be dragged with a mouse or a stylus (desktop, web previews)
/// and keeps the iOS bouncing physics on every platform, which is what
/// makes the immersive feed feel right.
class _AppScrollBehavior extends MaterialScrollBehavior {
  const _AppScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => const {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
    PointerDeviceKind.stylus,
  };

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) =>
      const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics());
}

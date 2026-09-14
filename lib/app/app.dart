import 'dart:async';

import 'package:eventhub/app/theme/theme.dart';
import 'package:eventhub/core/analytics/analytics_consent.dart';
import 'package:eventhub/core/analytics/app_analytics.dart';
import 'package:eventhub/core/config/app_config.dart';
import 'package:eventhub/core/widgets/analytics_consent_sheet.dart';
import 'package:eventhub/core/widgets/offline_aware.dart';
import 'package:eventhub/features/auth/application/auth_providers.dart';
import 'package:eventhub/features/auth/domain/entities/app_user.dart';
import 'package:eventhub/features/notifications/application/notification_providers.dart';
import 'package:eventhub/routes/routes.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Application root.
///
/// Responsibilities, and nothing else: wire the router, hand both themes to
/// Material and let the user's preference (or the OS) pick between them,
/// declare the supported locales, clamp text scaling — and start the
/// app-wide services that follow the session (push notifications, analytics
/// identity and consent, the offline band).
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
    // Starts the push pipeline (token registration follows the session).
    ref.watch(pushNotificationsProvider);

    ref
      // Subscribing instantiates the consent provider at startup; its build
      // applies the stored decision to Firebase Analytics.
      ..listen<AsyncValue<bool?>>(analyticsConsentProvider, (_, __) {})
      ..listen<AppUser?>(currentUserProvider, (previous, user) {
        ref
            .read(appAnalyticsProvider)
            .identify(userId: user?.id, role: user?.role.name);
        if (user != null && previous == null) unawaited(_askConsentOnce(ref));
      });

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
          child: OfflineAware(child: child ?? const SizedBox.shrink()),
        );
      },
    );
  }

  /// Offers the consent sheet after the first sign-in of the session, once
  /// the home screen is on screen, and only if the question was never
  /// answered on this install.
  static Future<void> _askConsentOnce(WidgetRef ref) async {
    final consent = await ref.read(analyticsConsentProvider.future);
    if (consent != null) return;
    await Future<void>.delayed(const Duration(milliseconds: 900));
    final context = rootNavigatorKey.currentContext;
    if (context == null || !context.mounted) return;
    await showAnalyticsConsentSheet(context);
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

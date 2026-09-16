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

/// Racine de l’application.
///
/// Ses responsabilités, et rien d’autre : brancher le routeur, confier les
/// deux thèmes à Material en laissant la préférence de l’utilisateur (ou
/// celle de l’OS) trancher entre eux, déclarer les locales supportées,
/// borner la mise à l’échelle du texte — et démarrer les services globaux
/// qui suivent la session (notifications push, identité et consentement
/// analytics, le bandeau hors ligne).
class EventHubApp extends ConsumerWidget {
  const EventHubApp({super.key});

  /// La mise à l’échelle du texte demandée par l’accessibilité est
  /// respectée, mais bornée : au-delà de ~1.35 les cartes denses du fil
  /// se disloquent. Le clamp est le compromis honnête — l’alternative
  /// serait d’ignorer purement et simplement le réglage.
  static const _minTextScale = 0.85;
  static const _maxTextScale = 1.35;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(appConfigProvider);
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeControllerProvider);
    // Démarre le pipeline push (l’enregistrement du token suit la session).
    ref.watch(pushNotificationsProvider);

    ref
      // S’abonner instancie le provider de consentement au démarrage ; son
      // build applique la décision stockée à Firebase Analytics.
      ..listen<AsyncValue<bool?>>(analyticsConsentProvider, (_, __) {})
      // Un lien de réinitialisation a ouvert l’app en session de récupération.
      ..listen<AsyncValue<void>>(passwordRecoveryProvider, (_, next) {
        if (next is AsyncData<void>) {
          router.go('${AppRoutes.changePassword}?recovery=1');
        }
      })
      ..listen<AppUser?>(currentUserProvider, (previous, user) {
        ref
            .read(appAnalyticsProvider)
            .identify(userId: user?.id, role: user?.role.name);
        if (user != null && previous == null) unawaited(_askConsentOnce(ref));
      });

    return MaterialApp.router(
      title: config.appName,

      // Le ruban de debug est coupé dans toutes les saveurs : il se place
      // pile où se trouve l’action en haut à droite de la plupart des
      // écrans, et il donne aux captures et aux démos un air inachevé.
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

  /// Propose la feuille de consentement après la première connexion de la
  /// session, une fois l’écran d’accueil affiché, et uniquement si la
  /// question n’a jamais reçu de réponse sur cette installation.
  static Future<void> _askConsentOnce(WidgetRef ref) async {
    final consent = await ref.read(analyticsConsentProvider.future);
    if (consent != null) return;
    await Future<void>.delayed(const Duration(milliseconds: 900));
    final context = rootNavigatorKey.currentContext;
    if (context == null || !context.mounted) return;
    await showAnalyticsConsentSheet(context);
  }
}

/// Permet de faire défiler l’app à la souris ou au stylet (desktop,
/// aperçus web) et conserve la physique rebondissante iOS sur toutes les
/// plateformes : c’est elle qui donne au fil immersif la bonne sensation.
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

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'analytics_consent.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// La décision de l’utilisateur sur la mesure d’audience, pour cette
/// installation.
///
/// `null` signifie « jamais demandé » : rien n’est collecté et la feuille de
/// consentement est proposée une fois après la connexion. Le choix est
/// stocké localement parce qu’il relève de l’appareil (le même compte sur
/// une tablette partagée peut trancher autrement). Firebase Analytics n’est
/// pas exempté de consentement au regard des lignes directrices de la CNIL,
/// d’où un opt-in plutôt qu’un opt-out.

@ProviderFor(AnalyticsConsent)
final analyticsConsentProvider = AnalyticsConsentProvider._();

/// La décision de l’utilisateur sur la mesure d’audience, pour cette
/// installation.
///
/// `null` signifie « jamais demandé » : rien n’est collecté et la feuille de
/// consentement est proposée une fois après la connexion. Le choix est
/// stocké localement parce qu’il relève de l’appareil (le même compte sur
/// une tablette partagée peut trancher autrement). Firebase Analytics n’est
/// pas exempté de consentement au regard des lignes directrices de la CNIL,
/// d’où un opt-in plutôt qu’un opt-out.
final class AnalyticsConsentProvider
    extends $AsyncNotifierProvider<AnalyticsConsent, bool?> {
  /// La décision de l’utilisateur sur la mesure d’audience, pour cette
  /// installation.
  ///
  /// `null` signifie « jamais demandé » : rien n’est collecté et la feuille de
  /// consentement est proposée une fois après la connexion. Le choix est
  /// stocké localement parce qu’il relève de l’appareil (le même compte sur
  /// une tablette partagée peut trancher autrement). Firebase Analytics n’est
  /// pas exempté de consentement au regard des lignes directrices de la CNIL,
  /// d’où un opt-in plutôt qu’un opt-out.
  AnalyticsConsentProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'analyticsConsentProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$analyticsConsentHash();

  @$internal
  @override
  AnalyticsConsent create() => AnalyticsConsent();
}

String _$analyticsConsentHash() => r'b0a894a07b4c0748ec065c42926a8bc8743c5fff';

/// La décision de l’utilisateur sur la mesure d’audience, pour cette
/// installation.
///
/// `null` signifie « jamais demandé » : rien n’est collecté et la feuille de
/// consentement est proposée une fois après la connexion. Le choix est
/// stocké localement parce qu’il relève de l’appareil (le même compte sur
/// une tablette partagée peut trancher autrement). Firebase Analytics n’est
/// pas exempté de consentement au regard des lignes directrices de la CNIL,
/// d’où un opt-in plutôt qu’un opt-out.

abstract class _$AnalyticsConsent extends $AsyncNotifier<bool?> {
  FutureOr<bool?> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<bool?>, bool?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<bool?>, bool?>,
              AsyncValue<bool?>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

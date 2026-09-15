// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'analytics_consent.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The user's decision about audience measurement on this install.
///
/// `null` means "never asked": nothing is collected and the consent sheet is
/// offered once after sign-in. Stored locally because it is a device-level
/// choice (the same account on a shared tablet may decide differently).
/// Firebase Analytics is not exempt from consent under the CNIL guidelines,
/// hence opt-in rather than opt-out.

@ProviderFor(AnalyticsConsent)
final analyticsConsentProvider = AnalyticsConsentProvider._();

/// The user's decision about audience measurement on this install.
///
/// `null` means "never asked": nothing is collected and the consent sheet is
/// offered once after sign-in. Stored locally because it is a device-level
/// choice (the same account on a shared tablet may decide differently).
/// Firebase Analytics is not exempt from consent under the CNIL guidelines,
/// hence opt-in rather than opt-out.
final class AnalyticsConsentProvider
    extends $AsyncNotifierProvider<AnalyticsConsent, bool?> {
  /// The user's decision about audience measurement on this install.
  ///
  /// `null` means "never asked": nothing is collected and the consent sheet is
  /// offered once after sign-in. Stored locally because it is a device-level
  /// choice (the same account on a shared tablet may decide differently).
  /// Firebase Analytics is not exempt from consent under the CNIL guidelines,
  /// hence opt-in rather than opt-out.
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

/// The user's decision about audience measurement on this install.
///
/// `null` means "never asked": nothing is collected and the consent sheet is
/// offered once after sign-in. Stored locally because it is a device-level
/// choice (the same account on a shared tablet may decide differently).
/// Firebase Analytics is not exempt from consent under the CNIL guidelines,
/// hence opt-in rather than opt-out.

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

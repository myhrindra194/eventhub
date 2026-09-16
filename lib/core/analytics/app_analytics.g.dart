// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_analytics.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(appAnalytics)
final appAnalyticsProvider = AppAnalyticsProvider._();

final class AppAnalyticsProvider
    extends $FunctionalProvider<AppAnalytics, AppAnalytics, AppAnalytics>
    with $Provider<AppAnalytics> {
  AppAnalyticsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appAnalyticsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appAnalyticsHash();

  @$internal
  @override
  $ProviderElement<AppAnalytics> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AppAnalytics create(Ref ref) {
    return appAnalytics(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppAnalytics value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppAnalytics>(value),
    );
  }
}

String _$appAnalyticsHash() => r'928b2d519ec69a1bfc46af85435ed7990042682d';

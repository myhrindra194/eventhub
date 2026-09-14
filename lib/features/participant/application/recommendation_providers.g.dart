// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recommendation_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// "Pour vous" (F-18). Empty until the catalogue is loaded, and for
/// organizers — they do not book.

@ProviderFor(recommendedEvents)
final recommendedEventsProvider = RecommendedEventsProvider._();

/// "Pour vous" (F-18). Empty until the catalogue is loaded, and for
/// organizers — they do not book.

final class RecommendedEventsProvider
    extends
        $FunctionalProvider<
          List<Recommendation>,
          List<Recommendation>,
          List<Recommendation>
        >
    with $Provider<List<Recommendation>> {
  /// "Pour vous" (F-18). Empty until the catalogue is loaded, and for
  /// organizers — they do not book.
  RecommendedEventsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'recommendedEventsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$recommendedEventsHash();

  @$internal
  @override
  $ProviderElement<List<Recommendation>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  List<Recommendation> create(Ref ref) {
    return recommendedEvents(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<Recommendation> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<Recommendation>>(value),
    );
  }
}

String _$recommendedEventsHash() => r'f6c1e830751472e7dd511f4870e122becc03575a';

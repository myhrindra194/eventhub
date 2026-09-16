// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'review_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(reviewRepository)
final reviewRepositoryProvider = ReviewRepositoryProvider._();

final class ReviewRepositoryProvider
    extends
        $FunctionalProvider<
          ReviewRepository,
          ReviewRepository,
          ReviewRepository
        >
    with $Provider<ReviewRepository> {
  ReviewRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'reviewRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$reviewRepositoryHash();

  @$internal
  @override
  $ProviderElement<ReviewRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ReviewRepository create(Ref ref) {
    return reviewRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ReviewRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ReviewRepository>(value),
    );
  }
}

String _$reviewRepositoryHash() => r'de983f103b00483b075fc83454fe8e9ab07e9227';

@ProviderFor(eventReviews)
final eventReviewsProvider = EventReviewsFamily._();

final class EventReviewsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Review>>,
          List<Review>,
          Stream<List<Review>>
        >
    with $FutureModifier<List<Review>>, $StreamProvider<List<Review>> {
  EventReviewsProvider._({
    required EventReviewsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'eventReviewsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$eventReviewsHash();

  @override
  String toString() {
    return r'eventReviewsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<Review>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<Review>> create(Ref ref) {
    final argument = this.argument as String;
    return eventReviews(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is EventReviewsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$eventReviewsHash() => r'9ab878d26e4e57d5aeda84de6736a947d00b3bc5';

final class EventReviewsFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<Review>>, String> {
  EventReviewsFamily._()
    : super(
        retry: null,
        name: r'eventReviewsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  EventReviewsProvider call(String eventId) =>
      EventReviewsProvider._(argument: eventId, from: this);

  @override
  String toString() => r'eventReviewsProvider';
}

@ProviderFor(myReview)
final myReviewProvider = MyReviewFamily._();

final class MyReviewProvider
    extends $FunctionalProvider<AsyncValue<Review?>, Review?, Stream<Review?>>
    with $FutureModifier<Review?>, $StreamProvider<Review?> {
  MyReviewProvider._({
    required MyReviewFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'myReviewProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$myReviewHash();

  @override
  String toString() {
    return r'myReviewProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<Review?> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<Review?> create(Ref ref) {
    final argument = this.argument as String;
    return myReview(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is MyReviewProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$myReviewHash() => r'f8acafcc8f2805252869391cab0b9c80eb5e5696';

final class MyReviewFamily extends $Family
    with $FunctionalFamilyOverride<Stream<Review?>, String> {
  MyReviewFamily._()
    : super(
        retry: null,
        name: r'myReviewProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  MyReviewProvider call(String eventId) =>
      MyReviewProvider._(argument: eventId, from: this);

  @override
  String toString() => r'myReviewProvider';
}

/// Indique si l’utilisateur connecté peut donner un avis sur [eventId]
/// maintenant.

@ProviderFor(canReviewEvent)
final canReviewEventProvider = CanReviewEventFamily._();

/// Indique si l’utilisateur connecté peut donner un avis sur [eventId]
/// maintenant.

final class CanReviewEventProvider extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  /// Indique si l’utilisateur connecté peut donner un avis sur [eventId]
  /// maintenant.
  CanReviewEventProvider._({
    required CanReviewEventFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'canReviewEventProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$canReviewEventHash();

  @override
  String toString() {
    return r'canReviewEventProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    final argument = this.argument as String;
    return canReviewEvent(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is CanReviewEventProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$canReviewEventHash() => r'6b92f70cc8b01379faf3c8adaac8594615dc6f23';

/// Indique si l’utilisateur connecté peut donner un avis sur [eventId]
/// maintenant.

final class CanReviewEventFamily extends $Family
    with $FunctionalFamilyOverride<bool, String> {
  CanReviewEventFamily._()
    : super(
        retry: null,
        name: r'canReviewEventProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Indique si l’utilisateur connecté peut donner un avis sur [eventId]
  /// maintenant.

  CanReviewEventProvider call(String eventId) =>
      CanReviewEventProvider._(argument: eventId, from: this);

  @override
  String toString() => r'canReviewEventProvider';
}

/// Vrai quand seule l'adresse non confirmée empêche de laisser un avis : la
/// fiche affiche alors le bandeau qui envoie le lien, au lieu de masquer le
/// bouton sans explication.

@ProviderFor(reviewBlockedByVerification)
final reviewBlockedByVerificationProvider =
    ReviewBlockedByVerificationFamily._();

/// Vrai quand seule l'adresse non confirmée empêche de laisser un avis : la
/// fiche affiche alors le bandeau qui envoie le lien, au lieu de masquer le
/// bouton sans explication.

final class ReviewBlockedByVerificationProvider
    extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  /// Vrai quand seule l'adresse non confirmée empêche de laisser un avis : la
  /// fiche affiche alors le bandeau qui envoie le lien, au lieu de masquer le
  /// bouton sans explication.
  ReviewBlockedByVerificationProvider._({
    required ReviewBlockedByVerificationFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'reviewBlockedByVerificationProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$reviewBlockedByVerificationHash();

  @override
  String toString() {
    return r'reviewBlockedByVerificationProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    final argument = this.argument as String;
    return reviewBlockedByVerification(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ReviewBlockedByVerificationProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$reviewBlockedByVerificationHash() =>
    r'5fc3f6f1d83c71b05f7341fd18c6d1e7f70ae045';

/// Vrai quand seule l'adresse non confirmée empêche de laisser un avis : la
/// fiche affiche alors le bandeau qui envoie le lien, au lieu de masquer le
/// bouton sans explication.

final class ReviewBlockedByVerificationFamily extends $Family
    with $FunctionalFamilyOverride<bool, String> {
  ReviewBlockedByVerificationFamily._()
    : super(
        retry: null,
        name: r'reviewBlockedByVerificationProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Vrai quand seule l'adresse non confirmée empêche de laisser un avis : la
  /// fiche affiche alors le bandeau qui envoie le lien, au lieu de masquer le
  /// bouton sans explication.

  ReviewBlockedByVerificationProvider call(String eventId) =>
      ReviewBlockedByVerificationProvider._(argument: eventId, from: this);

  @override
  String toString() => r'reviewBlockedByVerificationProvider';
}

@ProviderFor(ReviewController)
final reviewControllerProvider = ReviewControllerProvider._();

final class ReviewControllerProvider
    extends $AsyncNotifierProvider<ReviewController, void> {
  ReviewControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'reviewControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$reviewControllerHash();

  @$internal
  @override
  ReviewController create() => ReviewController();
}

String _$reviewControllerHash() => r'ef793cd76d29be80b47e64aedfef234e786bd3ea';

abstract class _$ReviewController extends $AsyncNotifier<void> {
  FutureOr<void> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<void>, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<void>, void>,
              AsyncValue<void>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

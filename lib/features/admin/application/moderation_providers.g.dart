// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'moderation_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(moderationRepository)
final moderationRepositoryProvider = ModerationRepositoryProvider._();

final class ModerationRepositoryProvider
    extends
        $FunctionalProvider<
          ModerationRepository,
          ModerationRepository,
          ModerationRepository
        >
    with $Provider<ModerationRepository> {
  ModerationRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'moderationRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$moderationRepositoryHash();

  @$internal
  @override
  $ProviderElement<ModerationRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ModerationRepository create(Ref ref) {
    return moderationRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ModerationRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ModerationRepository>(value),
    );
  }
}

String _$moderationRepositoryHash() =>
    r'5cc14aa41d4c561b0c243f522df311502b8f5b56';

@ProviderFor(moderationQueue)
final moderationQueueProvider = ModerationQueueFamily._();

final class ModerationQueueProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ModerationEntry>>,
          List<ModerationEntry>,
          Stream<List<ModerationEntry>>
        >
    with
        $FutureModifier<List<ModerationEntry>>,
        $StreamProvider<List<ModerationEntry>> {
  ModerationQueueProvider._({
    required ModerationQueueFamily super.from,
    required bool super.argument,
  }) : super(
         retry: null,
         name: r'moderationQueueProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$moderationQueueHash();

  @override
  String toString() {
    return r'moderationQueueProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<ModerationEntry>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<ModerationEntry>> create(Ref ref) {
    final argument = this.argument as bool;
    return moderationQueue(ref, open: argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ModerationQueueProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$moderationQueueHash() => r'e5ed5ba45778a5765fd43e02831fdb800d982a49';

final class ModerationQueueFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<ModerationEntry>>, bool> {
  ModerationQueueFamily._()
    : super(
        retry: null,
        name: r'moderationQueueProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ModerationQueueProvider call({required bool open}) =>
      ModerationQueueProvider._(argument: open, from: this);

  @override
  String toString() => r'moderationQueueProvider';
}

/// Badge on the "Modération" menu entry.

@ProviderFor(openModerationCount)
final openModerationCountProvider = OpenModerationCountProvider._();

/// Badge on the "Modération" menu entry.

final class OpenModerationCountProvider
    extends $FunctionalProvider<int, int, int>
    with $Provider<int> {
  /// Badge on the "Modération" menu entry.
  OpenModerationCountProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'openModerationCountProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$openModerationCountHash();

  @$internal
  @override
  $ProviderElement<int> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  int create(Ref ref) {
    return openModerationCount(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$openModerationCountHash() =>
    r'1e7f4247fe80d26582690257ab1cc047f5a5ede3';

@ProviderFor(moderationEntry)
final moderationEntryProvider = ModerationEntryFamily._();

final class ModerationEntryProvider
    extends
        $FunctionalProvider<
          AsyncValue<ModerationEntry?>,
          ModerationEntry?,
          Stream<ModerationEntry?>
        >
    with $FutureModifier<ModerationEntry?>, $StreamProvider<ModerationEntry?> {
  ModerationEntryProvider._({
    required ModerationEntryFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'moderationEntryProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$moderationEntryHash();

  @override
  String toString() {
    return r'moderationEntryProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<ModerationEntry?> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<ModerationEntry?> create(Ref ref) {
    final argument = this.argument as String;
    return moderationEntry(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ModerationEntryProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$moderationEntryHash() => r'c1f0733c57988cbb4f4f9fbc03aa030d1bb3bec6';

final class ModerationEntryFamily extends $Family
    with $FunctionalFamilyOverride<Stream<ModerationEntry?>, String> {
  ModerationEntryFamily._()
    : super(
        retry: null,
        name: r'moderationEntryProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ModerationEntryProvider call(String entryId) =>
      ModerationEntryProvider._(argument: entryId, from: this);

  @override
  String toString() => r'moderationEntryProvider';
}

@ProviderFor(moderationReports)
final moderationReportsProvider = ModerationReportsFamily._();

final class ModerationReportsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ReportRecord>>,
          List<ReportRecord>,
          Stream<List<ReportRecord>>
        >
    with
        $FutureModifier<List<ReportRecord>>,
        $StreamProvider<List<ReportRecord>> {
  ModerationReportsProvider._({
    required ModerationReportsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'moderationReportsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$moderationReportsHash();

  @override
  String toString() {
    return r'moderationReportsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<ReportRecord>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<ReportRecord>> create(Ref ref) {
    final argument = this.argument as String;
    return moderationReports(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ModerationReportsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$moderationReportsHash() => r'3b745ac6960f4497ca5ffbe24c7c6305b0018d1a';

final class ModerationReportsFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<ReportRecord>>, String> {
  ModerationReportsFamily._()
    : super(
        retry: null,
        name: r'moderationReportsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ModerationReportsProvider call(String entryId) =>
      ModerationReportsProvider._(argument: entryId, from: this);

  @override
  String toString() => r'moderationReportsProvider';
}

@ProviderFor(moderationDecisions)
final moderationDecisionsProvider = ModerationDecisionsFamily._();

final class ModerationDecisionsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ModerationDecision>>,
          List<ModerationDecision>,
          Stream<List<ModerationDecision>>
        >
    with
        $FutureModifier<List<ModerationDecision>>,
        $StreamProvider<List<ModerationDecision>> {
  ModerationDecisionsProvider._({
    required ModerationDecisionsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'moderationDecisionsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$moderationDecisionsHash();

  @override
  String toString() {
    return r'moderationDecisionsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<ModerationDecision>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<ModerationDecision>> create(Ref ref) {
    final argument = this.argument as String;
    return moderationDecisions(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ModerationDecisionsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$moderationDecisionsHash() =>
    r'5ccb9d4688b63e3af6adf12604452a995553a47c';

final class ModerationDecisionsFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<ModerationDecision>>, String> {
  ModerationDecisionsFamily._()
    : super(
        retry: null,
        name: r'moderationDecisionsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ModerationDecisionsProvider call(String entryId) =>
      ModerationDecisionsProvider._(argument: entryId, from: this);

  @override
  String toString() => r'moderationDecisionsProvider';
}

@ProviderFor(reportedAccount)
final reportedAccountProvider = ReportedAccountFamily._();

final class ReportedAccountProvider
    extends
        $FunctionalProvider<
          AsyncValue<ReportedAccount?>,
          ReportedAccount?,
          Stream<ReportedAccount?>
        >
    with $FutureModifier<ReportedAccount?>, $StreamProvider<ReportedAccount?> {
  ReportedAccountProvider._({
    required ReportedAccountFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'reportedAccountProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$reportedAccountHash();

  @override
  String toString() {
    return r'reportedAccountProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<ReportedAccount?> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<ReportedAccount?> create(Ref ref) {
    final argument = this.argument as String;
    return reportedAccount(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ReportedAccountProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$reportedAccountHash() => r'61f906c79210c1ea58114927868b75b9d088f869';

final class ReportedAccountFamily extends $Family
    with $FunctionalFamilyOverride<Stream<ReportedAccount?>, String> {
  ReportedAccountFamily._()
    : super(
        retry: null,
        name: r'reportedAccountProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ReportedAccountProvider call(String userId) =>
      ReportedAccountProvider._(argument: userId, from: this);

  @override
  String toString() => r'reportedAccountProvider';
}

/// A reported review, hidden or not. Review ids are `<eventId>_<authorId>`;
/// uids never contain `_`, so the author is after the last one.

@ProviderFor(moderatedReview)
final moderatedReviewProvider = ModeratedReviewFamily._();

/// A reported review, hidden or not. Review ids are `<eventId>_<authorId>`;
/// uids never contain `_`, so the author is after the last one.

final class ModeratedReviewProvider
    extends $FunctionalProvider<AsyncValue<Review?>, Review?, Stream<Review?>>
    with $FutureModifier<Review?>, $StreamProvider<Review?> {
  /// A reported review, hidden or not. Review ids are `<eventId>_<authorId>`;
  /// uids never contain `_`, so the author is after the last one.
  ModeratedReviewProvider._({
    required ModeratedReviewFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'moderatedReviewProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$moderatedReviewHash();

  @override
  String toString() {
    return r'moderatedReviewProvider'
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
    return moderatedReview(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ModeratedReviewProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$moderatedReviewHash() => r'27b29f4ba93dd79fbd89576998cdf1a92fe82b34';

/// A reported review, hidden or not. Review ids are `<eventId>_<authorId>`;
/// uids never contain `_`, so the author is after the last one.

final class ModeratedReviewFamily extends $Family
    with $FunctionalFamilyOverride<Stream<Review?>, String> {
  ModeratedReviewFamily._()
    : super(
        retry: null,
        name: r'moderatedReviewProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// A reported review, hidden or not. Review ids are `<eventId>_<authorId>`;
  /// uids never contain `_`, so the author is after the last one.

  ModeratedReviewProvider call(String reviewId) =>
      ModeratedReviewProvider._(argument: reviewId, from: this);

  @override
  String toString() => r'moderatedReviewProvider';
}

@ProviderFor(adminAccounts)
final adminAccountsProvider = AdminAccountsProvider._();

final class AdminAccountsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<AdminAccount>>,
          List<AdminAccount>,
          Stream<List<AdminAccount>>
        >
    with
        $FutureModifier<List<AdminAccount>>,
        $StreamProvider<List<AdminAccount>> {
  AdminAccountsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'adminAccountsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$adminAccountsHash();

  @$internal
  @override
  $StreamProviderElement<List<AdminAccount>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<AdminAccount>> create(Ref ref) {
    return adminAccounts(ref);
  }
}

String _$adminAccountsHash() => r'e792d74d0d6514eb7cb6556d755f4c2d2429da5c';

@ProviderFor(ModerationController)
final moderationControllerProvider = ModerationControllerProvider._();

final class ModerationControllerProvider
    extends $AsyncNotifierProvider<ModerationController, void> {
  ModerationControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'moderationControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$moderationControllerHash();

  @$internal
  @override
  ModerationController create() => ModerationController();
}

String _$moderationControllerHash() =>
    r'2b8d257e069e0516bef2b40f69a35ef0c7368bc7';

abstract class _$ModerationController extends $AsyncNotifier<void> {
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

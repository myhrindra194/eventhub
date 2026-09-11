import 'package:eventhub/core/errors/failure.dart';

/// Carries a [Failure] across a boundary that can only propagate exceptions
/// (e.g. aborting a Firestore transaction). Repositories unwrap it back into
/// a `Result.err` through `guard()`.
class FailureException implements Exception {
  const FailureException(this.failure);

  final Failure failure;

  @override
  String toString() => 'FailureException(${failure.message})';
}

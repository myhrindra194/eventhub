import 'package:eventhub/core/errors/failure.dart';

/// Transporte une [Failure] à travers une frontière qui ne sait propager que
/// des exceptions (par exemple l’abandon d’une transaction Firestore). Les
/// repositories la redéballent en `Result.err` grâce à `guard()`.
class FailureException implements Exception {
  const FailureException(this.failure);

  final Failure failure;

  @override
  String toString() => 'FailureException(${failure.message})';
}

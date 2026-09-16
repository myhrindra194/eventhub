/// Hiérarchie d’erreurs typée et exhaustive.
///
/// Les repositories ne lèvent jamais : ils renvoient un `Result<T>` dont le
/// côté erreur est l’une de ces classes. L’UI les traduit en messages via
/// `failure.message` et peut discriminer le type concret avec un `switch`.
sealed class Failure {
  const Failure({required this.message, this.cause, this.stackTrace});

  /// Message lisible (en français), sûr à montrer à l’utilisateur.
  final String message;
  final Object? cause;
  final StackTrace? stackTrace;

  @override
  String toString() => '$runtimeType($message)';
}

enum AuthFailureCode {
  invalidCredentials,
  emailAlreadyInUse,
  weakPassword,
  invalidEmail,
  userDisabled,
  tooManyRequests,
  notSignedIn,
  profileMissing,

  /// L’utilisateur a fermé le sélecteur ou la popup Google : ce n’est pas
  /// une erreur à afficher.
  cancelled,
  accountExistsWithDifferentCredential,
  requiresRecentLogin,
  unknown,
}

final class AuthFailure extends Failure {
  const AuthFailure({
    required this.code,
    required super.message,
    super.cause,
    super.stackTrace,
  });

  const AuthFailure.notSignedIn()
    : this(
        code: AuthFailureCode.notSignedIn,
        message: 'Vous devez être connecté.',
      );

  final AuthFailureCode code;
}

final class NetworkFailure extends Failure {
  const NetworkFailure({
    super.message = 'Connexion impossible. Vérifiez votre réseau.',
    super.cause,
    super.stackTrace,
  });
}

final class PermissionFailure extends Failure {
  const PermissionFailure({
    super.message = "Vous n'avez pas les droits pour cette action.",
    super.cause,
    super.stackTrace,
  });
}

final class NotFoundFailure extends Failure {
  const NotFoundFailure({
    required this.resource,
    required super.message,
    super.cause,
    super.stackTrace,
  });

  final String resource;
}

final class ValidationFailure extends Failure {
  const ValidationFailure({
    required super.message,
    this.fieldErrors = const {},
    super.cause,
    super.stackTrace,
  });

  /// Nom du champ -> message d’erreur.
  final Map<String, String> fieldErrors;
}

/// Violations des règles du domaine (voir `ReservationPolicy`, `EventPolicy`).
enum BusinessRule {
  eventFull,
  alreadyReserved,
  eventAlreadyStarted,
  reservationNotActive,
  notReservationOwner,
  notEventOwner,
  capacityBelowReservations,
  eventHasReservations,
  emailNotVerified,

  /// Le serveur a refusé une action dont les préconditions ne sont pas
  /// réunies (`failed-precondition` renvoyé par une callable function) ; le
  /// message dit pourquoi.
  actionRefused,
  notAttendee,
  eventNotStarted,
  waitlistNotAvailable,
  cannotFollowSelf,

  /// Types de billets et paiements (F-12, F-11).
  tierRequired,
  tierSoldOut,
  paymentRequired,
  paymentPending,
  refundRequired,
  tiersLocked,
  cannotReportSelf,
  alreadyReported,
}

final class BusinessRuleFailure extends Failure {
  const BusinessRuleFailure({
    required this.rule,
    required super.message,
    super.cause,
    super.stackTrace,
  });

  final BusinessRule rule;
}

final class StorageFailure extends Failure {
  const StorageFailure({
    super.message = "L'envoi de l'image a échoué.",
    super.cause,
    super.stackTrace,
  });
}

final class UnexpectedFailure extends Failure {
  const UnexpectedFailure({
    super.message = 'Une erreur inattendue est survenue.',
    super.cause,
    super.stackTrace,
  });
}

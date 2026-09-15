abstract class AuthFailure implements Exception {
  final String message;

  const AuthFailure(this.message);

  @override
  String toString() => message;
}

class InvalidCredentialsFailure extends AuthFailure {
  const InvalidCredentialsFailure() : super('Email or password is incorrect.');
}

class EmailAlreadyInUseFailure extends AuthFailure {
  const EmailAlreadyInUseFailure()
    : super('An account already exists for this email.');
}

class InvalidEmailFailure extends AuthFailure {
  const InvalidEmailFailure() : super('Please enter a valid email address.');
}

class WeakPasswordFailure extends AuthFailure {
  const WeakPasswordFailure() : super('Please choose a stronger password.');
}

class UserNotFoundFailure extends AuthFailure {
  const UserNotFoundFailure() : super('No account was found for this email.');
}

class TooManyRequestsFailure extends AuthFailure {
  const TooManyRequestsFailure()
    : super('Too many attempts. Please try again later.');
}

class UnknownAuthFailure extends AuthFailure {
  UnknownAuthFailure([String? detail])
    : super(
        detail == null || detail.isEmpty
            ? 'An authentication error occurred. Please try again.'
            : detail,
      );
}

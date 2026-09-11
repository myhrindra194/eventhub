import 'dart:async';

import 'package:eventhub/core/errors/error_mapper.dart';
import 'package:eventhub/core/errors/failure.dart';

typedef AsyncResult<T> = Future<Result<T>>;

/// Railway-oriented result type. Pattern-match with `switch` or use [fold].
///
/// ```dart
/// switch (await repo.signIn(...)) {
///   case Ok(:final value): ...
///   case Err(:final failure): ...
/// }
/// ```
sealed class Result<T> {
  const Result();

  const factory Result.ok(T value) = Ok<T>;
  const factory Result.err(Failure failure) = Err<T>;

  bool get isOk => this is Ok<T>;
  bool get isErr => this is Err<T>;

  T? get valueOrNull => switch (this) {
    Ok(:final value) => value,
    Err() => null,
  };

  Failure? get failureOrNull => switch (this) {
    Ok() => null,
    Err(:final failure) => failure,
  };

  R fold<R>(R Function(T value) onOk, R Function(Failure failure) onErr) =>
      switch (this) {
        Ok(:final value) => onOk(value),
        Err(:final failure) => onErr(failure),
      };

  Result<U> map<U>(U Function(T value) transform) => switch (this) {
    Ok(:final value) => Ok(transform(value)),
    Err(:final failure) => Err(failure),
  };

  Result<U> flatMap<U>(Result<U> Function(T value) transform) => switch (this) {
    Ok(:final value) => transform(value),
    Err(:final failure) => Err(failure),
  };

  T getOrElse(T Function(Failure failure) orElse) => switch (this) {
    Ok(:final value) => value,
    Err(:final failure) => orElse(failure),
  };
}

final class Ok<T> extends Result<T> {
  const Ok(this.value);

  final T value;

  @override
  bool operator ==(Object other) => other is Ok<T> && other.value == value;

  @override
  int get hashCode => Object.hash(runtimeType, value);

  @override
  String toString() => 'Ok($value)';
}

final class Err<T> extends Result<T> {
  const Err(this.failure);

  final Failure failure;

  @override
  bool operator ==(Object other) => other is Err<T> && other.failure == failure;

  @override
  int get hashCode => Object.hash(runtimeType, failure);

  @override
  String toString() => 'Err($failure)';
}

/// Runs [body] and converts any thrown error into `Err` via [ErrorMapper].
/// This is the only try/catch repositories should need.
AsyncResult<T> guard<T>(FutureOr<T> Function() body) async {
  try {
    return Ok(await body());
  } catch (error, stackTrace) {
    return Err(ErrorMapper.fromAny(error, stackTrace));
  }
}

extension AsyncResultX<T> on AsyncResult<T> {
  Future<Result<U>> mapAsync<U>(U Function(T value) transform) async =>
      (await this).map(transform);

  Future<Result<U>> flatMapAsync<U>(
    AsyncResult<U> Function(T value) transform,
  ) async {
    return switch (await this) {
      Ok(:final value) => transform(value),
      Err(:final failure) => Err<U>(failure),
    };
  }
}

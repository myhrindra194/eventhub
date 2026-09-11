import 'package:eventhub/core/errors/failure.dart';
import 'package:eventhub/core/errors/failure_exception.dart';
import 'package:eventhub/core/result/result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const failure = UnexpectedFailure(message: 'boom');

  group('Result', () {
    test('map / flatMap only transform the Ok side', () {
      expect(const Ok<int>(2).map((v) => v * 2), const Ok<int>(4));
      expect(
        const Err<int>(failure).map((v) => v * 2),
        const Err<int>(failure),
      );
      expect(
        const Ok<int>(2).flatMap((v) => const Err<String>(failure)),
        const Err<String>(failure),
      );
    });

    test('fold and getOrElse', () {
      expect(const Ok<int>(1).fold((v) => 'ok$v', (f) => 'err'), 'ok1');
      expect(
        const Err<int>(failure).fold((v) => 'ok', (f) => f.message),
        'boom',
      );
      expect(const Err<int>(failure).getOrElse((_) => -1), -1);
    });
  });

  group('guard', () {
    test('wraps a value', () async {
      expect(await guard(() async => 42), const Ok<int>(42));
    });

    test('unwraps FailureException into the carried failure', () async {
      final result = await guard<int>(
        () => throw const FailureException(failure),
      );
      expect(result, const Err<int>(failure));
    });

    test('maps unknown errors to UnexpectedFailure', () async {
      final result = await guard<int>(() => throw StateError('x'));
      expect(result.failureOrNull, isA<UnexpectedFailure>());
    });
  });
}

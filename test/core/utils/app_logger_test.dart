import 'package:eventhub/core/utils/app_logger.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(() => AppLogger.reporter = null);

  test('forwards errors to the installed reporter with their severity', () {
    final reported = <(Object, bool, String?)>[];
    AppLogger.reporter = (error, stack, {required fatal, reason}) =>
        reported.add((error, fatal, reason));

    AppLogger.error('Handled', error: StateError('a'));
    AppLogger.error('Crash', error: StateError('b'), fatal: true);
    AppLogger.error('No error object');

    expect(reported, hasLength(2));
    expect(reported[0].$2, isFalse);
    expect(reported[0].$3, 'Handled');
    expect(reported[1].$2, isTrue);
  });

  test('logging without a reporter is safe', () {
    expect(() => AppLogger.error('x', error: Exception('y')), returnsNormally);
  });
}

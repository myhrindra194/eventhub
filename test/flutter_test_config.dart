import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

/// Largest share of pixels a golden may differ by and still pass.
///
/// The reference images are generated on the developers' machines (Windows)
/// while CI renders on Linux: text anti-aliasing and sub-pixel glyph
/// placement differ between the two, which moved 0.04–0.75 % of the pixels
/// with no visual change. 1 % absorbs that noise; a real regression — a
/// missing block, an overflow, a different layout — changes far more.
const double goldenTolerance = 0.01;

/// Applied by `flutter test` to every test file under `test/`.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  final comparator = goldenFileComparator;
  if (comparator is LocalFileComparator) {
    goldenFileComparator = TolerantGoldenComparator(
      comparator.basedir.resolve('flutter_test_config.dart'),
      tolerance: goldenTolerance,
    );
  }
  await testMain();
}

/// A [LocalFileComparator] that accepts differences up to [tolerance]
/// (a fraction of the image) and otherwise fails with the usual diff images.
class TolerantGoldenComparator extends LocalFileComparator {
  TolerantGoldenComparator(super.testFile, {required this.tolerance});

  final double tolerance;

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    final result = await GoldenFileComparator.compareLists(
      imageBytes,
      await getGoldenBytes(golden),
    );
    if (result.passed || result.diffPercent <= tolerance) {
      result.dispose();
      return true;
    }
    final error = await generateFailureOutput(result, golden, basedir);
    result.dispose();
    throw FlutterError(error);
  }
}

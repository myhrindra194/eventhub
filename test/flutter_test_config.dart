import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

/// La part maximale de pixels dont un golden peut différer tout en passant.
///
/// Les images de référence sont produites sur les machines des développeurs
/// (Windows) alors que la CI rend sous Linux : l'anticrénelage du texte et le
/// placement sous-pixel des glyphes diffèrent entre les deux, ce qui déplaçait
/// 0,04 à 0,75 % des pixels sans le moindre changement visible. 1 % absorbe ce
/// bruit ; une vraie régression — un bloc manquant, un débordement, une autre
/// mise en page — en change bien davantage.
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

/// Un [LocalFileComparator] qui accepte les écarts jusqu'à [tolerance] — une
/// fraction de l'image — et échoue sinon avec les images de différence
/// habituelles.
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

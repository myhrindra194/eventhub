import 'package:flutter/foundation.dart';

bool get isFirebaseAuthSupported {
  if (kIsWeb) return true;

  return switch (defaultTargetPlatform) {
    TargetPlatform.android ||
    TargetPlatform.iOS ||
    TargetPlatform.macOS => true,
    TargetPlatform.linux ||
    TargetPlatform.windows ||
    TargetPlatform.fuchsia => false,
  };
}

import 'package:flutter/animation.dart';

/// Motion tokens.
///
/// One vocabulary of durations and curves for the whole product, so that a
/// chip, a page transition and a bottom sheet feel like they belong to the
/// same machine. Values follow the Material 3 "expressive" easing set.
///
/// Rule of thumb:
///  * [instant] / [xshort] — state feedback (press, hover, ripple)
///  * [short]              — small element enters/leaves (chip, badge)
///  * [medium]             — page transitions, expanding cards
///  * [long] / [xlong]     — full-screen or celebratory motion
abstract final class AppMotion {
  static const instant = Duration(milliseconds: 80);
  static const xshort = Duration(milliseconds: 120);
  static const short = Duration(milliseconds: 180);
  static const medium = Duration(milliseconds: 260);
  static const slow = Duration(milliseconds: 340);
  static const long = Duration(milliseconds: 480);
  static const xlong = Duration(milliseconds: 720);

  /// Default "arrives with authority, settles softly" curve.
  static const emphasized = Cubic(0.2, 0, 0, 1);

  /// Entering the screen — no initial speed, decelerates into place.
  static const decelerate = Cubic(0.05, 0.7, 0.1, 1);

  /// Leaving the screen — picks up speed and exits.
  static const accelerate = Cubic(0.3, 0, 0.8, 0.15);

  /// Symmetric, for values that go back and forth (toggles, sliders).
  static const standard = Cubic(0.4, 0, 0.2, 1);

  /// A touch of overshoot for celebratory or playful elements only.
  static const spring = Cubic(0.34, 1.56, 0.64, 1);
}

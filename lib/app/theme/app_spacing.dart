import 'package:flutter/widgets.dart';

/// Spacing scale — a strict 4 pt grid.
///
/// Never hard-code a padding: pick the closest step. A layout built from a
/// finite scale reads as deliberate; one built from arbitrary numbers reads
/// as accidental, and that difference is most of what "mature design" means.
abstract final class AppSpacing {
  static const none = 0.0;
  static const xxs = 2.0;
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 20.0;
  static const xxl = 24.0;
  static const xxxl = 32.0;
  static const huge = 40.0;
  static const giant = 56.0;

  /// Horizontal gutter of every screen. Single source of truth: change it
  /// here and the whole app re-aligns.
  static const gutter = 20.0;

  static const screen = EdgeInsets.symmetric(horizontal: gutter);
}

/// Corner radii.
///
/// The scale is *nested-aware*: a child inside a container of radius `r`
/// uses the step below, which keeps concentric corners visually parallel.
abstract final class AppRadius {
  /// Controls the user *acts on* get a deliberately tight radius.
  ///
  /// 6 px is not a rounded rectangle pretending to be a pill: it reads as a
  /// drawn edge. Large radii on buttons are the single strongest tell of a
  /// default template, and the product's identity lives in its photography
  /// and its type, not in soft corners.
  static const button = 6.0;

  /// Fields share the button radius. One value for every rectangle a user
  /// types into or taps — a single sharp edge, repeated, reads as a decision;
  /// three neighbouring radii read as an accident.
  static const input = button;

  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 20.0;
  static const xl = 24.0;
  static const xxl = 28.0;
  static const xxxl = 34.0;
  static const pill = 999.0;

  static const brButton = BorderRadius.all(Radius.circular(button));
  static const brInput = BorderRadius.all(Radius.circular(input));
  static const brXs = BorderRadius.all(Radius.circular(xs));
  static const brSm = BorderRadius.all(Radius.circular(sm));
  static const brMd = BorderRadius.all(Radius.circular(md));
  static const brLg = BorderRadius.all(Radius.circular(lg));
  static const brXl = BorderRadius.all(Radius.circular(xl));
  static const brXxl = BorderRadius.all(Radius.circular(xxl));
  static const brPill = BorderRadius.all(Radius.circular(pill));

  /// Top-only rounding used by bottom sheets and content sheets that
  /// overlap a hero image.
  static const brSheet = BorderRadius.vertical(top: Radius.circular(xxxl));
}

/// Touch-target and control sizing.
abstract final class AppSizes {
  /// WCAG / Material minimum touch target.
  static const minTouch = 48.0;

  static const buttonSm = 40.0;
  static const buttonMd = 48.0;
  static const buttonLg = 56.0;

  static const inputHeight = 56.0;
  static const navBarHeight = 68.0;

  /// Space a scrollable must reserve so its last item clears the floating
  /// navigation bar.
  static const navBarInset = 108.0;

  /// Max content width — beyond this, a single column looks stretched on
  /// tablets and foldables, so content is centred instead.
  static const maxContentWidth = 560.0;
}

/// Layout breakpoints (Material 3 window size classes, trimmed to what the
/// product actually adapts to).
abstract final class AppBreakpoints {
  static const compact = 600.0;
  static const medium = 840.0;

  static bool isCompact(double width) => width < compact;
  static bool isExpanded(double width) => width >= medium;
}

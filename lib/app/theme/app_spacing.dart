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
/// The scale is **deliberately flat at 6 px**. Every rounded rectangle —
/// button, field, card, chip, badge, sheet, dialog, snack bar, image, track —
/// takes the same drawn edge. The named steps (`xs` … `xxxl`) are kept so
/// call sites still say *which* role a corner plays, but they all resolve to
/// the same value: one sharp edge, repeated, reads as a decision; a ladder of
/// neighbouring radii reads as a default template.
///
/// Circles are a different shape, not a bigger radius: avatars, status dots,
/// pager dots and round icon-only buttons use `BoxShape.circle` /
/// `CircleBorder`, never a radius.
abstract final class AppRadius {
  /// 6 px is not a rounded rectangle pretending to be a pill: it reads as a
  /// drawn edge. Large radii are the single strongest tell of a default
  /// template, and the product's identity lives in its photography and its
  /// type, not in soft corners.
  static const button = 6.0;

  /// Fields share the button radius.
  static const input = button;

  static const xs = button;
  static const sm = button;
  static const md = button;
  static const lg = button;
  static const xl = button;
  static const xxl = button;
  static const xxxl = button;

  /// Fully rounded ends. Reserved for pager dots and hairline indicators
  /// whose height *is* their diameter — never for a shape that holds text.
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

  /// Top-only rounding of the content sheet that overlaps a hero image.
  /// Same 6 px as everything else.
  static const brSheet = BorderRadius.vertical(top: Radius.circular(xxxl));

  /// Modal bottom sheets use the control radius, not [brSheet]: a sheet is
  /// a panel the user acts in, and it takes the same drawn 6 px edge as the
  /// buttons and fields it holds.
  static const brModalSheet = BorderRadius.vertical(
    top: Radius.circular(button),
  );
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

import 'package:eventhub/app/theme/theme.dart';
import 'package:flutter/widgets.dart';

/// Width bands the product actually adapts to.
///
/// Three, not seven. Every extra band is a layout nobody tests: the design
/// only has to survive a 320 dp budget phone, the 360–430 dp mainstream, and
/// anything wider where a single column would look stretched.
enum ScreenSize {
  /// < 360 dp — small or split-screen phones.
  small,

  /// 360–599 dp — the phone the design is drawn for.
  medium,

  /// >= 600 dp — tablets, foldables, desktop windows.
  expanded;

  static ScreenSize of(double width) {
    if (width < 360) return ScreenSize.small;
    if (width < AppBreakpoints.compact) return ScreenSize.medium;
    return ScreenSize.expanded;
  }
}

extension ResponsiveX on BuildContext {
  ScreenSize get screenSize => ScreenSize.of(MediaQuery.sizeOf(this).width);

  bool get isSmallScreen => screenSize == ScreenSize.small;
  bool get isExpandedScreen => screenSize == ScreenSize.expanded;

  /// Picks a value per band. [medium] is the reference; the other two fall
  /// back to it, so a caller only overrides what genuinely needs to change.
  ///
  /// ```dart
  /// final hero = context.responsive(medium: 148.0, small: 116.0);
  /// ```
  T responsive<T>({required T medium, T? small, T? expanded}) =>
      switch (screenSize) {
        ScreenSize.small => small ?? medium,
        ScreenSize.medium => medium,
        ScreenSize.expanded => expanded ?? medium,
      };

  /// Horizontal gutter, tightened on narrow screens where 20 dp on each side
  /// eats a meaningful share of a 320 dp line.
  double get gutter => responsive(medium: AppSpacing.gutter, small: 16.0);
}

/// Centres and caps a single column of content.
///
/// Beyond ~480 dp a form column stops being readable and starts looking
/// abandoned in the middle of a page. Capping the width is what makes the
/// same screen usable on a phone, a foldable and a desktop window without a
/// second layout.
class ResponsiveColumn extends StatelessWidget {
  const ResponsiveColumn({required this.child, super.key, this.maxWidth = 480});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: child,
    ),
  );
}

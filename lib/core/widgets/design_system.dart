/// EventHub component library.
///
/// One import gives a screen the whole vocabulary:
/// `import 'package:eventhub/core/widgets/design_system.dart';`
///
/// The rule the codebase follows: a screen composes components, it does not
/// draw. If a screen reaches for a raw `Container` with a hand-picked colour,
/// the component is missing and belongs here.
library;

export 'app_avatar.dart';
export 'app_background.dart';
export 'app_badge.dart';
export 'app_button.dart';
export 'app_field.dart';
export 'app_meter.dart';
export 'app_nav_bar.dart';
export 'app_section.dart';
export 'app_sheet.dart';
export 'app_skeleton.dart';
export 'app_surface.dart';
export 'async_value_widget.dart';
export 'event_image.dart';
export 'field_group.dart';
export 'responsive.dart';
export 'state_views.dart';

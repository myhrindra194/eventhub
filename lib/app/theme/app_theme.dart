import 'package:eventhub/app/theme/app_motion.dart';
import 'package:eventhub/app/theme/app_palette.dart';
import 'package:eventhub/app/theme/app_spacing.dart';
import 'package:eventhub/app/theme/app_tokens.dart';
import 'package:eventhub/app/theme/app_typography.dart';
import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Assemble le [ThemeData] Material 3 à partir des tokens de design.
///
/// Rien ici n’invente une couleur : chaque valeur est lue depuis [AppTokens],
/// si bien que le thème clair et le thème sombre sont littéralement le même
/// code exécuté sur deux jeux de tokens. Les thèmes de composants sont
/// configurés exhaustivement — un écran ne devrait presque jamais avoir à
/// styler localement un bouton, un champ ou un chip.
abstract final class AppTheme {
  static ThemeData light() => _build(AppTokens.light);

  static ThemeData dark() => _build(AppTokens.dark);

  static ThemeData _build(AppTokens t) {
    final scheme = _scheme(t);
    final text = AppTypography.textTheme(
      primary: t.textPrimary,
      secondary: t.textSecondary,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: t.brightness,
      colorScheme: scheme,
      textTheme: text,
      extensions: [t],
      scaffoldBackgroundColor: t.canvas,
      canvasColor: t.canvas,
      dividerColor: t.border,
      splashFactory: InkSparkle.splashFactory,
      visualDensity: VisualDensity.standard,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
        },
      ),

      // ----------------------------------------------------------- barres
      appBarTheme: AppBarTheme(
        backgroundColor: t.canvas,
        surfaceTintColor: Colors.transparent,
        foregroundColor: t.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleSpacing: AppSpacing.gutter,
        titleTextStyle: text.titleLarge,
        iconTheme: IconThemeData(color: t.textPrimary, size: 22),
        systemOverlayStyle: t.isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        indicatorColor: t.brandSoft,
        indicatorShape: const RoundedRectangleBorder(
          borderRadius: AppRadius.brButton,
        ),
        height: AppSizes.navBarHeight,
        elevation: 0,
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
      ),

      // -------------------------------------------------------- conteneurs
      cardTheme: CardThemeData(
        elevation: 0,
        clipBehavior: Clip.antiAlias,
        color: t.surface,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.brXl,
          side: BorderSide(color: t.border),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: t.surfaceOverlay,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.brXxl),
        titleTextStyle: text.headlineSmall,
        contentTextStyle: text.bodyMedium,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: t.surfaceOverlay,
        surfaceTintColor: Colors.transparent,
        modalBarrierColor: t.scrim,
        elevation: 0,
        // Pas de poignée : les sheets se ferment par leur propre bouton ✕,
        // par un appui sur le scrim ou par un glissement vers le bas.
        showDragHandle: false,
        clipBehavior: Clip.antiAlias,
        shape: const RoundedRectangleBorder(
          borderRadius: AppRadius.brModalSheet,
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: t.surfaceRaised,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.brMd,
          side: BorderSide(color: t.border),
        ),
        textStyle: text.bodyLarge,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: t.isDark ? AppPalette.neutral800 : AppPalette.neutral900,
          borderRadius: AppRadius.brSm,
        ),
        textStyle: text.bodySmall?.copyWith(color: AppPalette.neutral0),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
      ),

      // ------------------------------------------------------------ champs
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: t.surfaceSunken,
        hintStyle: text.bodyLarge?.copyWith(color: t.textTertiary),
        labelStyle: text.bodyMedium,
        floatingLabelStyle: text.labelLarge?.copyWith(color: t.brand),
        errorStyle: text.bodySmall?.copyWith(color: t.danger.fg, height: 1.3),
        helperStyle: text.bodySmall?.copyWith(color: t.textTertiary),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.lg,
        ),
        border: _border(t.border),
        enabledBorder: _border(t.border),
        focusedBorder: _border(t.brand, width: 1.6),
        errorBorder: _border(t.danger.border),
        focusedErrorBorder: _border(t.danger.fg, width: 1.6),
        disabledBorder: _border(t.borderSubtle),
        prefixIconColor: WidgetStateColor.resolveWith(
          (s) => s.contains(WidgetState.focused) ? t.brand : t.textTertiary,
        ),
        suffixIconColor: t.textTertiary,
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: t.brand,
        selectionColor: t.brandSoft,
        selectionHandleColor: t.brand,
      ),

      // ----------------------------------------------------------- boutons
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: t.brand,
          foregroundColor: t.textOnBrand,
          disabledBackgroundColor: t.surfaceSunken,
          disabledForegroundColor: t.textTertiary,
          minimumSize: const Size(0, AppSizes.buttonMd),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.brButton),
          textStyle: text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: t.textPrimary,
          backgroundColor: Colors.transparent,
          minimumSize: const Size(0, AppSizes.buttonMd),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
          side: BorderSide(color: t.borderStrong),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.brButton),
          textStyle: text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: t.brand,
          minimumSize: const Size(0, AppSizes.buttonSm),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.brButton),
          textStyle: text.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: t.textSecondary,
          highlightColor: t.brandSoft,
          minimumSize: const Size.square(AppSizes.minTouch),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.brButton),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: t.brand,
        foregroundColor: t.textOnBrand,
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.brLg),
      ),

      // ----------------------------------------------------------- divers
      chipTheme: ChipThemeData(
        backgroundColor: t.surfaceSunken,
        selectedColor: t.brand,
        disabledColor: t.surfaceSunken,
        labelStyle: text.labelLarge,
        secondaryLabelStyle: text.labelLarge?.copyWith(color: t.textOnBrand),
        side: BorderSide(color: t.border),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.brButton),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        showCheckmark: false,
        elevation: 0,
        pressElevation: 0,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: t.isDark ? t.surfaceRaised : AppPalette.neutral900,
        contentTextStyle: text.bodyMedium?.copyWith(
          color: t.isDark ? t.textPrimary : AppPalette.neutral0,
        ),
        actionTextColor: t.brandStrong,
        elevation: 0,
        insetPadding: const EdgeInsets.all(AppSpacing.lg),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.brMd),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: t.brand,
        linearTrackColor: t.surfaceSunken,
        circularTrackColor: Colors.transparent,
        linearMinHeight: 6,
        strokeWidth: 3,
      ),
      dividerTheme: DividerThemeData(color: t.border, thickness: 1, space: 1),
      listTileTheme: ListTileThemeData(
        iconColor: t.textSecondary,
        textColor: t.textPrimary,
        titleTextStyle: text.titleMedium,
        subtitleTextStyle: text.bodySmall,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.xs,
        ),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.brMd),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? t.textOnBrand
              : t.isDark
              ? t.textSecondary
              : AppPalette.neutral0,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? t.brand : t.surfaceSunken,
        ),
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (s) =>
              s.contains(WidgetState.selected) ? Colors.transparent : t.border,
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: t.brand,
        inactiveTrackColor: t.surfaceSunken,
        thumbColor: t.brand,
        overlayColor: t.brandSoft,
        trackHeight: 6,
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          side: WidgetStatePropertyAll(BorderSide(color: t.border)),
          backgroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected)
                ? t.brandSoft
                : Colors.transparent,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? t.brand : t.textSecondary,
          ),
          textStyle: WidgetStatePropertyAll(text.titleSmall),
          shape: const WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: AppRadius.brButton),
          ),
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: t.brand,
        unselectedLabelColor: t.textSecondary,
        labelStyle: text.titleSmall,
        unselectedLabelStyle: text.titleSmall,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: Colors.transparent,
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(color: t.brand, width: 2.5),
          borderRadius: AppRadius.brButton,
        ),
      ),
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStatePropertyAll(t.borderStrong),
        radius: const Radius.circular(AppRadius.xs),
        thickness: const WidgetStatePropertyAll(4),
      ),
    );
  }

  static ColorScheme _scheme(AppTokens t) => ColorScheme(
    brightness: t.brightness,
    primary: t.brand,
    onPrimary: t.textOnBrand,
    primaryContainer: t.brandSoft,
    onPrimaryContainer: t.brandStrong,
    secondary: t.accent,
    onSecondary: t.textOnBrand,
    secondaryContainer: t.accentSoft,
    onSecondaryContainer: t.accent,
    tertiary: t.success.solid,
    onTertiary: t.success.onSolid,
    tertiaryContainer: t.success.bg,
    onTertiaryContainer: t.success.fg,
    error: t.danger.solid,
    onError: t.danger.onSolid,
    errorContainer: t.danger.bg,
    onErrorContainer: t.danger.fg,
    surface: t.canvas,
    onSurface: t.textPrimary,
    onSurfaceVariant: t.textSecondary,
    surfaceContainerLowest: t.canvas,
    surfaceContainerLow: t.surfaceSunken,
    surfaceContainer: t.surface,
    surfaceContainerHigh: t.surfaceRaised,
    surfaceContainerHighest: t.surfaceOverlay,
    outline: t.border,
    outlineVariant: t.borderSubtle,
    scrim: t.scrim,
    shadow: Colors.black,
    inverseSurface: t.textPrimary,
    onInverseSurface: t.canvas,
    inversePrimary: t.brandStrong,
    surfaceTint: Colors.transparent,
  );

  static OutlineInputBorder _border(Color color, {double width = 1}) =>
      OutlineInputBorder(
        borderRadius: AppRadius.brInput,
        borderSide: BorderSide(color: color, width: width),
      );

  /// Barres système accordées au thème courant. Appliquées par `EventHubApp`
  /// via un `AnnotatedRegion`, pour qu’un écran n’ait jamais à s’en soucier.
  static SystemUiOverlayStyle overlayStyle(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: isDark
          ? Brightness.light
          : Brightness.dark,
      systemNavigationBarDividerColor: Colors.transparent,
    );
  }

  /// Durée utilisée par `MaterialApp.themeAnimationDuration` pour qu’une
  /// bascule clair↔sombre fonde via le `lerp` des tokens au lieu de sauter.
  static const themeSwitchDuration = AppMotion.slow;
}

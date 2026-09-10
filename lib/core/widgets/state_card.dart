import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class StateCard extends StatelessWidget {
  final String title;
  final String description;
  final Widget iconWidget;
  final String? buttonText;
  final VoidCallback? onButtonPressed;
  final Color? titleColor;
  final Color? buttonColor;
  final bool isFullWidthStyle;

  const StateCard({
    super.key,
    required this.title,
    required this.description,
    required this.iconWidget,
    this.buttonText,
    this.onButtonPressed,
    this.titleColor,
    this.buttonColor,
    this.isFullWidthStyle = false,
  });

  /// Factory for the no-events state with a full-width layout.
  factory StateCard.noEvents({VoidCallback? onClearFilters}) {
    return StateCard(
      isFullWidthStyle: true,
      title: 'No Events Found',
      description:
          "We couldn't find any events matching\nyour current search. Try different\nkeywords or filters.",
      iconWidget: Container(
        width: 110,
        height: 110,
        decoration: BoxDecoration(
          color: AppColors.darkSurfaceLight,
          borderRadius: BorderRadius.circular(28),
        ),
        child: const Icon(
          Icons.event_busy_rounded,
          color: AppColors.accentIndigo,
          size: 48,
        ),
      ),
      buttonText: 'Clear All Filters',
      buttonColor: AppColors.accentIndigo,
      onButtonPressed: onClearFilters,
    );
  }

  /// Carte : Syncing Calendar
  factory StateCard.syncing() {
    return const StateCard(
      title: 'Syncing Calendar',
      description: 'Just a moment while we fetch the\nlatest events...',
      iconWidget: SizedBox(
        width: 36,
        height: 36,
        child: CircularProgressIndicator(
          strokeWidth: 3,
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentIndigo),
        ),
      ),
    );
  }

  /// Carte : Connection Lost
  factory StateCard.connectionLost({VoidCallback? onRetry}) {
    return StateCard(
      title: 'Connection Lost',
      titleColor: AppColors.error,
      description:
          'Unable to connect to the server.\nPlease check your internet.',
      iconWidget: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(
          Icons.wifi_off_rounded,
          color: AppColors.error,
          size: 28,
        ),
      ),
      buttonText: 'Retry Connection',
      buttonColor: AppColors.error,
      onButtonPressed: onRetry,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isFullWidthStyle) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            iconWidget,
            const SizedBox(height: 28),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: titleColor ?? AppColors.darkTextPrimary,
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              description,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.darkTextSecondary,
                fontSize: 14,
                height: 1.45,
              ),
            ),
            if (buttonText != null) ...[
              const SizedBox(height: 36),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: onButtonPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: buttonColor ?? AppColors.accentIndigo,
                    foregroundColor: AppColors.darkTextPrimary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    buttonText!,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    }

    return Container(
      width: 270,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.darkSurfaceLight, width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          iconWidget,
          const SizedBox(height: 20),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: titleColor ?? AppColors.darkTextPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.darkTextSecondary,
              fontSize: 12,
              height: 1.4,
            ),
          ),
          if (buttonText != null) ...[
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: onButtonPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: buttonColor ?? AppColors.darkSurfaceLight,
                foregroundColor: AppColors.darkTextPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                elevation: 0,
              ),
              child: Text(
                buttonText!,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

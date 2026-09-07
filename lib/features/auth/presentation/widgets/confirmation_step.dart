import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';

/// Étape 3 de l'inscription : écran de confirmation "You're All Set!"
/// avec redirection automatique après quelques secondes.
class ConfirmationStep extends StatefulWidget {
  final bool isDark;

  const ConfirmationStep({super.key, required this.isDark});

  @override
  State<ConfirmationStep> createState() => _ConfirmationStepState();
}

class _ConfirmationStepState extends State<ConfirmationStep> {
  int _secondsLeft = 3;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft <= 1) {
        timer.cancel();
        _navigateHome();
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _navigateHome() {
    if (!mounted) return;
    // TODO: remplacer '/home' par la vraie route (ou écran) de la liste
    // des événements, et déclarer cette route dans ton MaterialApp
    // (routes: {...}), ou importer directement l'écran ici et utiliser
    // Navigator.pushAndRemoveUntil(MaterialPageRoute(...)).
    Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final size = MediaQuery.of(context).size;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: size.width * 0.08),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const _SuccessBadge(),
            const SizedBox(height: 28),
            Text(
              "You're All Set!",
              textAlign: TextAlign.center,
              style: AppTypography.display(isDark),
            ),
            const SizedBox(height: 12),
            Text(
              'Your account has been created successfully. Welcome to '
              'the premier event platform.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyLarge(isDark),
            ),
            const SizedBox(height: 36),
            AppButton(
              text: 'Explore Events',
              icon: Icons.arrow_forward_rounded,
              onPressed: _navigateHome,
            ),
            const SizedBox(height: 16),
            Text(
              'Redirecting to home in $_secondsLeft second'
              '${_secondsLeft > 1 ? 's' : ''}...',
              style: AppTypography.body(isDark).copyWith(color: textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _SuccessBadge extends StatelessWidget {
  const _SuccessBadge();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 140,
      height: 140,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.success.withValues(alpha: 0.08),
            ),
          ),
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.success.withValues(alpha: 0.15),
            ),
          ),
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.success,
              boxShadow: [
                BoxShadow(
                  color: AppColors.success.withValues(alpha: 0.5),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(Icons.check, color: Colors.white, size: 32),
          ),
        ],
      ),
    );
  }
}
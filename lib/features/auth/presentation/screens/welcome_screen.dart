import 'dart:async';

import 'package:eventhub/app/theme/theme.dart';
import 'package:eventhub/core/extensions/context_x.dart';
import 'package:eventhub/core/l10n/app_strings.dart';
import 'package:eventhub/core/widgets/design_system.dart';
import 'package:eventhub/features/auth/application/auth_providers.dart';
import 'package:eventhub/routes/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Post-registration celebration, shown once.
///
/// It auto-advances after three seconds *and* offers the button: the timer
/// keeps a passive user moving, the button respects an impatient one.
class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(seconds: 3), _goHome);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _goHome() {
    if (!mounted) return;
    final user = ref.read(currentUserProvider);
    context.go(user?.role.homePath ?? AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final isOrganizer = user?.isOrganizer ?? false;
    final cta = isOrganizer
        ? AppStrings.viewDashboard
        : AppStrings.exploreEvents;

    return AppScaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxxl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(flex: 3),
              const Center(child: SuccessHero()),
              const SizedBox(height: AppSpacing.huge),
              Text(
                AppStrings.allSet,
                style: context.textTheme.displaySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                AppStrings.allSetHint,
                style: context.textTheme.bodyLarge?.copyWith(
                  color: context.tokens.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const Spacer(flex: 2),
              AppButton.primary(
                label: cta,
                trailingIcon: Icons.arrow_forward_rounded,
                onPressed: _goHome,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                AppStrings.redirecting,
                style: context.textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
}
